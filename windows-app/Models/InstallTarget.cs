namespace ConsultUserMCP.Models;

public enum InstallTarget
{
    ClaudeDesktop,
    ClaudeCode,
    Codex,
}

public enum ConfigFormat
{
    Json,
    Toml,
}

public enum BasePromptInstallMode
{
    CreateNew,
    AppendSection,
    Update,
    Skip,
}

public static class InstallTargetExtensions
{
    public static string DisplayName(this InstallTarget target) => target switch
    {
        InstallTarget.ClaudeDesktop => "Claude",
        InstallTarget.ClaudeCode => "Claude Code",
        InstallTarget.Codex => "Codex",
        _ => target.ToString(),
    };

    public static string Description(this InstallTarget target) => target switch
    {
        InstallTarget.ClaudeDesktop => "Anthropic's desktop app",
        InstallTarget.ClaudeCode => "CLI coding assistant",
        InstallTarget.Codex => "OpenAI's CLI tool",
        _ => "",
    };

    public static string ConfigPath(this InstallTarget target) => target switch
    {
        InstallTarget.ClaudeDesktop => Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "Claude", "claude_desktop_config.json"),
        InstallTarget.ClaudeCode => Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
            ".claude.json"),
        InstallTarget.Codex => Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
            ".codex", "config.toml"),
        _ => "",
    };

    public static ConfigFormat ConfigFormat(this InstallTarget target) => target switch
    {
        InstallTarget.Codex => Models.ConfigFormat.Toml,
        _ => Models.ConfigFormat.Json,
    };

    public static string? BasePromptPath(this InstallTarget target) => target switch
    {
        InstallTarget.ClaudeCode => Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
            ".claude", "CLAUDE.md"),
        InstallTarget.Codex => Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
            ".codex", "AGENTS.md"),
        _ => null,
    };

    public static bool SupportsBasePrompt(this InstallTarget target) =>
        target.BasePromptPath() is not null;

    public static string? BasePromptFileName(this InstallTarget target) =>
        target.BasePromptPath() is string p ? Path.GetFileName(p) : null;

    public static string DisplayConfigPath(this InstallTarget target) => target switch
    {
        InstallTarget.ClaudeDesktop => @"%APPDATA%\Claude\claude_desktop_config.json",
        InstallTarget.ClaudeCode => @"%USERPROFILE%\.claude.json",
        InstallTarget.Codex => @"%USERPROFILE%\.codex\config.toml",
        _ => "",
    };

    public static string? DisplayBasePromptPath(this InstallTarget target) => target switch
    {
        InstallTarget.ClaudeCode => @"%USERPROFILE%\.claude\CLAUDE.md",
        InstallTarget.Codex => @"%USERPROFILE%\.codex\AGENTS.md",
        _ => null,
    };
}
