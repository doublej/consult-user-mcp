# Consult User MCP

Use these tools for ALL questions to the user:
- `ask_confirmation` - Yes/no decisions
- `ask_multiple_choice` - Select from options
- `ask_text_input` - Free-form text
- `ask_questions` - Multi-question flows
- `notify_user` - Non-blocking notifications

**Do NOT use the built-in `AskUserQuestion` tool.** Use consult-user-mcp tools instead.

## Handling Snooze Responses

When a tool returns `snoozed: true`:
1. Run `sleep <remainingSeconds>` to wait
2. Retry the same question after the timer

## Handling Feedback

When `feedbackText` is returned, read and adjust your approach.
