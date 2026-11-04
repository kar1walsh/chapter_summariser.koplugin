# Changelog

## 2.0.0 (stable release)

This release brings the previously tested development improvements together as the first 2.0 release.

- Added a current-chapter indicator beneath the chapter-picker title and a `[Current]` marker beside the current chapter.
- Added **Summarise Previous Chapter** to the main menu and as an assignable KOReader gesture. A valid saved recap opens without a Gemini request; otherwise, the previous chapter is generated through the existing spoiler-safe workflow.
- Reorganised the main menu and introduced a Settings submenu containing **API Key (Gemini)** and **Detailed Summary Length**.
- Added Short (125–175 words), Standard (250–300 words), and Extended (400–450 words) detailed-recap preferences. Standard is the default. The preference applies to detailed chapter recaps and does not change Book Memory notes, Brief Chapter Summary, or This Chapter So Far.
- Strengthened source-grounded recap instructions and an in-request factual check for names, places, dates, quantities, chronology, cause-and-effect, and uncertainty.
- Improved long-chapter note consolidation so conflicting details are not resolved by guessing.
- Kept duplicate EPUB chapter labels distinct using local document positions and identifiers; internal story indexes are not presented to Gemini as chapter numbers.
- Preserved chronological, spoiler-safe Book Memory processing, existing saved data formats, gesture actions, and the temporary nature of This Chapter So Far.

The maintainer tested this release on a Kindle Paperwhite 4 running KOReader 2026.07.01, including the main menu, Settings, summary-length choices, chapter selection, previous-chapter shortcut, and recap generation across different books. Other devices and KOReader versions have not been independently verified.

## 1.1.12 (development build — source-grounded recap quality)

- Strengthened detailed recap prompts with a silent source check for names, locations, dates, quantities, list items, chronology, cause-and-effect, and uncertainty.
- Clarified that EPUB chapter labels and internal story indexes can repeat or be non-sequential; recaps must not calculate or state a chapter number.
- Removed internal story chapter indexes and repeated TOC labels from the Gemini Book Memory request payload. Lua retains those values locally for chronological safety, cache keys, and persistence; the model receives ordered notes and opaque unit IDs instead.
- Improved long-chapter section notes and merge instructions so the consolidation step does not resolve conflicting details by guessing.
- Kept the three summary-length targets unchanged: Short 125–175, Standard 250–300, Extended 400–450 words.
- Kept the spoiler-safe sequential processing algorithm, saved-summary format, gesture registrations, menus, and Gemini request count unchanged. Quality checks are instructions within existing requests; no additional review request is made.

## 1.1.11 (development build — tighter summary-length targets)

- Tightened detailed-recap targets to Short (125–175 words; aim 150), Standard (250–300 words; aim 275), and Extended (400–450 words; aim 425).
- Strengthened the distinct content-selection instructions for each length, including an explicit pre-response length check and direction to avoid padding or inventing content.
- Updated the Settings labels and README to show the new ranges.
- Kept the length preference limited to detailed chapter recaps, including long-chapter merges and memory-aware target recaps. Book Memory notes, brief chapter summaries, and This Chapter So Far are unchanged.
- No changes to the Gemini API request shape, menus, gestures, cache behaviour, or spoiler-safe chapter processing.

## 1.1.10 (development build — summary-length prompt refinement)

- Reworked the Short, Standard, and Extended detailed-recap instructions so each has a distinct target range, paragraph guide, and level of detail.
- Removed the previous cross-over guidance that allowed Standard recaps to fall into the Short or Extended ranges.
- Kept the selected length limited to detailed chapter recaps; Book Memory updates, brief chapter notes, and This Chapter So Far are unchanged.
- No changes to menus, gestures, cache behaviour, API request flow, or spoiler-safe chapter processing.

## 1.1.9 (development build — not yet tested on-device)

- Reorganised the main menu to: Summarise A Chapter, Book Memory, Summarise Previous Chapter, This Chapter So Far, Settings.
- Added a Settings submenu containing **API Key (Gemini)** and **Detailed Summary Length**.
- Added Short (100–200 words), Standard (250–350 words), and Extended (350–450 words) detailed recap length preferences. Standard is the default.
- The selected length is saved locally and applies to detailed chapter recaps, including the final recap for long chapters and the Summarise Previous Chapter workflow. It does not change Book Memory notes, Brief Chapter Summary, or This Chapter So Far.
- Existing saved recaps remain available and are not automatically regenerated when the preference changes. The selected length applies to new generations or when a saved recap is explicitly regenerated.


## 1.1.7 (development build)

- Added a **Summarise Previous Chapter** main-menu item and assignable KOReader gesture.
- The shortcut identifies the story chapter immediately before the current reading chapter.
- Opens a valid saved recap immediately without a Gemini request; otherwise generates and saves the previous chapter recap through the existing spoiler-safe memory-aware workflow.
- Shows a clear message when the current chapter cannot be identified or the reader is already in the first chapter.
- Capitalised the chapter-picker subtitle to `Currently Reading`.

## 1.1.6 (development build)

- Added a current-chapter label beneath the chapter picker title.
- Marked the current story chapter at the start of its list row with `[Current]`, keeping the marker visible even for long chapter titles.
- Reuses KOReader reading-position and TOC chapter-boundary information; this display does not generate text or make API requests.

## 1.1.5

- Renamed the Brief Chapter Summary gesture label to `Brief Chapter Summary`.
- Retained the saved-summary menu labels `View Saved Summary` and `Generate Again`.
- Retained the `[Recap]` and `[Memory]` chapter-picker status tags.
- Preserved the menu order and temporary This Chapter So Far behaviour.

## 1.1.4

- Capitalised the saved-summary menu actions as `View Saved Summary` and `Generate Again`.

## 1.1.3

- Changed the chapter-picker recap status label to `[Recap]`.

## 1.1.2

- Removed the `[Memory pending]` label; chapters without a saved recap or Book Memory are unlabelled.

## 1.1.1

- Polished main-menu wording and chapter-picker status labels.
- Added the Brief Chapter Summary gesture label and retained existing action IDs.
