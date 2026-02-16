using System.Diagnostics;
using System.IO;
using System.Text.Json;
using System.Text.Json.Nodes;
using ConsultUserMCP.Models;

namespace ConsultUserMCP.Services;

public static class MCPInstaller
{
    /// <summary>First-run auto-install for Claude Desktop (backward compat).</summary>
    public static void Configure()
    {
        try { ConfigureTarget(InstallTarget.ClaudeDesktop); }
        catch { /* Best-effort: don't crash on first run */ }
    }

    public static bool ConfigureTarget(InstallTarget target)
    {
        var nodePath = FindNodePath();
        var serverPath = FindMCPServerPath();
        if (nodePath is null || serverPath is null) return false;

        return target.ConfigFormat() == ConfigFormat.Toml
            ? ConfigureToml(target.ConfigPath(), nodePath, serverPath)
            : ConfigureJson(target.ConfigPath(), nodePath, serverPath);
    }

    public static bool IsConfigured(InstallTarget target)
    {
        var path = target.ConfigPath();
        if (!File.Exists(path)) return false;

        try
        {
            var content = File.ReadAllText(path);
            return target.ConfigFormat() == ConfigFormat.Toml
                ? content.Contains("[mcp_servers.consult-user-mcp]")
                : HasJsonMcpEntry(content);
        }
        catch { return false; }
    }

    /// <summary>Legacy overload for existing callers.</summary>
    public static bool IsConfigured() => IsConfigured(InstallTarget.ClaudeDesktop);

    public static string? FindMCPServerPath()
    {
        var appDir = AppDomain.CurrentDomain.BaseDirectory;

        // Installed: mcp-server alongside app
        var installedPath = Path.Combine(appDir, "mcp-server", "dist", "index.js");
        if (File.Exists(installedPath)) return installedPath;

        // Dev: navigate up to repo root
        var current = appDir;
        for (var i = 0; i < 6; i++)
        {
            var parent = Directory.GetParent(current)?.FullName;
            if (parent is null) break;
            current = parent;

            var devPath = Path.Combine(current, "mcp-server", "dist", "index.js");
            if (File.Exists(devPath)) return devPath;
        }

        return null;
    }

    public static string? FindNodePath()
    {
        try
        {
            var psi = new ProcessStartInfo
            {
                FileName = "where",
                Arguments = "node",
                UseShellExecute = false,
                RedirectStandardOutput = true,
                CreateNoWindow = true,
            };
            var process = Process.Start(psi);
            if (process is not null)
            {
                var output = process.StandardOutput.ReadLine();
                process.WaitForExit(3000);
                if (!string.IsNullOrEmpty(output) && File.Exists(output))
                    return output;
            }
        }
        catch { }

        var fallback = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
            "nodejs", "node.exe");
        if (File.Exists(fallback)) return fallback;

        return null;
    }

    private static bool ConfigureJson(string path, string nodePath, string serverPath)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);

        JsonObject config;
        if (File.Exists(path))
        {
            var existing = File.ReadAllText(path);
            config = JsonNode.Parse(existing)?.AsObject() ?? new JsonObject();
        }
        else
        {
            config = new JsonObject();
        }

        var mcpServers = config["mcpServers"]?.AsObject() ?? new JsonObject();
        config["mcpServers"] = mcpServers;

        mcpServers["consult-user-mcp"] = new JsonObject
        {
            ["command"] = nodePath,
            ["args"] = new JsonArray(JsonValue.Create(serverPath)),
        };

        var options = new JsonSerializerOptions { WriteIndented = true };
        File.WriteAllText(path, config.ToJsonString(options));
        return true;
    }

    private static bool ConfigureToml(string path, string nodePath, string serverPath)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);

        var content = File.Exists(path) ? File.ReadAllText(path) : "";
        var escapedServer = serverPath.Replace(@"\", @"\\");

        var section = $"""
            [mcp_servers.consult-user-mcp]
            command = "{nodePath.Replace(@"\", @"\\")}"
            args = ["{escapedServer}"]
            """;

        if (content.Contains("[mcp_servers.consult-user-mcp]"))
        {
            // Replace existing section (up to next [section] or end)
            content = System.Text.RegularExpressions.Regex.Replace(
                content,
                @"\[mcp_servers\.consult-user-mcp\][^\[]*",
                section + "\n\n");
        }
        else
        {
            content = content.TrimEnd() + "\n\n" + section + "\n";
        }

        File.WriteAllText(path, content);
        return true;
    }

    private static bool HasJsonMcpEntry(string json)
    {
        var config = JsonNode.Parse(json)?.AsObject();
        return config?["mcpServers"]?.AsObject()?.ContainsKey("consult-user-mcp") == true;
    }
}
