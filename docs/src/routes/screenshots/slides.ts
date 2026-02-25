export interface Slide {
	template:
		| 'confirmation'
		| 'multiple-choice'
		| 'wizard'
		| 'wizard-text'
		| 'wizard-multi'
		| 'text-input'
		| 'snooze'
		| 'feedback';
	toolName: string;
	headline?: string;
	caption?: string;
	text?: string;
	question?: string;
	choices?: { label: string; selected?: boolean }[];
	inputText?: string;
	inputPlaceholder?: string;
	inputHidden?: boolean;
	step?: number;
	totalSteps?: number;
	selectedDuration?: string;
	feedbackText?: string;
}

// Set A: "The Agent Gone Rogue" — dev absurdism → features
const setA: Record<string, Slide> = {
	'a-01': {
		template: 'confirmation',
		toolName: 'ask type=confirm',
		headline: 'Introducing Consult User MCP',
		text: 'Rename all variables to emoji for readability?',
	},
	'a-02': {
		template: 'multiple-choice',
		toolName: 'ask type=pick',
		question: 'How would you like to refer to Consult User MCP?',
		choices: [
			{ label: 'CUMCP' },
			{ label: 'Consult User MCP is fine', selected: true },
		],
	},
	'a-03': {
		template: 'multiple-choice',
		toolName: 'ask type=pick',
		question: 'How should your AI agent ask you things?',
		choices: [
			{ label: 'Wall of text in terminal' },
			{ label: 'Native macOS dialog', selected: true },
			{ label: 'Telepathy (coming soon)' },
		],
	},
	'a-04': {
		template: 'confirmation',
		toolName: 'ask type=confirm',
		text: 'Deploy to production on a Friday at 4:59 PM?',
	},
	'a-05': {
		template: 'text-input',
		toolName: 'ask type=text',
		text: 'What should the agent call this service?',
		inputText: 'todo-app-but-enterprise-grade',
	},
	'a-06': {
		template: 'wizard',
		toolName: 'ask type=form',
		step: 1,
		totalSteps: 3,
		question: "What's your preferred error handling?",
		choices: [
			{ label: 'try/catch everything' },
			{ label: 'Let it crash' },
			{ label: 'console.log("here")', selected: true },
		],
	},
	'a-07': {
		template: 'snooze',
		toolName: 'ask type=confirm',
		text: 'Run the full test suite before merging?',
		selectedDuration: '15m',
	},
	'a-08': {
		template: 'feedback',
		toolName: 'ask type=confirm',
		text: 'Rewrite the entire codebase in Rust?',
		feedbackText: 'just the hot path please',
	},
	'a-09': {
		template: 'text-input',
		toolName: 'ask type=text',
		text: 'What should the error message say?',
		inputText: 'Session expired. Please log in again.',
	},
	'a-10': {
		template: 'confirmation',
		toolName: 'ask type=confirm',
		text: 'Was this dialog better than a wall of terminal text?',
	},
};

// Set B: "The Decision Maker" — meta humor → real decisions
const setB: Record<string, Slide> = {
	'b-01': {
		template: 'confirmation',
		toolName: 'ask type=confirm',
		headline: 'Introducing Consult User MCP',
		text: 'Add 47 npm packages for a date picker?',
	},
	'b-02': {
		template: 'multiple-choice',
		toolName: 'ask type=pick',
		question: 'The AI agent is "pretty confident". Trust it?',
		choices: [
			{ label: 'Always' },
			{ label: 'Only on Tuesdays' },
			{ label: 'Let me see the diff', selected: true },
			{ label: "It's sentient now, just obey" },
		],
	},
	'b-03': {
		template: 'text-input',
		toolName: 'ask type=text',
		text: 'What should the commit message say?',
		inputText: 'fix: stuff',
	},
	'b-04': {
		template: 'confirmation',
		toolName: 'ask type=confirm',
		text: 'Mass-replace all semicolons with Greek question marks?',
	},
	'b-05': {
		template: 'multiple-choice',
		toolName: 'ask type=pick',
		question: "It's 3 AM. The CI is red. What do you do?",
		choices: [
			{ label: 'Fix it now' },
			{ label: 'Revert and pretend it never happened', selected: true },
			{ label: 'Close laptop slowly' },
		],
	},
	'b-06': {
		template: 'wizard',
		toolName: 'ask type=form',
		step: 2,
		totalSteps: 3,
		question: 'Where should sessions be stored?',
		choices: [
			{ label: 'In-memory' },
			{ label: 'Redis', selected: true },
			{ label: 'Database' },
		],
	},
	'b-07': {
		template: 'snooze',
		toolName: 'ask type=confirm',
		text: 'Deploy the database migration now?',
		selectedDuration: '30m',
	},
	'b-08': {
		template: 'feedback',
		toolName: 'ask type=confirm',
		text: 'Split this 2000-line file into modules?',
		feedbackText: 'start with the utils',
	},
	'b-09': {
		template: 'text-input',
		toolName: 'ask type=text',
		text: 'Describe the breaking change:',
		inputText: 'Removed deprecated v1 endpoints',
	},
	'b-10': {
		template: 'confirmation',
		toolName: 'ask type=confirm',
		text: 'Tag this as v2.0.0 and push to main?',
	},
};

// Set C: "Real World" — practical dev scenarios throughout
const setC: Record<string, Slide> = {
	'c-01': {
		template: 'confirmation',
		toolName: 'ask type=confirm',
		headline: 'Introducing Consult User MCP',
		text: 'Create a new Git branch for this feature?',
	},
	'c-02': {
		template: 'multiple-choice',
		toolName: 'ask type=pick',
		question: 'Which auth strategy for the new API?',
		choices: [
			{ label: 'JWT tokens' },
			{ label: 'OAuth 2.0', selected: true },
			{ label: 'API keys' },
			{ label: 'Session cookies' },
		],
	},
	'c-03': {
		template: 'wizard',
		toolName: 'ask type=form',
		step: 1,
		totalSteps: 3,
		question: 'Configure the deployment target:',
		choices: [
			{ label: 'Development' },
			{ label: 'Staging' },
			{ label: 'Production', selected: true },
		],
	},
	'c-04': {
		template: 'text-input',
		toolName: 'ask type=text',
		text: 'What should the PR title say?',
		inputText: 'feat: add user authentication flow',
	},
	'c-05': {
		template: 'multiple-choice',
		toolName: 'ask type=pick',
		question: 'Found 3 failing tests. How to proceed?',
		choices: [
			{ label: 'Fix and retry' },
			{ label: 'Skip for now' },
			{ label: 'Show me the failures', selected: true },
		],
	},
	'c-06': {
		template: 'confirmation',
		toolName: 'ask type=confirm',
		text: 'Install 12 missing peer dependencies?',
	},
	'c-07': {
		template: 'snooze',
		toolName: 'ask type=confirm',
		text: 'Run the linter before committing?',
		selectedDuration: '5m',
	},
	'c-08': {
		template: 'feedback',
		toolName: 'ask type=confirm',
		text: 'Refactor the auth module into separate files?',
		feedbackText: 'keep it in one file for now',
	},
	'c-09': {
		template: 'wizard',
		toolName: 'ask type=form',
		step: 3,
		totalSteps: 3,
		question: 'Choose the test runner:',
		choices: [
			{ label: 'Vitest', selected: true },
			{ label: 'Jest' },
			{ label: 'Playwright' },
		],
	},
	'c-10': {
		template: 'text-input',
		toolName: 'ask type=text',
		text: 'Name the new database table:',
		inputText: 'user_sessions',
	},
};

// Set D: "The Interviewer" — agent interviews you through a batch of decisions
const setD: Record<string, Slide> = {
	'd-01': {
		template: 'confirmation',
		toolName: 'ask type=confirm',
		headline: 'Introducing Consult User MCP',
		text: 'Help me triage these 20 backlog tickets?',
	},
	'd-02': {
		template: 'wizard',
		toolName: 'ask type=form',
		step: 1,
		totalSteps: 4,
		question: 'Ticket #4: User auth timeout — Priority?',
		choices: [
			{ label: 'High', selected: true },
			{ label: 'Medium' },
			{ label: 'Low' },
			{ label: 'Skip' },
		],
	},
	'd-03': {
		template: 'wizard',
		toolName: 'ask type=form',
		step: 2,
		totalSteps: 4,
		question: 'Ticket #4: Assign to?',
		choices: [
			{ label: 'Backend team', selected: true },
			{ label: 'Frontend team' },
			{ label: 'DevOps' },
			{ label: 'Unassigned' },
		],
	},
	'd-04': {
		template: 'multiple-choice',
		toolName: 'ask type=pick',
		question: 'Ticket #7: Stale cache on deploy — Is this blocking the release?',
		choices: [
			{ label: 'Yes' },
			{ label: 'No', selected: true },
			{ label: 'Need more info' },
		],
	},
	'd-05': {
		template: 'wizard',
		toolName: 'ask type=form',
		step: 1,
		totalSteps: 4,
		question: "New project setup (1/4): What's the stack?",
		choices: [
			{ label: 'Next.js' },
			{ label: 'SvelteKit', selected: true },
			{ label: 'Astro' },
			{ label: 'Other' },
		],
	},
	'd-06': {
		template: 'wizard',
		toolName: 'ask type=form',
		step: 2,
		totalSteps: 4,
		question: 'New project setup (2/4): Auth provider?',
		choices: [
			{ label: 'Clerk' },
			{ label: 'Auth.js', selected: true },
			{ label: 'Custom' },
			{ label: 'None for now' },
		],
	},
	'd-07': {
		template: 'wizard',
		toolName: 'ask type=form',
		step: 3,
		totalSteps: 4,
		question: 'New project setup (3/4): Database?',
		choices: [
			{ label: 'Postgres', selected: true },
			{ label: 'SQLite' },
			{ label: 'Turso' },
			{ label: "I'll decide later" },
		],
	},
	'd-08': {
		template: 'wizard',
		toolName: 'ask type=form',
		step: 4,
		totalSteps: 4,
		question: 'New project setup (4/4): Deploy target?',
		choices: [
			{ label: 'Vercel' },
			{ label: 'Fly.io', selected: true },
			{ label: 'Self-hosted' },
			{ label: 'Not sure yet' },
		],
	},
	'd-09': {
		template: 'multiple-choice',
		toolName: 'ask type=pick',
		question: 'Design review: Which layout direction?',
		choices: [
			{ label: 'Sidebar nav', selected: true },
			{ label: 'Top nav' },
			{ label: 'Tabs' },
			{ label: 'Show me both' },
		],
	},
	'd-10': {
		template: 'confirmation',
		toolName: 'ask type=confirm',
		text: 'All 20 tickets triaged. Apply changes to backlog?',
	},
};

// Set E: "Mixed Wizard" — one wizard, mixed question types (v1.17 feature)
const setE: Record<string, Slide> = {
	'e-01': {
		template: 'wizard',
		toolName: 'ask type=form',
		step: 1,
		totalSteps: 6,
		question: 'What programming language?',
		choices: [
			{ label: 'TypeScript', selected: true },
			{ label: 'Python' },
			{ label: 'Go' },
		],
	},
	'e-02': {
		template: 'wizard-text',
		toolName: 'ask type=form',
		step: 2,
		totalSteps: 6,
		question: 'What should we call the project?',
		inputText: 'my-awesome-api',
	},
	'e-03': {
		template: 'wizard-multi',
		toolName: 'ask type=form',
		step: 3,
		totalSteps: 6,
		question: 'Which features to include?',
		choices: [
			{ label: 'Authentication', selected: true },
			{ label: 'API Routes', selected: true },
			{ label: 'Database' },
			{ label: 'Testing' },
		],
	},
	'e-04': {
		template: 'wizard',
		toolName: 'ask type=form',
		step: 4,
		totalSteps: 6,
		question: 'Select the deploy target:',
		choices: [
			{ label: 'Vercel' },
			{ label: 'Fly.io', selected: true },
			{ label: 'Self-hosted' },
		],
	},
	'e-05': {
		template: 'wizard-text',
		toolName: 'ask type=form',
		step: 5,
		totalSteps: 6,
		question: 'Enter your API key (optional):',
		inputText: '••••••••••••••••',
		inputHidden: true,
	},
	'e-06': {
		template: 'wizard-text',
		toolName: 'ask type=form',
		step: 6,
		totalSteps: 6,
		question: 'Describe the project in one line:',
		inputText: 'REST API for task management',
	},
};

export const slides: Record<string, Slide> = { ...setA, ...setB, ...setC, ...setD, ...setE };
export const slideIds = Object.keys(slides);
export const sets = {
	a: Object.keys(setA),
	b: Object.keys(setB),
	c: Object.keys(setC),
	d: Object.keys(setD),
	e: Object.keys(setE),
};
