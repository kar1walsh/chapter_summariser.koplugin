# Release checklist

Use this for every release. Copy it into the release pull request and tick it off.

## Status: v2.0.0 (stable)

- [x] Tested on a Kindle Paperwhite 4 with KOReader 2026.07.1.
- [x] Full AGPL-3.0 text in `LICENSE`.
- [x] Public GitHub repository with contents at the repository root.
- [x] GitHub topic `koreader-plugin` added.
- [x] GitHub Release `v2.0.0` published with `Chapter_Summariser_v2.0.0_Manual_Install.zip`.
- [x] Privacy and data-handling section in the README.
- [ ] Optional: submit to `koreader/contrib` following that repository's current instructions.
- [ ] Optional: announcement post once there are screenshots.

## For each new release

- [ ] Update the version in `_meta.lua` **and** `main.lua` (`version = ...`). They must match.
- [ ] Update `MANIFEST.txt`, `CHANGELOG.md`, `COMPATIBILITY.md` and the README version line.
- [ ] Test on a device and record the device and KOReader version in `COMPATIBILITY.md`.
- [ ] Build the install zip. It must contain a single `chapter_summariser.koplugin/` folder holding `_meta.lua`, `main.lua`, `gemini_client.lua`, and the docs.
- [ ] Tag `vX.Y.Z` on `main` and create a GitHub Release with the zip attached.
- [ ] Check the Release page shows the correct zip, then check the plugin appears in the KOReader storefront.
