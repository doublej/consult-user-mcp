import type { VercelRequest, VercelResponse } from '@vercel/node';

// Returns the MCP tool definitions for remote MCP clients
// This follows the MCP tool schema format

const tools = [
  {
    name: 'ask_confirmation',
    description: 'Ask the user a yes/no confirmation question. Returns true for yes, false for no.',
    inputSchema: {
      type: 'object',
      properties: {
        sessionId: {
          type: 'string',
          description: 'The session ID for the PWA instance',
        },
        title: {
          type: 'string',
          description: 'The title of the dialog',
        },
        message: {
          type: 'string',
          description: 'The question to ask the user',
        },
        yesText: {
          type: 'string',
          description: 'Custom text for the yes button (default: "Yes")',
        },
        noText: {
          type: 'string',
          description: 'Custom text for the no button (default: "No")',
        },
      },
      required: ['sessionId', 'message'],
    },
  },
  {
    name: 'ask_choice',
    description: 'Ask the user to choose from a list of options. Can be single or multiple selection.',
    inputSchema: {
      type: 'object',
      properties: {
        sessionId: {
          type: 'string',
          description: 'The session ID for the PWA instance',
        },
        title: {
          type: 'string',
          description: 'The title of the dialog',
        },
        message: {
          type: 'string',
          description: 'Instructions for the user',
        },
        choices: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              label: { type: 'string', description: 'Display label for the choice' },
              value: { type: 'string', description: 'Value to return when selected' },
              description: { type: 'string', description: 'Optional description' },
            },
            required: ['label', 'value'],
          },
          description: 'The choices to present to the user',
        },
        multiple: {
          type: 'boolean',
          description: 'Allow multiple selections (default: false)',
        },
      },
      required: ['sessionId', 'choices'],
    },
  },
  {
    name: 'ask_text',
    description: 'Ask the user to enter text input. Can be regular or hidden (password-style) input.',
    inputSchema: {
      type: 'object',
      properties: {
        sessionId: {
          type: 'string',
          description: 'The session ID for the PWA instance',
        },
        title: {
          type: 'string',
          description: 'The title of the dialog',
        },
        message: {
          type: 'string',
          description: 'Instructions or prompt for the user',
        },
        placeholder: {
          type: 'string',
          description: 'Placeholder text for the input field',
        },
        hidden: {
          type: 'boolean',
          description: 'Hide the input (password style)',
        },
      },
      required: ['sessionId'],
    },
  },
  {
    name: 'notify_user',
    description: 'Send a notification to the user without requiring a response.',
    inputSchema: {
      type: 'object',
      properties: {
        sessionId: {
          type: 'string',
          description: 'The session ID for the PWA instance',
        },
        title: {
          type: 'string',
          description: 'The notification title',
        },
        message: {
          type: 'string',
          description: 'The notification message',
        },
      },
      required: ['sessionId', 'message'],
    },
  },
];

export default function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  return res.status(200).json({ tools });
}
