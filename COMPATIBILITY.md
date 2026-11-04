# Compatibility

## Confirmed test environment

- Plugin version: 1.1.5
- KOReader: 2026.07.1
- Device: Kindle Paperwhite 4
- Book format tested: EPUB

The maintainer has tested v1.1.5 on this setup and confirmed that the plugin is working, including the updated gesture label and the main plugin features. The maintainer has also tested the v1.1.6 current-chapter indicator on this device and confirmed that it correctly identifies and marks the current chapter.

The v1.1.7 development build adds a Summarise Previous Chapter menu item and assignable gesture, and capitalises the current-chapter label; the maintainer confirmed that functionality working on-device. The v1.1.9 development build reorganises the main menu, moves the Gemini key into Settings, and adds a saved detailed-summary-length preference; the maintainer confirmed the settings and other functionality working on-device, but reported that the length choices produced similar-sized recaps. The v1.1.10 development build revises only the detailed-recap prompts to make the three length choices more distinct. The revised prompts still need on-device testing.

## Not yet independently verified

- Other Kindle models
- Kobo devices
- Android, Linux, macOS, and other KOReader builds
- Non-EPUB formats

The current-position recap relies on KOReader's EPUB reading-position and table-of-contents information. EPUBs with unusual navigation structures may behave differently. Please include the device, KOReader version, and (where possible) a small description of the EPUB's table of contents when reporting issues.
