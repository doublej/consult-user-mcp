namespace ConsultUserMCP.Models;

public class InstallAnswers
{
    public InstallTarget Target { get; set; } = InstallTarget.ClaudeCode;
    public bool IncludeBasePrompt { get; set; } = true;
    public BasePromptInstallMode BasePromptMode { get; set; } = BasePromptInstallMode.CreateNew;
}

public class InstallResult
{
    public bool McpConfigSuccess { get; init; }
    public bool BasePromptSuccess { get; init; }
    public string? BasePromptError { get; init; }

    public bool IsFullySuccessful => McpConfigSuccess && BasePromptSuccess;
}

public class BasePromptInfo
{
    public required string Version { get; init; }
    public required string Content { get; init; }
}
