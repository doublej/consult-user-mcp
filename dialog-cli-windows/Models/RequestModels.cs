namespace DialogCLI.Models;

public enum DialogPosition
{
    Left,
    Center,
    Right,
}

public record ConfirmRequest(
    string Body,
    string Title,
    string ConfirmLabel,
    string CancelLabel,
    DialogPosition Position
);

public record ChooseRequest(
    string Body,
    string[] Choices,
    string[]? Descriptions,
    bool AllowMultiple,
    string? DefaultSelection,
    DialogPosition Position
);

public record TextInputRequest(
    string Body,
    string Title,
    string DefaultValue,
    bool Hidden,
    DialogPosition Position
);

public record NotifyRequest(
    string Body,
    string Title,
    bool Sound
);

public record QuestionOption(
    string Label,
    string? Description
);

public record QuestionItem(
    string Id,
    string Question,
    QuestionOption[] Options,
    bool MultiSelect
);

public record QuestionsRequest(
    QuestionItem[] Questions,
    string Mode,
    DialogPosition Position
);
