# Changelog

All notable changes to this project will be documented in this file.

<!-- Auto-generated from docs/src/lib/data/releases.json -->
<!-- Run: bun run scripts/generate-changelog.ts -->

## [Unreleased]

## [2.6.7] (macOS) - 2026-08-17

### Fixed
- Automatic updates work again. In 2.6.5 and 2.6.6 the download could gain a stray file while being unpacked, which broke the app's signature and stopped macOS from launching it afterwards. The downloads for both of those versions have been replaced, so updating from any version now works.
- If an update ever does fail to install, the app now restores the previous version instead of leaving nothing behind.
- The list of changes shown before an update loads reliably again. It was read from a single address that rate-limits, and any refusal from it looked identical to a version with nothing to report. It now reads from the documentation site first, retries, and says plainly when it could not load rather than showing an empty list.

## [2.6.6] (macOS) - 2026-08-17

### Changed
- Dialogs now always use the Caret interface. The style option in Appearance is gone, and installs still set to the older Classic look are moved across on first launch. Caret is the one that gets designed, measured and tested, so it is the one everybody gets.

### Removed
- Removed the style previews added in 2.6.5. The screenshots were never included in the download, so the setting showed a placeholder instead of a preview.

## [2.6.5] (macOS) - 2026-08-17

### Changed
- The app is now signed with a Developer ID and notarized by Apple. It opens without a security warning, and you no longer have to clear the quarantine flag by hand after installing.
- macOS downloads are now a disk image: open it and drag the app to Applications. Existing installs keep updating in place as before.

### Fixed
- In a multi-question form, choosing 'Other' now puts the cursor in that question's own text box. On the following question the cursor no longer jumped into a text box nobody had asked for, which swallowed the key that picks an option.

## [2.6.4] (macOS) - 2026-07-31

### Fixed
- Characters typed into a text field are no longer treated as keyboard shortcuts when the dialog cannot bring itself to the front — behind a full-screen app, during a Space switch, or while a system alert holds the foreground. An answer beginning with 's' opened the snooze tray instead of being typed
- Choosing the 'Other' option now puts the cursor in its text box, so you can just start typing your custom answer

## [2.6.3] (macOS) - 2026-07-31

### Fixed
- A notification longer than a couple of lines is no longer drawn over its own title and cut off at the bottom — the whole message is shown, and a long one shows far more of itself than before
- Opening the note pane no longer draws it through the Cancel and Next buttons underneath
- A long list of options with the note pane open no longer paints its rows over the question, the header and the buttons
- A prefilled answer containing line breaks — a release note, a commit message — stays inside its field instead of being drawn across the question above it and the buttons below
- Picking an option that does not yet answer the question now grows the dialog to fit the hint that appears, instead of drawing it outside the window

## [2.6.2] (macOS) - 2026-07-31

### Fixed
- A dialog could fail to appear at all on a machine whose audio device was unavailable, exclusive to another app, or wedged — the notification sound was played before the window was built and could block it indefinitely, leaving the agent waiting for an answer to a question that was never shown. The sound now plays out of the way of the dialog
- A dialog now appears even when it cannot bring itself to the front, instead of staying invisible

## [2.6.1] (macOS) - 2026-07-31

### Fixed
- Pressing the left arrow to fix a typo while answering a form no longer throws the whole dialog away — the arrows now move through what you are typing, as they should
- In the Bracket interface, the arrow keys no longer jump between form steps while you are typing an answer
- The light theme no longer draws dark panels over a light dialog — setting a theme the interface does not recognise leaves its own colours alone instead of replacing them

## [2.6.0] (macOS) - 2026-07-30

### Added
- A completely redesigned dialog interface is available — switch it on with the New Interface toggle in Settings → General
- When the agent stops waiting for an answer (after 10 minutes), the dialog now stays on screen and clearly says the agent continued with its best guess — instead of silently collecting an answer that would never be read
- Dialogs can be reskinned — the visual layer is now swappable, with two extra experimental looks selectable via the DIALOG_SKIN environment variable

### Fixed
- A question asked after an earlier one timed out no longer gets stuck behind the abandoned dialog

### Removed
- The pre-release versions toggle is gone from Updates settings — beta builds can still be enabled directly in settings.json

## [2.5.1] (macOS) - 2026-07-21

### Fixed
- Typing in the feedback pane no longer triggers keyboard shortcuts — even the first characters typed right after opening it land in your note instead of toggling the snooze panel or opening menus
- The feedback pane no longer breaks the dialog layout — toolbar edges sticking out past the rounded corners and clipped buttons on right-positioned dialogs are gone
- The feedback editor is focused the instant the pane opens, so you can start typing immediately
- Fast typists can no longer accidentally open the ask-differently menu while a dialog is still appearing

## [2.5.0] (macOS) - 2026-07-14

### Added
- Every tool now returns machine-readable structured responses, so agents reliably recognize answers, snoozes, cancellations, and feedback notes — even in clients that trim long instructions
- Tools now declare display titles and behavior hints (read-only, non-destructive), so clients can show friendlier names and skip unnecessary permission prompts
- Every tool parameter is now documented directly in the schema, so agents fill in dialogs correctly without guessing at field semantics

### Changed
- Base prompt v2.15.0 puts response-handling rules first, so critical guidance survives clients that truncate long instructions
- The layout editor tool is no longer offered on Windows, where it cannot run

### Fixed
- Away (AFK) mode now tells the agent to proceed with sensible defaults instead of pointing it at a disabled question tool
- The MCP server now reports its real version to connected clients

## [2.4.0] (macOS) - 2026-07-07

### Added
- Slide out a feedback pane on any dialog to leave a targeted note on a specific question — or the whole prompt — so the agent knows exactly how to adjust
- Feedback notes render markdown and show the question you're responding to right in the header
- Press ⌘F to open the feedback pane, including on text-input and password dialogs

### Changed
- The base prompt is now delivered to the agent automatically each session through the MCP server, instead of being copied into your global CLAUDE.md
- Updated baseprompt to v2.13.0 with per-question feedback guidance

### Fixed
- Tall forms and pick lists no longer get stuck endlessly resizing between two layouts

## [2.3.0] (macOS) - 2026-05-21

### Added
- New Away (AFK) mode auto-responds to interactive dialogs so the agent falls back to its native question tool instead of waiting on you
- Away can turn on automatically when the Mac sleeps and turn off when it wakes
- Away can turn on after a configurable period of keyboard and mouse inactivity (1–60 minutes), and clears as soon as you're back
- Right-click the menu bar icon to toggle Away (AFK) without opening Settings

### Fixed
- Menu bar icon and right-click menu icons now adapt correctly to light and dark menu bars

## [2.2.0] (macOS) - 2026-05-01

### Changed
- Accordion auto-advance, single-select clearing, and other-text behavior now stay consistent across all form types
- Updated baseprompt to v2.12.1 with clearer guidance for current selection and disambiguation

### Fixed
- Tweak sliders now disambiguate same-pattern matches in code, picking the right value when multiple identical literals exist
- Wizard and accordion forms reliably count answers when only the Other field is filled
- Login Items no longer accumulates duplicate entries when the app starts

## [2.1.3] (macOS) - 2026-03-22

### Fixed
- Dialog body text now renders reliably on macOS Sequoia instead of collapsing to zero height

## [2.1.2] (macOS) - 2026-03-10

### Fixed
- Keyboard shortcuts (S, F, A) no longer fire while typing in text fields
- Dialog body text now renders markdown formatting including newlines and bullet points

## [2.1.1] (macOS) - 2026-03-08

### Fixed
- Dialogs with long descriptions now wrap text correctly instead of expanding wider than the screen

## [2.1.0] (macOS) - 2026-03-08

### Added
- Custom scrub slider with vertical-distance sensitivity — drag up while sliding for fine-grained control
- Cogwheel settings button on each parameter card lets you reset values and expand slider min/max range

### Changed
- Show Edits console now opens as a separate floating panel that doesn't resize or disturb the main dialog
- Parameter labels now wrap instead of truncating at 100px, with flexible width up to 120px
- Framework badge, replay animations toggle, and show edits button are now grouped together

### Fixed
- Wizard form body text and question text now render reliably on macOS Sequoia

## [2.0.3] (macOS) - 2026-03-03

### Fixed
- Wizard form body text and question text now appear reliably on first render
- Tweak dialog footer no longer grows when switching between save and cancel states
- Smaller blocks in ASCII layout sketches now render on top of larger overlapping blocks

## [2.0.2] (macOS) - 2026-03-03

### Added
- Annotations now move with their parent block when dragged in the layout editor

### Fixed
- Layout editor grid cells are now square, maintaining proper aspect ratio instead of stretching to fill
- Drop-to-stash hint now floats as an overlay instead of pushing layout content around
- Annotation legend now aligns to the left edge consistently

## [2.0.1] (macOS) - 2026-03-03

### Fixed
- Keyboard hotkeys (S, F, A) no longer trigger while typing in the Other text field
- Arrow keys and Tab now work normally inside text fields instead of moving dialog focus
- Clicking the Other card now auto-focuses the text field for immediate typing
- Left/right arrow keys in wizard forms no longer navigate steps while editing text

## [2.0.0] (macOS) - 2026-03-02

### Added
- Notification and preview panes now include a report button for quick bug reporting
- Layout sketch editor now includes a report button in the title bar

### Changed
- Report button renamed from "Feedback" to "Report" for clarity

## [1.20.0] (macOS) - 2026-03-02

### Added
- New `propose_layout` tool opens an interactive grid editor where users can drag, resize, and arrange UI blocks visually
- Layout blocks support semantic roles (header, sidebar, canvas, footer), importance hierarchy, and elevation shadows
- Device frame chrome (browser, phone, tablet) wraps the sketch canvas for realistic previews
- Annotation callouts with numbered markers and a legend can be added to layouts
- Alignment guide lines appear on hover and drag to help position blocks precisely
- Wireframe content shapes (text, image, button, input, list, chart, etc.) render inside blocks
- Layouts can be defined as a semantic structure tree with direction and constraints as an alternative to explicit grid coordinates
- Layout results include structured data, ASCII art, and SVG output

### Changed
- Base prompt updated to v2.12.0 with positive framing and emphasis rebalancing

## [1.19.0] (macOS) - 2026-03-01

### Added
- Choose and form dialogs now include an "Other" option so users can type a custom answer not in the predefined list

### Changed
- Base prompt updated to v2.11.0 with "Other" option documentation

### Fixed
- Clicking an unfocused dialog now both activates the window and registers the action in a single click
- Clickable elements (choice cards, buttons, accordion headers) now show a pointer cursor on hover

## [1.18.1] (macOS) - 2026-03-01

### Fixed
- Buttons with long labels now truncate cleanly instead of overflowing
- Choice card subtitles now wrap at the correct width
- Dialog body text now sizes correctly after text wrapping, preventing cut-off content
- Dialog header text no longer extends past the window edges

## [1.18.0] (macOS) - 2026-02-28

### Added
- Every dialog now has a Feedback button that opens a two-step issue reporter with optional screenshot

### Fixed
- Feedback responses now include any partial input so the agent has full context
- Dialog text now adapts to window width instead of being capped at a fixed pixel size
- Dialog windows now anchor to their position edge when resizing
- Notify and preview dialogs now scroll long text instead of clipping it
- Build script now generates the app icon automatically on fresh clones

## [1.17.0] (macOS) - 2026-02-25

### Added
- Form dialogs now support mixed question types — combine choice selectors and text inputs in a single wizard or accordion
- Text questions in forms support placeholder text and hidden/password input mode
- Debug menu now includes Wizard Mixed and Accordion Mixed test cases

### Changed
- Base prompt updated to v2.10.0 with mixed question type documentation and examples

### Fixed
- Dialog window now resizes correctly when switching between question types of different heights

## [1.16.1] (macOS) - 2026-02-24

### Added
- New 'Start with Mac' toggle in General settings to automatically launch at login
- Settings window now appears in Cmd+Tab when open
- Uninstall removes the login item registration when cleaning up

## [1.16.0] (macOS) - 2026-02-24

### Added
- Tweak pane now detects CSS framework (Tailwind, Bootstrap, etc.) and shows it in the header
- Tweak pane replays CSS animations after each value change via WebSocket broadcast
- Windows dialogs now use selectable text for markdown content

### Changed
- Debug menu now loads test cases from JSON files instead of hardcoded data
- Base prompt updated with tweak animation replay instructions (v2.9.0)

### Fixed
- Dialog windows now reliably auto-size to fit their content on every step change
- Wizard and form question text now appears immediately on first load
- Choice card subtitles no longer overlap with titles

## [1.15.1] (macOS) - 2026-02-23

### Fixed
- Uninstall UI now clarifies that only consult-user-mcp entries are removed from config files, not the entire files

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
