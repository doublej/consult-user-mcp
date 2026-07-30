/**
 * How long the server waits for a dialog answer before giving up and letting
 * the agent continue. The providers pass this to the Dialog CLI via the
 * MCP_DIALOG_TIMEOUT_MS env var so the dialog can flip into its expired
 * state ("the agent has moved on") at the same moment.
 */
export const DIALOG_TIMEOUT_MS = 10 * 60 * 1000; // 10 minutes
