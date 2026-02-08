namespace DialogCLI.Models;

public enum QuestionType
{
    Choice,
    Text,
}

public record QuestionOption(
    string Label,
    string? Description
);

public record QuestionItem(
    string Id,
    string Question,
    QuestionType Type = QuestionType.Choice,
    QuestionOption[]? Options = null,
    bool MultiSelect = false,
    string? Placeholder = null
)
{
    // Ensure Options is never null for choice-type questions
    public QuestionOption[] Options { get; init; } = Options ?? [];
};

public record QuestionsRequest(
    QuestionItem[] Questions,
    string Mode,
    DialogPosition Position
);

public class QuestionsResponse
{
    public string DialogType { get; set; } = "questions";
    public Dictionary<string, StringOrStrings> Answers { get; set; } = new();
    public bool Cancelled { get; set; }
    public bool Dismissed { get; set; }
    public int CompletedCount { get; set; }
    public bool? Snoozed { get; set; }
    public int? SnoozeMinutes { get; set; }
    public int? RemainingSeconds { get; set; }
    public string? FeedbackText { get; set; }
    public string? Instruction { get; set; }
}
