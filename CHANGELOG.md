# Changelog

All notable changes to this project will be documented in this file.

<!-- Auto-generated from docs/src/lib/data/releases.json -->
<!-- Run: bun run scripts/generate-changelog.ts -->

## [Unreleased]

## [1.15.0] (macOS) - 2026-02-23

### Added
- Settings now includes an Uninstall section to completely remove the app and all MCP configurations
- Uninstaller shows exactly what will be removed before proceeding
- Option to keep settings and dialog history when uninstalling
- CLI uninstall scripts (uninstall.sh for macOS, uninstall.ps1 for Windows) as fallback options

## [1.14.0] (macOS) - 2026-02-22

### Added
- App checks on launch if usage hints in CLAUDE.md are outdated and offers to update them
- Menu bar icon shows an orange badge dot when an app update is available
- Clicking the menu bar icon while an update is available opens the Updates tab directly
- Updates settings now show a Usage Hints section with per-target version status and update buttons
- Form dialogs (wizard and accordion) now support body text for additional context

### Changed
- Choose and form dialogs now display a proper header with icon and title instead of plain text

## [1.13.0] (macOS) - 2026-02-22

### Added
- New tweak tool opens a slider panel for real-time numeric value tuning with live file writes
- Three parameter formats: text search patterns, CSS selector references, and direct file locations
- Save to File keeps live edits, Tell Agent reverts files and returns values for the agent to apply

### Changed
- Base prompt restructured to v2.7.0 with 25% fewer tokens and tweak documentation

## [1.12.0] (macOS) - 2026-02-16

### Added
- Ask differently: toolbar button lets you request a different dialog type mid-conversation
- Humanize responses: answers returned as plain text instead of JSON (e.g. "The user confirmed." instead of {"answer": true})
- Review before send: preview exactly what gets returned to the agent before it's sent
- Validate choices: agents can no longer offer "All of the above" options — must use multi-select instead

### Changed
- Base prompt updated to v2.2.0 with ask-differently and humanize guidance

## [1.11.0] (macOS) - 2026-02-09

### Added
- macOS and Windows now have independent version numbers and release cycles

### Changed
- Auto-updater now correctly identifies macOS releases when both platforms are published
- Install script now uses GitHub API to find the latest macOS release

## [1.10.0] (macOS) - 2026-02-08

### Added
- Notifications now show the project badge when `project_path` is provided, matching all other dialog types
- App now checks for updates automatically on MCP server startup

### Changed
- Project path is cached across both `ask` and `notify` — set it once on either tool and all subsequent calls inherit it
- Base prompt updated to v2.1.0 with notify project_path guidance

## [1.1.0] (Windows) - 2026-02-10

### Added
- Professional installer with automatic setup — no more manual zip extraction
- Auto-updates with delta downloads — only download what changed between versions
- First-run wizard automatically configures Claude Code MCP server
- Launch at startup toggle in Settings

### Changed
- Executables renamed to cross-platform convention (dialog-cli.exe, consult-user-mcp.exe)

## [1.0.0] (Windows) - 2026-02-09

### Added
- Native Windows dialogs that let AI agents ask you questions
- Four dialog types: yes/no, multiple choice, text input, and multi-question wizards
- System tray app with settings, snooze management, and auto-updates
- Dark-themed WPF dialogs with keyboard shortcuts and markdown support
- Snooze dialogs for 1-60 minutes when you're busy
- Provide feedback to redirect the agent mid-conversation

## [1.9.5] (macOS) - 2026-02-08

### Added
- Project path is cached after the first call, saving tokens on every subsequent dialog

### Changed
- MCP interface consolidated from 5 tools to 2: `ask` (with type=confirm/pick/text/form) and `notify`
- Responses are now compact — only meaningful fields are returned, no more null padding
- Single-select is now the default for pick dialogs (was multi-select)
- Base prompt updated to v2.0.0 with streamlined tool reference and examples

## [1.9.4] (macOS) - 2026-02-07

### Added
- Settings now include a dedicated About pane with version details and a direct GitHub Issues feedback link
- Updates settings now support automatic-check toggle, daily/weekly/manual cadence, reminder interval, and pre-release channel selection
- General settings now let you choose notification sounds separately for question dialogs and informational notifications

### Changed
- Update reminder dialogs now respect your configured reminder interval instead of fixed 1-hour/24-hour options
- Notification dialogs now render as native SwiftUI panes with optional sound and history logging
- Visual test scenarios now cover notify dialogs and expanded snooze/feedback panes with full current CLI arguments

### Fixed
- Project badges now stay compact as text-sized pills in the top-right corner without overlapping dialog content

## [1.9.3] (macOS) - 2026-02-02

### Added
- Progress heartbeat keeps the MCP client connection alive during slow dialog interactions

### Fixed
- Long-running dialogs no longer spawn duplicates when the MCP client retries after timeout

## [1.9.2] (macOS) - 2026-02-01

### Changed
- Install wizard now has a persistent footer bar with Back/Next buttons
- Install wizard progress stepper uses evenly-spaced columns with centered labels
- Project rows now have consistent height and larger action button hit targets
- Base prompt toggle, status badge, and file options grouped in a single container
- History row status dot and chevron grouped as a tighter trailing cluster

### Fixed
- Sidebar badges now align vertically across all rows

## [1.9.1] (macOS) - 2026-02-01

### Changed
- Settings version panel is now more compact with a cleaner layout

### Fixed
- Keyboard shortcuts (S, F) no longer trigger while typing in text input fields

## [1.9.0] (macOS) - 2026-01-31

### Added
- History view now includes a search field to filter entries by question, answer, or client name
- Day sections in history are now collapsible, with today expanded by default
- History footer now has a button to reveal the data folder in Finder

### Changed
- History entries are now stored in per-day files for better performance and organization
- Existing history is automatically migrated to the new per-day format
- Toolbar keyboard shortcuts (S, F, Esc) now handled consistently across all dialog types

## [1.8.0] (macOS) - 2026-01-31

### Added
- Text input dialog now supports snooze and feedback, matching all other dialogs
- Dev build workflow now installs directly to the running app with one command

### Changed
- Test dialogs are now hidden behind option+click on the tray icon
- Right-click tray menu now shows settings, updates, and quit only
- Settings window split into modular views for better maintainability
- Text input dialog migrated from AppKit to SwiftUI for consistency

## [1.7.0] (macOS) - 2026-01-30

### Added
- Documentation site now features interactive dialog examples from real development history
- 28 real questions displayed in scrollable gallery with actual options and answers

### Changed
- Settings window height increased to reduce scrolling and better use screen space
- Replaced static screenshots with interactive feature panels showing Snooze and Feedback dialogs

## [1.6.0] (macOS) - 2026-01-30

### Added
- Usage hints now include concrete examples of correct vs incorrect question patterns
- Better guidance for when agents should batch questions vs ask sequentially

### Changed
- Agents now batch multiple questions together instead of asking one at a time
- Agents continue working smoothly after receiving answers without checking back in

## [1.5.0] (macOS) - 2026-01-28

### Added
- Dialogs now show which project they belong to via project_path parameter
- Usage hints now include version info for detecting when updates are available
- Install wizard shows update option when newer usage hints are bundled

### Fixed
- Button cooldown now prevents accidental rapid clicks across all dialogs

## [1.4.1] (macOS) - 2026-01-27

### Added
- Text input dialogs now support markdown formatting in the body text
- Inline code blocks are now properly rendered in dialog text
- Partial answers are now preserved when providing feedback mid-dialog

### Fixed
- Button cooldown now works correctly across multiple interactions

## [1.4.0] (macOS) - 2026-01-25

### Added
- View full question details, answers, and metadata in history
- Navigate through history entries with back button support
- History rows now show hover states and navigation indicators

## [1.3.0] (macOS) - 2026-01-20

### Added
- All dialog interactions are now tracked and viewable in settings
- iOS PWA now supports full keyboard navigation
- App now checks for updates automatically via GitHub
- iOS PWA now works on home screen with proper icons

### Fixed
- Snooze state now syncs properly between CLI and menu bar
- Better error messages when Dialog CLI isn't found
- Long-running dialogs no longer timeout unexpectedly

## [1.2.0] (macOS) - 2026-01-10

### Changed
- Dialogs are now native Swift for better performance and reliability

### Fixed
- Snooze feature now works reliably without crashes
- Menu bar icon now matches your system theme

## [1.1.2] (macOS) - 2025-12-16

### Fixed
- Installation script now runs without permission errors

## [1.1.1] (macOS) - 2025-12-16

### Added
- One-line install script with clear setup instructions

### Changed
- Faster builds using bun instead of npm

### Fixed
- Dialog CLI now works correctly regardless of install location

## [1.1.0] (macOS) - 2025-12-11

### Changed
- Renamed from 'Speak MCP' to 'Consult User MCP'
- Dialogs now focus correctly when switching between apps
- Keyboard hints are now more compact and less intrusive

### Fixed
- Typing 's' or 'f' in feedback fields no longer triggers shortcuts

### Removed
- Removed experimental shader overlay effect

## [1.0.0] (macOS) - 2025-11-27

### Added
- Native macOS dialogs that let AI agents ask you questions
- Four dialog types: yes/no, multiple choice, text input, and multi-question wizards
- Snooze dialogs for 1-60 minutes when you're busy
- Provide feedback to redirect the agent mid-conversation
- iOS companion app for answering dialogs remotely
- Menu bar app with settings and status display
