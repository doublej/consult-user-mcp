using System.Diagnostics;
using System.IO;

namespace ConsultUserMCP.TrayIcon;

public static class DebugDialogRunner
{
    public static void Run(string command, string json)
    {
        var cliPath = FindDialogCli();
        if (cliPath is null) return;

        var startInfo = new ProcessStartInfo
        {
            FileName = cliPath,
            Arguments = $"{command} {EscapeArg(json)}",
            UseShellExecute = false,
            CreateNoWindow = true,
        };
        startInfo.EnvironmentVariables["MCP_CLIENT_NAME"] = "Debug";
        startInfo.EnvironmentVariables["MCP_PROJECT_PATH"] = @"C:\Users\debug\test-project";

        Process.Start(startInfo);
    }

    private static string? FindDialogCli()
    {
        var dir = AppDomain.CurrentDomain.BaseDirectory;
        // Installed: dialog-cli-windows.exe alongside tray app
        var path = Path.Combine(dir, "dialog-cli-windows.exe");
        if (File.Exists(path)) return path;

        // Dev layout: navigate from windows-tray-app/bin/Debug/net8.0-windows/win-x64/
        // up to repo root, then into dialog-cli-windows build output
        var current = dir;
        for (var i = 0; i < 6; i++)
        {
            var parent = Directory.GetParent(current)?.FullName;
            if (parent is null) break;
            current = parent;

            // Check for sibling dialog-cli-windows project
            var debugPath = Path.Combine(current, "dialog-cli-windows", "bin", "Debug", "net8.0-windows", "win-x64", "dialog-cli-windows.exe");
            if (File.Exists(debugPath)) return debugPath;

            var releasePath = Path.Combine(current, "dialog-cli-windows", "bin", "Release", "net8.0-windows", "win-x64", "publish", "dialog-cli-windows.exe");
            if (File.Exists(releasePath)) return releasePath;
        }

        return null;
    }

    private static string EscapeArg(string arg)
        => "\"" + arg.Replace("\"", "\\\"") + "\"";
}
