using System.Diagnostics;
using System.IO;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace ConsultUserMCP.Services;

public static class MCPInstaller
{
    private static readonly string ConfigPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "Claude", "claude_desktop_config.json");

    public static void Configure()
    {
        try
        {
            var nodePath = FindNodePath();
            var serverPath = FindMCPServerPath();
            if (nodePath is null || serverPath is null) return;

            JsonObject config;
            if (File.Exists(ConfigPath))
            {
                var existing = File.ReadAllText(ConfigPath);
                config = JsonNode.Parse(existing)?.AsObject() ?? new JsonObject();
            }
            else
            {
                Directory.CreateDirectory(Path.GetDirectoryName(ConfigPath)!);
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
            File.WriteAllText(ConfigPath, config.ToJsonString(options));
        }
        catch
        {
            // Best-effort: don't crash on first run if config can't be written
        }
    }

    public static bool IsConfigured()
    {
        if (!File.Exists(ConfigPath)) return false;
        try
        {
            var json = File.ReadAllText(ConfigPath);
            var config = JsonNode.Parse(json)?.AsObject();
            return config?["mcpServers"]?.AsObject()?.ContainsKey("consult-user-mcp") == true;
        }
        catch
        {
            return false;
        }
    }

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
        // Check PATH via where command
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

        // Fallback to common install location
        var fallback = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
            "nodejs", "node.exe");
        if (File.Exists(fallback)) return fallback;

        return null;
    }
}
