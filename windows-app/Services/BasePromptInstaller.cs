using System.IO;
using System.Reflection;
using System.Text.RegularExpressions;
using ConsultUserMCP.Models;

namespace ConsultUserMCP.Services;

public static class BasePromptInstaller
{
    private const string TagName = "consult-user-mcp-baseprompt";

    public static string BundledVersion
    {
        get
        {
            var content = BasePromptContent();
            if (content is null) return "1.0.0";

            var match = Regex.Match(content, @"<!--\s*version:\s*([0-9]+\.[0-9]+\.[0-9]+)\s*-->");
            return match.Success ? match.Groups[1].Value : "1.0.0";
        }
    }

    public static string? BasePromptContent()
    {
        var asm = Assembly.GetExecutingAssembly();
        using var stream = asm.GetManifestResourceStream("ConsultUserMCP.Resources.base-prompt.md");
        if (stream is null) return null;
        using var reader = new StreamReader(stream);
        return reader.ReadToEnd();
    }

    public static bool DetectExisting(InstallTarget target)
    {
        var path = target.BasePromptPath();
        return path is not null && File.Exists(path);
    }

    public static BasePromptInfo? DetectInstalledInfo(InstallTarget target)
    {
        var path = target.BasePromptPath();
        if (path is null || !File.Exists(path)) return null;

        var content = File.ReadAllText(path);

        // Try versioned XML tags
        var versionMatch = Regex.Match(content, $@"<{TagName} version=""([^""]+)"">");
        if (versionMatch.Success)
        {
            var version = versionMatch.Groups[1].Value;
            var contentMatch = Regex.Match(content,
                $@"<{TagName} version=""[^""]+"">(.+?)</{TagName}>",
                RegexOptions.Singleline);
            var inner = contentMatch.Success ? contentMatch.Groups[1].Value.Trim() : "";
            return new BasePromptInfo { Version = version, Content = inner };
        }

        // Legacy detection
        if (content.Contains("# Consult User MCP"))
            return new BasePromptInfo { Version = "0.0.0", Content = "" };

        return null;
    }

    public static bool IsUpdateAvailable(InstallTarget target)
    {
        var installed = DetectInstalledInfo(target);
        if (installed is null) return false;
        return CompareVersions(installed.Version, BundledVersion) < 0;
    }

    public static void Install(InstallTarget target, BasePromptInstallMode mode)
    {
        if (mode == BasePromptInstallMode.Skip) return;

        var path = target.BasePromptPath()
            ?? throw new InvalidOperationException("Target doesn't support base prompt");

        var wrapped = WrappedBasePromptContent()
            ?? throw new InvalidOperationException("Base prompt resource not found");

        var dir = Path.GetDirectoryName(path)!;
        Directory.CreateDirectory(dir);

        string finalContent;

        switch (mode)
        {
            case BasePromptInstallMode.CreateNew:
                finalContent = wrapped;
                break;

            case BasePromptInstallMode.AppendSection:
            {
                var existing = File.Exists(path) ? File.ReadAllText(path) : "";
                if (existing.Contains($"<{TagName}") || existing.Contains("# Consult User MCP"))
                    return; // already installed
                finalContent = string.IsNullOrEmpty(existing)
                    ? wrapped
                    : existing.TrimEnd() + "\n\n" + wrapped;
                break;
            }

            case BasePromptInstallMode.Update:
            {
                var existing = File.Exists(path) ? File.ReadAllText(path) : "";
                var tagPattern = $@"<{TagName} version=""[^""]+"">[\s\S]*?</{TagName}>";
                if (Regex.IsMatch(existing, tagPattern))
                {
                    finalContent = Regex.Replace(existing, tagPattern, wrapped);
                }
                else
                {
                    var legacyPattern = @"# Consult User MCP[\s\S]*?(?=\n#[^#]|\z)";
                    finalContent = Regex.IsMatch(existing, legacyPattern)
                        ? Regex.Replace(existing, legacyPattern, wrapped)
                        : existing.TrimEnd() + "\n\n" + wrapped;
                }
                break;
            }

            default:
                return;
        }

        File.WriteAllText(path, finalContent);
    }

    private static string? WrappedBasePromptContent()
    {
        var content = BasePromptContent();
        if (content is null) return null;
        return $"<{TagName} version=\"{BundledVersion}\">\n{content.Trim()}\n</{TagName}>";
    }

    private static int CompareVersions(string v1, string v2)
    {
        var parts1 = v1.Split('.').Select(int.Parse).ToArray();
        var parts2 = v2.Split('.').Select(int.Parse).ToArray();
        var len = Math.Max(parts1.Length, parts2.Length);

        for (var i = 0; i < len; i++)
        {
            var p1 = i < parts1.Length ? parts1[i] : 0;
            var p2 = i < parts2.Length ? parts2[i] : 0;
            if (p1 != p2) return p1.CompareTo(p2);
        }
        return 0;
    }
}
