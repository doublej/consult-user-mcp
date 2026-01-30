# Changelog

All notable changes to this project will be documented in this file.

<!-- Auto-generated from docs/src/lib/data/releases.json -->
<!-- Run: bun run scripts/generate-changelog.ts -->

## [Unreleased]

## [1.6.0] - 2026-01-30

### Added
- Usage hints now include concrete examples of correct vs incorrect question patterns
- Better guidance for when agents should batch questions vs ask sequentially

### Changed
- Agents now batch multiple questions together instead of asking one at a time
- Agents continue working smoothly after receiving answers without checking back in

## [1.5.0] - 2026-01-28

### Added
- Dialogs now show which project they belong to via project_path parameter
- Usage hints now include version info for detecting when updates are available
- Install wizard shows update option when newer usage hints are bundled

### Fixed
- Button cooldown now prevents accidental rapid clicks across all dialogs

## [1.4.1] - 2026-01-27

### Added
- Text input dialogs now support markdown formatting in the body text
- Inline code blocks are now properly rendered in dialog text
- Partial answers are now preserved when providing feedback mid-dialog

### Fixed
- Button cooldown now works correctly across multiple interactions

## [1.4.0] - 2026-01-25

### Added
- View full question details, answers, and metadata in history
- Navigate through history entries with back button support
- History rows now show hover states and navigation indicators

## [1.3.0] - 2026-01-20

### Added
- All dialog interactions are now tracked and viewable in settings
- iOS PWA now supports full keyboard navigation
- App now checks for updates automatically via GitHub
- iOS PWA now works on home screen with proper icons

### Fixed
- Snooze state now syncs properly between CLI and menu bar
- Better error messages when Dialog CLI isn't found
- Long-running dialogs no longer timeout unexpectedly

## [1.2.0] - 2026-01-10

### Changed
- Dialogs are now native Swift for better performance and reliability

### Fixed
- Snooze feature now works reliably without crashes
- Menu bar icon now matches your system theme

## [1.1.2] - 2025-12-16

### Fixed
- Installation script now runs without permission errors

## [1.1.1] - 2025-12-16

### Added
- One-line install script with clear setup instructions

### Changed
- Faster builds using bun instead of npm

### Fixed
- Dialog CLI now works correctly regardless of install location

## [1.1.0] - 2025-12-11

### Changed
- Renamed from 'Speak MCP' to 'Consult User MCP'
- Dialogs now focus correctly when switching between apps
- Keyboard hints are now more compact and less intrusive

### Fixed
- Typing 's' or 'f' in feedback fields no longer triggers shortcuts

### Removed
- Removed experimental shader overlay effect

## [1.0.0] - 2025-11-27

### Added
- Native macOS dialogs that let AI agents ask you questions
- Four dialog types: yes/no, multiple choice, text input, and multi-question wizards
- Snooze dialogs for 1-60 minutes when you're busy
- Provide feedback to redirect the agent mid-conversation
- iOS companion app for answering dialogs remotely
- Menu bar app with settings and status display
