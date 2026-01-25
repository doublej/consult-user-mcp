# Consult User MCP

Prefer these MCP tools over text-based questions for user input:
- `ask_confirmation` - Yes/no decisions
- `ask_multiple_choice` - Select from options
- `ask_text_input` - Free-form text
- `ask_questions` - Multi-question flows
- `notify_user` - Non-blocking notifications

## Handling Snooze Responses

When a tool returns `snoozed: true`:
1. Run `sleep <remainingSeconds>` to wait
2. Retry the same question after the timer

## Handling Feedback

When `feedbackText` is returned, read and adjust your approach.
