-- Chapter Summariser Gemini client (v0.4.6)
-- Uses stable Gemini 3.5 Flash-Lite with the minimal GenerateContent payload.
-- One POST per planned request; no SSE, retries, hidden fallbacks, or extra token-count request.

local JSON = require("json")
local logger = require("logger")

local GeminiClient = {}
local STATUS_MARKER = "__CHAPTER_SUMMARISER_HTTP__"

local function trim(value)
    if type(value) ~= "string" then return "" end
    return (value:gsub("^%s*(.-)%s*$", "%1"))
end

local function shellQuote(value)
    value = tostring(value or "")
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function curlConfigQuote(value)
    value = tostring(value or "")
    value = value:gsub("\\", "\\\\")
    value = value:gsub('"', '\\"')
    value = value:gsub("\r", ""):gsub("\n", "")
    return '"' .. value .. '"'
end

local function makeTempPath()
    local ok, path = pcall(os.tmpname)
    if not ok or type(path) ~= "string" or path == "" then
        return nil, "Could not create a temporary filename"
    end
    return path
end

local function writeFile(path, content)
    local file, err = io.open(path, "wb")
    if not file then return nil, tostring(err or "Could not open temporary file") end
    local ok, write_err = file:write(content)
    local close_ok, close_err = file:close()
    if not ok then return nil, tostring(write_err or close_err or "Could not write temporary file") end
    if close_ok == nil then return nil, tostring(close_err or "Could not close temporary file") end
    return true
end

local function readFile(path)
    local file = io.open(path, "rb")
    if not file then return "" end
    local content = file:read("*a") or ""
    file:close()
    return content
end

local function removeFiles(paths)
    for _, path in ipairs(paths) do
        if path then pcall(os.remove, path) end
    end
end

local function findCurl()
    -- Local command lookup only: no network traffic and no generation quota.
    local ok, pipe = pcall(io.popen, "command -v curl 2>/dev/null", "r")
    if not ok or not pipe then return nil end
    local path = trim(pipe:read("*l") or "")
    pcall(function() pipe:close() end)
    if path == "" then return nil end
    return path
end

local function decodeJson(text)
    if type(text) ~= "string" or text == "" then return nil end
    -- Some command-line transports may leave a UTF-8 BOM at the start.
    if text:sub(1, 3) == "\239\187\191" then text = text:sub(4) end
    local ok, value = pcall(JSON.decode, text)
    if ok and type(value) == "table" then return value end
    return nil
end

local function apiErrorMessage(body, code)
    local data = decodeJson(body)
    local message = data and data.error and data.error.message
    if type(message) ~= "string" or message == "" then
        message = trim(body)
    end
    if message == "" then message = "Google returned no error details." end

    if code == 400 then
        return "Google rejected the generation request (HTTP 400). " .. message
    elseif code == 401 or code == 403 then
        return "Google did not authorise this request (HTTP " .. tostring(code) .. "). Check the API key and project access. " .. message
    elseif code == 404 then
        return "Google could not find the requested Gemini model or endpoint (HTTP 404). " .. message
    elseif code == 429 then
        return "Google's generation quota or rate limit was reached (HTTP 429). No retry was made. " .. message
    elseif code == 500 or code == 502 or code == 503 or code == 504 then
        return "Google's service returned HTTP " .. tostring(code) .. ". No retry was made. " .. message
    end
    return "Google Gemini returned HTTP " .. tostring(code or "unknown") .. ". No retry was made. " .. message
end

local function safePreview(body, limit)
    body = tostring(body or "")
    body = body:gsub("[%c]", " "):gsub("%s+", " ")
    if #body > (limit or 180) then body = body:sub(1, limit or 180) .. "…" end
    return body
end

-- Standard Gemini GenerateContent responses contain candidates[].content.parts[].text.
-- Ignore thought parts, and preserve all visible text parts in candidate order.
local function extractGenerateContentText(response)
    if type(response) ~= "table" then return "", nil end
    local candidates = response.candidates
    local pieces = {}
    local finish_reason, finish_message
    if type(candidates) == "table" then
        for _, candidate in ipairs(candidates) do
            if type(candidate) == "table" then
                finish_reason = candidate.finishReason or finish_reason
                finish_message = candidate.finishMessage or finish_message
                local content = candidate.content
                if type(content) == "table" and type(content.parts) == "table" then
                    for _, part in ipairs(content.parts) do
                        if type(part) == "table" and part.thought ~= true
                                and type(part.text) == "string" and part.text ~= "" then
                            pieces[#pieces + 1] = part.text
                        end
                    end
                end
            end
            if #pieces > 0 then break end -- one candidate is requested by default
        end
    end
    return trim(table.concat(pieces)), {
        finish_reason = finish_reason,
        finish_message = finish_message,
        prompt_feedback = response.promptFeedback,
        usage = response.usageMetadata,
        model_version = response.modelVersion,
        response_id = response.responseId,
    }
end

local function parseStatus(output)
    local marker_start = output:find(STATUS_MARKER, 1, true)
    if not marker_start then return output, nil, nil end
    local body = output:sub(1, marker_start - 1)
    body = body:gsub("[\r\n]+$", "")
    local marker_tail = output:sub(marker_start + #STATUS_MARKER)
    local code = tonumber(marker_tail:match("^(%d%d%d)"))
    local details = marker_tail:match("^%d%d%d;([^\r\n]*)")
    if code == 0 then code = nil end
    return body, code, details
end

local function requestWithCurl(curl_path, url, api_key, request_body)
    local request_path, err1 = makeTempPath()
    if not request_path then return nil, nil, err1 end
    local config_path, err2 = makeTempPath()
    if not config_path then removeFiles({ request_path }); return nil, nil, err2 end
    local stderr_path, err3 = makeTempPath()
    if not stderr_path then removeFiles({ request_path, config_path }); return nil, nil, err3 end
    local headers_path, err4 = makeTempPath()
    if not headers_path then removeFiles({ request_path, config_path, stderr_path }); return nil, nil, err4 end
    local paths = { request_path, config_path, stderr_path, headers_path }

    local ok_body, body_err = writeFile(request_path, request_body)
    if not ok_body then removeFiles(paths); return nil, nil, "Could not prepare the chapter request: " .. tostring(body_err) end

    -- The API key is kept out of the shell command line in a short-lived config.
    -- Certificate verification remains enabled; do not add --insecure/-k.
    local config = table.concat({
        "silent",
        "show-error",
        'request = "POST"',
        'header = ' .. curlConfigQuote("Content-Type: application/json"),
        'header = ' .. curlConfigQuote("Accept: application/json"),
        'header = ' .. curlConfigQuote("x-goog-api-key: " .. api_key),
        'header = ' .. curlConfigQuote("Expect:"),
        'data-binary = ' .. curlConfigQuote("@" .. request_path),
        'url = ' .. curlConfigQuote(url),
        "",
    }, "\n")
    local ok_config, config_err = writeFile(config_path, config)
    if not ok_config then removeFiles(paths); return nil, nil, "Could not prepare the Gemini request: " .. tostring(config_err) end

    -- Exactly one POST. No retry, redirect, transport switch, or fallback.
    -- The 180-second cap is passed directly to curl and not read from .curlrc.
    local writeout = "\\n" .. STATUS_MARKER .. "%{http_code};dns=%{time_namelookup};tcp=%{time_connect};tls=%{time_appconnect};upload=%{size_upload};ttfb=%{time_starttransfer};total=%{time_total};ip=%{remote_ip}\\n"
    local command = shellQuote(curl_path)
        .. " --disable --config " .. shellQuote(config_path)
        .. " --ipv4 --http1.1 --connect-timeout 20 --max-time 180"
        .. " --dump-header " .. shellQuote(headers_path)
        .. " --write-out " .. shellQuote(writeout)
        .. " 2>" .. shellQuote(stderr_path)

    local popen_ok, pipe = pcall(io.popen, command, "r")
    if not popen_ok or not pipe then
        removeFiles(paths)
        return nil, nil, "Could not start curl on this Kindle. " .. tostring(pipe or "")
    end
    local output = pipe:read("*a") or ""
    local close_ok, close_reason, close_code = pipe:close()
    local stderr_text = trim(readFile(stderr_path))
    local headers_text = readFile(headers_path)
    removeFiles(paths)

    local response_body, status_code, timings = parseStatus(output)
    if not status_code then
        local detail = stderr_text ~= "" and stderr_text or tostring(close_code or close_reason or "No HTTP status received")
        if timings and timings ~= "" then detail = detail .. " | timings: " .. timings end
        return nil, nil, "The Kindle did not receive an HTTP response. " .. detail, response_body
    end
    return response_body, status_code, nil, nil, {
        stderr = stderr_text,
        headers = headers_text,
        timings = timings,
        exit_reason = close_reason or close_code,
        response_bytes = #response_body,
    }
end

local function requestWithLuaSec(url, api_key, request_body, timeout_seconds)
    local https = require("ssl.https")
    local socketutil = require("socketutil")
    local ltn12 = require("ltn12")
    local response_chunks = {}
    local request = {
        url = url,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#request_body),
            ["Accept"] = "application/json",
            ["Expect"] = "",
            ["x-goog-api-key"] = api_key,
            ["Connection"] = "close",
        },
        source = ltn12.source.string(request_body),
        sink = ltn12.sink.table(response_chunks),
    }
    socketutil:set_timeout(20, timeout_seconds or 180)
    local request_ok, result, code, headers, status = pcall(function() return https.request(request) end)
    pcall(function() socketutil:reset_timeout() end)
    local body = table.concat(response_chunks)
    if not request_ok then return nil, nil, tostring(result), body end
    if not result then return body, tonumber(code), tostring(status or code or "HTTPS request failed") end
    return body, tonumber(code), nil, nil, { headers = headers or {}, response_bytes = #body }
end

local function requestWithLuaSecGet(url, api_key)
    local https = require("ssl.https")
    local socketutil = require("socketutil")
    local ltn12 = require("ltn12")
    local chunks = {}
    local request = {
        url = url,
        method = "GET",
        headers = { ["Accept"] = "application/json", ["x-goog-api-key"] = api_key, ["Connection"] = "close" },
        sink = ltn12.sink.table(chunks),
    }
    socketutil:set_timeout(15, 40)
    local ok, result, code, headers, status = pcall(function() return https.request(request) end)
    pcall(function() socketutil:reset_timeout() end)
    if not ok then return nil, nil, tostring(result) end
    if not result then return nil, tonumber(code), tostring(status or code or "HTTPS request failed") end
    return table.concat(chunks), tonumber(code), nil
end

local function runCurlGet(curl_path, url, api_key)
    local config_path, err1 = makeTempPath()
    if not config_path then return nil, nil, err1 end
    local stderr_path, err2 = makeTempPath()
    if not stderr_path then removeFiles({ config_path }); return nil, nil, err2 end
    local paths = { config_path, stderr_path }
    local config = table.concat({
        "silent", "show-error",
        'header = ' .. curlConfigQuote("Accept: application/json"),
        'header = ' .. curlConfigQuote("x-goog-api-key: " .. api_key),
        'url = ' .. curlConfigQuote(url), "",
    }, "\n")
    local ok_config, config_err = writeFile(config_path, config)
    if not ok_config then removeFiles(paths); return nil, nil, tostring(config_err) end

    local writeout = "\\n" .. STATUS_MARKER .. "%{http_code}\\n"
    local command = shellQuote(curl_path)
        .. " --disable --config " .. shellQuote(config_path)
        .. " --ipv4 --http1.1 --connect-timeout 15 --max-time 40"
        .. " --write-out " .. shellQuote(writeout)
        .. " 2>" .. shellQuote(stderr_path)
    local popen_ok, pipe = pcall(io.popen, command, "r")
    if not popen_ok or not pipe then removeFiles(paths); return nil, nil, "Could not start curl for the connection check." end
    local output = pipe:read("*a") or ""
    local _, close_reason, close_code = pipe:close()
    local stderr_text = trim(readFile(stderr_path))
    removeFiles(paths)

    local body, code = parseStatus(output)
    if not code then
        return nil, nil, "The connection check received no HTTP status. " .. (stderr_text ~= "" and stderr_text or tostring(close_code or close_reason or "unknown error"))
    end
    return body, code, nil
end

local function apiErrorFromBody(body, code)
    if code ~= 200 then return apiErrorMessage(body, code) end
    local data = decodeJson(body or "")
    if data and data.error then
        return tostring(data.error.message or data.error.status or "Google returned an API error.")
    end
    return nil
end

function GeminiClient.checkConnection(api_key, model, is_kindle)
    if type(api_key) ~= "string" or api_key == "" then
        return false, "The Gemini API key is missing. Add it in the plugin menu."
    end
    local url = "https://generativelanguage.googleapis.com/v1beta/models/" .. model
    local curl = findCurl()
    local body, code, err
    if curl then
        body, code, err = runCurlGet(curl, url, api_key)
    else
        body, code, err = requestWithLuaSecGet(url, api_key)
    end
    if err then return false, "Connection check failed: " .. tostring(err) end
    if code ~= 200 then return false, apiErrorMessage(body or "", code) end
    local data = decodeJson(body or "")
    if not data then return false, "Google responded, but the model information could not be read." end
    local model_name = data.name or ("models/" .. model)
    local input_limit = tonumber(data.inputTokenLimit)
    local detail = "Gemini connection successful. Model available: " .. tostring(model_name)
    if input_limit then detail = detail .. " (input limit " .. tostring(input_limit) .. " tokens)." else detail = detail .. "." end
    detail = detail .. " No chapter text was sent and no text was generated."
    return true, detail
end

function GeminiClient.generate(api_key, model, prompt, is_kindle)
    if type(api_key) ~= "string" or api_key == "" then return nil, "The Gemini API key is missing." end
    if type(prompt) ~= "string" or prompt == "" then return nil, "There is no chapter text to summarise. Nothing was sent." end

    -- Google GenerateContent REST API: a single conventional JSON response.
    -- The chapter text is sent once. No streaming parser, retry or second POST.
    -- Keep request shape minimal: v0.4.2 successfully generated a recap on-device
    -- with contents only. Do not add generationConfig without a separate test.
    local payload = {
        contents = {
            { role = "user", parts = { { text = prompt } } },
        },
        -- Deliberately omit generationConfig. The minimal contents-only request
        -- is the exact request shape that produced a complete recap on this Kindle
        -- in v0.4.2. The prompt controls recap length; let the model use its defaults.
    }
    local encode_ok, request_body = pcall(JSON.encode, payload)
    if not encode_ok or type(request_body) ~= "string" or request_body == "" then
        return nil, "Could not prepare the Gemini request. Nothing was sent."
    end

    local url = "https://generativelanguage.googleapis.com/v1beta/models/" .. model .. ":generateContent"
    local curl = findCurl()
    local body, code, err, partial_body, diagnostics
    if curl then
        logger.info("ChapterSummariser: sending one GenerateContent JSON request via curl")
        body, code, err, partial_body, diagnostics = requestWithCurl(curl, url, api_key, request_body)
    else
        logger.warn("ChapterSummariser: curl unavailable; using LuaSec for one GenerateContent request")
        body, code, err, partial_body, diagnostics = requestWithLuaSec(url, api_key, request_body, 180)
    end

    if err then
        local partial = partial_body or body
        local parsed = decodeJson(partial or "")
        if parsed then
            local partial_text = extractGenerateContentText(parsed)
            if partial_text ~= "" then
                return partial_text, "The connection ended after Gemini returned a response body. The recap may be incomplete; no retry was made.", { partial = true }
            end
        end
        return nil, "The Gemini request did not complete. No retry was made because Google may already have received it. " .. tostring(err)
    end
    if code ~= 200 then return nil, apiErrorMessage(body or "", code) end

    local response = decodeJson(body or "")
    if not response then
        local preview = safePreview(body, 180)
        local mime = ""
        if diagnostics and diagnostics.headers then
            mime = diagnostics.headers:match("[Cc]ontent%-[Tt]ype:%s*([^\r\n]+)") or ""
        end
        return nil, "Google returned HTTP 200, but the response was not valid GenerateContent JSON. Response bytes: "
            .. tostring(#(body or "")) .. "; content type: " .. tostring(mime) .. "; preview: " .. preview
            .. ". No second request was made."
    end

    if response.error then
        return nil, tostring(response.error.message or response.error.status or "Gemini returned an API error.")
    end

    local summary, metadata = extractGenerateContentText(response)
    if summary == "" then
        local block_reason = metadata and metadata.prompt_feedback and metadata.prompt_feedback.blockReason
        local finish_reason = metadata and metadata.finish_reason
        if block_reason then
            return nil, "Gemini did not generate a recap because the prompt was blocked (" .. tostring(block_reason) .. "). No retry was made."
        end
        if finish_reason then
            return nil, "Gemini returned HTTP 200 but no readable text (finish reason: " .. tostring(finish_reason) .. "). No retry was made."
        end
        return nil, "Gemini returned HTTP 200 but no candidate text. Response bytes: " .. tostring(#body)
            .. ". No retry was made."
    end

    if metadata and metadata.finish_reason and metadata.finish_reason ~= "STOP" then
        local reason = tostring(metadata.finish_reason)
        return summary, "Gemini returned a recap but stopped with finish reason " .. reason .. ". The recap may be incomplete; no retry was made.", { partial = true, usage = metadata.usage }
    end
    return summary, nil, { partial = false, usage = metadata and metadata.usage, model_version = metadata and metadata.model_version }
end

return GeminiClient
