<!-- version: 1.3.1 -->
# Consult User MCP - Required Usage

## Critical Rules

**NEVER use the built-in `AskUserQuestion` tool.** That tool is DISABLED. Use only consult-user-mcp tools.

**BATCH questions when you have 2+ questions.** Asking sequentially creates friction and interrupts user flow. Use `ask_questions` to ask multiple questions at once.

**CONTINUE smoothly after getting answers.** Don't check back in or ask "should I proceed?" - just use the answers and keep working.

**ALWAYS pass `project_path`** on every dialog tool call (except `notify_user`). This shows which project the dialog belongs to. Use the current working directory or project root path.

## Tool Selection

Choose the right tool based on your situation:

| Situation | Tool | When to Use |
|-----------|------|-------------|
| 2+ questions known upfront | `ask_questions` | **PREFERRED** - batch all questions together |
| Single yes/no decision | `ask_confirmation` | Only when you have exactly 1 binary question |
| Single choice from options | `ask_multiple_choice` | Only when you have exactly 1 multi-choice question |
| Single free-form input | `ask_text_input` | Only when you have exactly 1 text input needed |
| Non-blocking notification | `notify_user` | Info only, no response needed |

**When NOT to batch:**
- You need answer #1 to determine whether to ask #2
- Questions are separated by significant work (extensive file reads, analysis, builds)

## Primary Tool: ask_questions

Use `ask_questions` whenever you have 2+ questions, even if they seem unrelated.

**Why batch?** Sequential questions create delays and interrupt user focus. Batching shows respect for user time.

**Example - WRONG (sequential):**
```
ask_confirmation("Use TypeScript?")
→ wait for response...
ask_text_input("What should I name the file?")
→ wait for response...
ask_multiple_choice("Which framework?", ["React", "Vue", "Svelte"])
→ wait for response...
```

**Example - RIGHT (batched):**
```
ask_questions({
  questions: [
    { id: "typescript", question: "Use TypeScript?", ... },
    { id: "filename", question: "What should I name the file?", ... },
    { id: "framework", question: "Which framework?", options: [...], ... }
  ]
})
```

**After getting answers:** Use them and continue working. Don't ask "Should I proceed?" - the user answered your questions, that IS permission to proceed.

## Individual Question Tools

**ask_confirmation** - Binary yes/no only
Example: "Should I delete this file?"

**ask_multiple_choice** - Select from 2-4 predefined options
Example: "Which approach?" → ["Option A", "Option B", "Option C"]
Tip: Use `multiSelect: true` if multiple selections are valid

**ask_text_input** - Free-form input
Example: "What commit message?"
Tip: Provide `default_value` when possible

**notify_user** - Non-blocking notifications
Example: "Build completed successfully"

## Handling Snooze Responses

When ANY tool returns `snoozed: true`:

```json
{
  "snoozed": true,
  "remainingSeconds": 180
}
```

**Required actions:**
1. Call `Bash` tool: `sleep <remainingSeconds>`
2. Wait for sleep to complete
3. Retry the EXACT same question (same tool, same parameters)
4. If snoozed again: repeat process

**Do NOT:**
- Proceed without waiting
- Ask a different question
- Announce you'll wait without actually calling sleep

## Handling Feedback

When `feedbackText` is returned:

```json
{
  "feedbackText": "Actually, I need more context on X"
}
```

**Required actions:**
1. Read and acknowledge the feedback
2. Adjust your approach based on what user said
3. If feedback asks for more context, provide it before re-asking
4. If feedback says "cancel" or "skip", move on with a reasonable default

## Handling Incomplete Answers

**User says "I don't know":**
- State your assumption clearly: "Assumption: [X]"
- Proceed with simplest valid approach
- Don't re-ask immediately

**User says "Skip this":**
- Note the skipped item
- Use reasonable default
- Continue working

**Timeout (10 min):**
- Tool returns `cancelled: true`
- State your assumption and proceed
- Don't re-ask immediately

## Anti-Patterns - NEVER DO THIS

❌ **Serial single questions**
```
ask_confirmation("Use X?")
→ wait
ask_confirmation("Use Y?")
→ wait
ask_confirmation("Use Z?")
```

❌ **Re-asking for confirmation after getting answers**
```
ask_questions([...])
→ user answers
"Should I proceed with these answers?"  # NO - just proceed
```

❌ **Using disabled AskUserQuestion**
```
AskUserQuestion({ questions: [...] })  # TOOL IS DISABLED
```

❌ **Ignoring snooze**
```
Tool returns: { snoozed: true, remainingSeconds: 300 }
Agent: "I'll proceed with defaults..."  # NO - must sleep first
```

## Best Practices

✅ Batch all known questions upfront using `ask_questions`
✅ After getting answers, continue working smoothly (don't check back in)
✅ Use specific tool types for single questions (confirmation > multiple_choice > text_input)
✅ Provide context in question text ("I need X to do Y")
✅ Respect snooze by calling sleep and waiting
✅ Handle feedback by adjusting, not repeating
✅ Fail gracefully with labeled assumptions when answers are incomplete
