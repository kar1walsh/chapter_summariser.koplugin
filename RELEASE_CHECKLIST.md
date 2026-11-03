# Public release checklist — v1.1.5

The v1.1.5 device test is complete. The remaining items concern public repository setup and distribution; this checklist does not imply acceptance by any catalogue.

- [x] Test v1.1.5 on the maintainer's Kindle Paperwhite 4 with KOReader 2026.07.1.
- [x] Test the chapter picker, saved-summary menu, Book Memory menu, gestures, and This Chapter So Far behaviour.
- [x] Include the complete AGPL-3.0 text in `LICENSE`.
- [ ] Create a public GitHub repository named `chapter_summariser.koplugin`.
- [ ] Upload the contents of this folder at the repository root (not an extra nested folder).
- [ ] Add the GitHub topic `koreader-plugin`.
- [ ] Create a GitHub Release tagged `v1.1.5` and attach a manual-install ZIP containing the `chapter_summariser.koplugin/` folder.
- [ ] Confirm the AppStore can discover the repository and validates `_meta.lua`.
- [ ] Verify Storefront discovery separately; do not assume the two catalogues index repositories in the same way.
- [ ] Submit a submodule pull request to `koreader/contrib` if desired, following that repository's current contribution instructions.
- [ ] Publish the Reddit announcement when the repository, release ZIP, privacy notice, and screenshots are ready.
