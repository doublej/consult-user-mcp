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
        var path = Path.Combine(dir, "dialog-cli-windows.exe");
        if (File.Exists(path)) return path;

        // Dev layout: sibling project build output
        var parent = Directory.GetParent(dir)?.FullName;
        if (parent is null) return null;

        path = Path.Combine(parent, "dialog-cli-windows", "bin", "Debug", "net8.0-windows", "dialog-cli-windows.exe");
        return File.Exists(path) ? path : null;
    }

    private static string EscapeArg(string arg)
        => "\"" + arg.Replace("\"", "\\\"") + "\"";
}
