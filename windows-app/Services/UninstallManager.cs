using System.IO;
using ConsultUserMCP.Models;

namespace ConsultUserMCP.Services;

public record RemovalItem(string Icon, string Title, string Detail);

public static class UninstallManager
{
    public static List<RemovalItem> GetRemovalList(bool keepData)
    {
        var items = new List<RemovalItem>();

        foreach (var target in Enum.GetValues<InstallTarget>())
        {
            if (MCPInstaller.IsConfigured(target))
            {
                items.Add(new RemovalItem(
                    "config",
                    $"MCP config: {target.DisplayName()}",
                    target.DisplayConfigPath()));
            }

            if (target.SupportsBasePrompt() && BasePromptInstaller.DetectInstalledInfo(target) is not null)
            {
                items.Add(new RemovalItem(
                    "prompt",
                    $"Base prompt: {target.DisplayName()}",
                    target.DisplayBasePromptPath() ?? ""));
            }
        }

        if (StartupManager.IsEnabled())
        {
            items.Add(new RemovalItem(
                "startup",
                "Startup registry entry",
                @"HKCU\Software\Microsoft\Windows\CurrentVersion\Run"));
        }

        items.Add(new RemovalItem(
            "app",
            "Application",
            "Consult User MCP"));

        if (!keepData)
        {
            items.Add(new RemovalItem(
                "data",
                "Settings and history",
                @"%APPDATA%\ConsultUserMCP"));

            var projectsFile = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
                ".config", "consult-user-mcp", "projects.json");
            if (File.Exists(projectsFile))
            {
                items.Add(new RemovalItem(
                    "projects",
                    "Projects file",
                    @"%USERPROFILE%\.config\consult-user-mcp\projects.json"));
            }
        }

        return items;
    }

    public static void RunFastCleanup(bool keepData = false)
    {
        try { StartupManager.SetEnabled(false); } catch { }

        foreach (var target in Enum.GetValues<InstallTarget>())
        {
            try { MCPInstaller.UnconfigureTarget(target); } catch { }
            if (!target.SupportsBasePrompt()) continue;
            try { BasePromptInstaller.Uninstall(target); } catch { }
        }

        if (!keepData)
        {
            try { RemoveFile(SettingsManager.GetSettingsPath()); } catch { }
            try { RemoveFile(SettingsManager.GetSnoozeStatePath()); } catch { }
            try { RemoveDirectoryIfEmpty(SettingsManager.GetAppDataDir()); } catch { }

            var projectsFile = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
                ".config", "consult-user-mcp", "projects.json");
            try { RemoveFile(projectsFile); } catch { }
            try { RemoveDirectoryIfEmpty(Path.GetDirectoryName(projectsFile)); } catch { }
        }
    }

    private static void RemoveFile(string path)
    {
        if (File.Exists(path))
            File.Delete(path);
    }

    private static void RemoveDirectoryIfEmpty(string? path)
    {
        if (string.IsNullOrWhiteSpace(path) || !Directory.Exists(path))
            return;

        if (Directory.EnumerateFileSystemEntries(path).Any())
            return;

        Directory.Delete(path);
    }
}
