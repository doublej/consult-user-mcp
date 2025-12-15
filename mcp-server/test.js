#!/usr/bin/env node

/**
 * Test script to preview all dialog types.
 * Run with: node test.js
 */

import { exec } from "child_process";
import { promisify } from "util";

const execAsync = promisify(exec);

function escapeAppleScript(str) {
  return str.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, "\" & return & \"");
}

async function runOsascript(script) {
  try {
    const { stdout } = await execAsync(`osascript -e '${script.replace(/'/g, "'\\''")}'`);
    return stdout.trim();
  } catch (error) {
    if (error.stderr?.includes("User canceled") || error.stderr?.includes("-128")) {
      return "__CANCELLED__";
    }
    throw error;
  }
}

async function getComment() {
  const script = `display dialog "Enter your comment:" with title "Add Comment" default answer "" buttons {"Cancel", "OK"} default button "OK"`;
  const result = await runOsascript(script);

  if (result === "__CANCELLED__" || result.includes("button returned:Cancel")) {
    return null;
  }

  const textMatch = result.match(/text returned:(.*)/);
  return textMatch ? textMatch[1].trim() || null : null;
}

async function testConfirmation() {
  console.log("\n1. Testing: ask_confirmation");
  console.log("   Showing Yes/No list with multi-select (Cmd+click for comment)...\n");

  const choices = ["Yes", "No", "+ Add a comment"];
  const choiceList = choices.map(c => `"${c}"`).join(", ");
  const script = `choose from list {${choiceList}} with prompt "Do you want to proceed with this action?" with title "Confirmation Test" with multiple selections allowed default items {"Yes"}`;

  const result = await runOsascript(script);

  if (result === "__CANCELLED__" || result === "false") {
    console.log("   Result: User cancelled");
    return;
  }

  const selections = result.split(", ");
  const hasComment = selections.includes("+ Add a comment");
  const confirmed = selections.includes("Yes");
  const declined = selections.includes("No");

  let comment = null;
  if (hasComment) {
    comment = await getComment();
    console.log(`   Comment: "${comment || "(none)"}"`);
  }

  if (confirmed) {
    console.log(`   Result: User selected "Yes"${comment ? " (with comment)" : ""}`);
  } else if (declined) {
    console.log(`   Result: User selected "No"${comment ? " (with comment)" : ""}`);
  } else {
    console.log("   Result: User only selected comment option (no choice made)");
  }
}

async function testMultipleChoice() {
  console.log("\n2. Testing: ask_multiple_choice");
  console.log("   Showing list picker with multi-select (Cmd+click for comment)...\n");

  const choices = ["PDF", "Word Document", "Markdown", "Plain Text", "+ Add a comment"];
  const choiceList = choices.map(c => `"${c}"`).join(", ");

  const result = await runOsascript(`choose from list {${choiceList}} with prompt "Which format would you like?" with multiple selections allowed default items {"PDF"}`);

  if (result === "__CANCELLED__" || result === "false") {
    console.log("   Result: User cancelled");
    return;
  }

  const selections = result.split(", ");
  const hasComment = selections.includes("+ Add a comment");
  const actualSelections = selections.filter(s => s !== "+ Add a comment");

  let comment = null;
  if (hasComment) {
    comment = await getComment();
    console.log(`   Comment: "${comment || "(none)"}"`);
  }

  if (actualSelections.length > 0) {
    console.log(`   Result: User selected "${actualSelections.join(", ")}"${comment ? " (with comment)" : ""}`);
  } else {
    console.log("   Result: User only selected comment option (no choice made)");
  }
}

async function testMultipleChoiceMulti() {
  console.log("\n3. Testing: ask_multiple_choice (multi-select)");
  console.log("   Showing list picker with multiple selection (Cmd+click)...\n");

  const choices = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "+ Add a comment"];
  const choiceList = choices.map(c => `"${c}"`).join(", ");

  const result = await runOsascript(`choose from list {${choiceList}} with prompt "Which days work for you?" with multiple selections allowed`);

  if (result === "__CANCELLED__" || result === "false") {
    console.log("   Result: User cancelled");
    return;
  }

  const selections = result.split(", ");
  const hasComment = selections.includes("+ Add a comment");
  const actualSelections = selections.filter(s => s !== "+ Add a comment");

  let comment = null;
  if (hasComment) {
    comment = await getComment();
    console.log(`   Comment: "${comment || "(none)"}"`);
  }

  if (actualSelections.length > 0) {
    console.log(`   Result: User selected "${actualSelections.join(", ")}"${comment ? " (with comment)" : ""}`);
  } else {
    console.log("   Result: User only selected comment option (no choice made)");
  }
}

async function testTextInput() {
  console.log("\n4. Testing: ask_text_input");
  console.log("   Showing text input dialog with + Comment option...\n");

  // Three buttons: Cancel, + Comment, OK
  const script = `display dialog "What should I name this file?" with title "File Name" default answer "untitled" buttons {"Cancel", "+ Comment", "OK"} default button "OK"`;
  const result = await runOsascript(script);

  if (result === "__CANCELLED__" || result.includes("button returned:Cancel")) {
    console.log("   Result: User cancelled");
    return;
  }

  const textMatch = result.match(/text returned:(.*)/);
  const text = textMatch ? textMatch[1] : "";

  if (result.includes("button returned:+ Comment")) {
    const comment = await getComment();
    console.log(`   Comment: "${comment || "(none)"}"`);
    console.log(`   Result: User entered "${text}" (with comment)`);
  } else {
    console.log(`   Result: User entered "${text}"`);
  }
}

async function testNotification() {
  console.log("\n5. Testing: notify_user");
  console.log("   Showing macOS notification...\n");

  const script = `display notification "This is a test notification from the MCP server." with title "Consult User MCP" subtitle "Test Complete" sound name "default"`;
  await runOsascript(script);

  console.log("   Result: Notification sent (check top-right of screen)");
}

async function testSpeak() {
  console.log("\n6. Testing: speak_text");
  console.log("   Speaking text aloud...\n");

  await execAsync(`say -r 200 "Hello! This is the consult user MCP server. I can talk to you."`);

  console.log("   Result: Speech complete");
}

async function main() {
  console.log("=".repeat(50));
  console.log("  Consult User MCP Server - UI Test");
  console.log("=".repeat(50));
  console.log("\nThis will show each dialog type. Interact with each one.\n");

  try {
    await testConfirmation();
    await testMultipleChoice();
    await testMultipleChoiceMulti();
    await testTextInput();
    await testNotification();
    await testSpeak();

    console.log("\n" + "=".repeat(50));
    console.log("  All tests complete!");
    console.log("=".repeat(50) + "\n");
  } catch (error) {
    console.error("\nError:", error.message);
    process.exit(1);
  }
}

main();
