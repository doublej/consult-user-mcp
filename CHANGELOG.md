# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [1.4.0] - 2026-01-25

### Added
- History detail view with full question, answer, and metadata
- History entry navigation with back button
- Hover states and chevron indicators on history rows

## [1.3.0] - 2026-01-20

### Added
- Dialog history tracking with viewer in settings
- Keyboard accessibility to iOS PWA choice cards
- Automated tests for MCP server
- PNG icons for iOS PWA compatibility
- Input validation for iOS PWA API endpoints
- Auto-update via GitHub releases

### Changed
- Split DialogManager.swift into focused modules
- Replace magic key codes with KeyCode constants

### Fixed
- Sync snooze clear from CLI to macOS app
- Fallback error with setup instructions if Dialog CLI not found
- Error logging for file write failures in UserSettings
- Timeout handling for long dialogs in MCP server
- Validate choice descriptions array length matches choices
- Error handling for JSON parse and CLI path in swift.ts

## [1.2.0] - 2026-01-10

### Changed
- Refactor dialog system to use native Swift CLI, remove AppleScript provider

### Fixed
- Snooze crash and menu bar icon theme
- Install script with MCP config output, use bun consistently

## [1.1.2] - 2025-12-16

### Fixed
- Add execute permission to install.sh

## [1.1.1] - 2025-12-16

### Added
- Install script with quarantine removal instructions

### Changed
- Switch from npm/pnpm to bun

### Fixed
- dialog-cli path resolution
- GitHub link in macOS app

## [1.1.0] - 2025-12-11

### Changed
- Rename from "Speak MCP" to "Consult User MCP" across codebase
- Consolidate dialog types and improve focus handling
- Make keyboard hints more compact

### Fixed
- ScrollView clipping and toolbar transparency
- Allow typing 's' in feedback text field without triggering snooze
- Allow typing 'f' in feedback text field

### Removed
- Shader overlay effect

## [1.0.0] - 2025-11-27

Initial release.

### Added
- Native macOS dialog system for MCP servers
- Confirmation, multiple choice, text input, and multi-question dialogs
- Snooze feature (1-60 minutes)
- Feedback feature for redirecting the agent
- iOS PWA companion for remote MCP support
- macOS menu bar app with settings UI

### Removed
- Text-to-speech feature
