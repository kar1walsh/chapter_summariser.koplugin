# Chapter Summariser for KOReader

An EPUB-focused KOReader plugin for readers who want to revisit chapters, keep track of a novel's story, and refresh their memory without leaving the book.

**Current version:** 1.1.5  
**AI model:** Google Gemini 3.5 Flash-Lite (`gemini-3.5-flash-lite`)  
**Document format:** EPUB

## Features

- **Summarise A Chapter** — choose a chapter and generate a saved chapter recap. If a recap already exists, you can view it or generate it again.
- **Book Memory** — build chronological story memory as chapters are processed. The plugin works through missing earlier chapters in order rather than giving a summary of an earlier chapter access to later chapters.
- **Brief Chapter Summary** — open the brief chapter summaries held in Book Memory.
- **Chapter Progress List** — review chapter progress and which chapter summaries have been generated.
- **This Chapter So Far** — generate a temporary recap of the current chapter up to the current reading position. This result is not saved and does not update Book Memory or Chapter Progress.
- **Gesture shortcuts** — assign the chapter picker, Brief Chapter Summary, and This Chapter So Far actions to KOReader gestures.

The chapter picker uses `[Recap]` for chapters with a saved full recap and `[Memory]` for chapters with Book Memory. Chapters without either remain unlabelled.

## Compatibility

- Designed for KOReader and EPUB books.
- Version **1.1.5** has been tested and confirmed working by the maintainer on **KOReader 2026.07.1** running on a **Kindle Paperwhite 4**, including the updated gesture label and the plugin features.
- Other devices and KOReader versions have not yet been independently verified. Device-specific network and reading-position behaviour may differ.

## Installation

### Manual installation

1. Exit KOReader completely.
2. Download the latest plugin ZIP from the project's GitHub Releases page.
3. Extract the ZIP. It should contain a folder named `chapter_summariser.koplugin`.
4. Copy that complete folder into your KOReader `plugins` directory. The result should be `koreader/plugins/chapter_summariser.koplugin/`.
5. Restart KOReader.
6. Open an EPUB and find **Chapter Summariser** under Tools. Assign gestures from KOReader's gesture settings if desired.

Do not copy the individual Lua files directly into `koreader/plugins/`; keep them inside the `.koplugin` folder.

### AppStore / Storefront

The project is intended to be discoverable by KOReader community plugin managers once its public GitHub repository is available and tagged with the `koreader-plugin` topic. Availability depends on each manager's repository index and refresh schedule. Until it appears there, use manual installation.

## Setup: Gemini API key

1. Create an API key using [Google AI Studio](https://aistudio.google.com/app/apikey).
2. In KOReader, open **Tools → Chapter Summariser → API Key**.
3. Paste and save your key.
4. Generate a recap when ready.

The plugin uses the fixed model ID `gemini-3.5-flash-lite`. The maintainer selected Flash-Lite after testing because it gave more reliable results for this plugin's chapter summaries. The model is not user-selectable in the interface.

A normal-sized chapter usually uses one generation request. Very long chapters or reading portions may be split into several requests and then combined, so unusually long content can consume more quota. The plugin does not automatically retry failed generation requests or silently switch to another model.

Check Google's current [Gemini API pricing and usage tiers](https://ai.google.dev/gemini-api/docs/pricing) before use. Availability, free-tier limits, billing, and prices can change.

## Spoiler handling

The plugin is designed to process chapters chronologically and limit **This Chapter So Far** to the current reading position within the current chapter. It uses KOReader's EPUB navigation and reading-position information to identify the page and chapter boundaries. If it cannot validate those boundaries, it should stop rather than send uncertain text.

No automated method can guarantee perfect spoiler prevention for every EPUB. EPUB table-of-contents structures vary, and the result should be treated as a reading aid rather than a guarantee. Please report any case where a recap refers to an event beyond the selected chapter or reading position.

For **This Chapter So Far**, the current chapter's full recap and full-chapter memory are excluded from its context. Only available earlier-chapter notes may be used. It does not backfill missing earlier memory; context can therefore be incomplete if earlier chapters have not been processed.

## Privacy and data handling

This plugin does not use a developer-operated server or analytics service. It connects directly from KOReader to Google's Gemini API over HTTPS using the API key supplied by the reader.

When you request a generation, the plugin sends Google the prompt and the relevant book text. Depending on the operation, the request may also include the book title, chapter title, and previously generated chapter notes or Book Memory needed for context. The plugin does not upload the EPUB file itself.

- Your Gemini API key is saved in KOReader's local settings directory in the plugin settings file. The plugin does not add its own encryption layer; protect your device and local KOReader settings/backups accordingly.
- Saved chapter recaps and Book Memory are stored locally in KOReader settings files. The plugin does not send those files to a separate service.
- The plugin does not retain the full extracted chapter text as its summary cache; the local recap cache stores generated summaries and source fingerprints.
- **This Chapter So Far** is temporary: its generated result is not written to the summary cache, Book Memory, or Chapter Progress.
- When the curl transport is used, the request body and a short-lived curl configuration are written to temporary files for the HTTPS request and normally removed when the request finishes. An abrupt device or process failure could interrupt cleanup. The API key is sent in an HTTPS request header, not as part of the URL.

Google's current pricing page marks Gemini 3.5 Flash-Lite free-tier prompts as used to improve Google's products, while paid-tier prompts are marked as not used for product improvement. This can change, so check Google's [Gemini API pricing page](https://ai.google.dev/gemini-api/docs/pricing) and [usage-policy / abuse-monitoring documentation](https://ai.google.dev/gemini-api/docs/usage-policies) before sending book text. Google also describes limited human review of content flagged for abuse monitoring. Do not use this plugin with material you are not entitled to submit to the service.

## Development and AI assistance

This project began as the maintainer's idea for a focused tool to help remember novels while reading in KOReader. The maintainer defined the intended workflow, feature requirements, spoiler-handling rules, interface decisions, and testing priorities, and tested successive versions on a Kindle Paperwhite 4.

ChatGPT provided substantial assistance with the Lua implementation, code revisions, debugging, and documentation. The project was developed iteratively: the maintainer described the behaviour wanted, tested builds on-device, reported problems and results, and decided which changes to keep. This is an AI-assisted project. The source is intended for public distribution so that other KOReader users and experienced Lua developers can inspect it, report problems, and contribute improvements.

## Reporting issues

When reporting a problem, please include:

- KOReader version and device model.
- Whether the book is EPUB and, if possible, whether its table of contents has chapter entries.
- Which menu item or gesture you used.
- The exact error message, if one appeared.
- Relevant excerpts from KOReader's `crash.log` where appropriate. **Remove API keys and personal book/file paths before sharing logs.**

Please do not post your Gemini API key, private book text, or an entire copyrighted book in an issue.

## Acknowledgements

- [KOReader](https://github.com/koreader/koreader), the open-source ebook reader this plugin extends.
- [Google Gemini API](https://ai.google.dev/gemini-api/docs), used for chapter recap and Book Memory generation.

## License

Chapter Summariser is licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**. See [`LICENSE`](LICENSE) and the [official license text](https://www.gnu.org/licenses/agpl-3.0.txt).
