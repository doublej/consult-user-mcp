using System.Diagnostics;
using System.IO;
using System.Net.Http;
using System.Reflection;
using System.Text.Json;
using ConsultUserMCP.Models;

namespace ConsultUserMCP.Services;

public class UpdateManager
{
    public static UpdateManager Shared { get; } = new();

    private const string ReleasesUrl = "https://api.github.com/repos/jurrejan/consult-user-mcp/releases";
    private static readonly HttpClient Http = new();

    public string CurrentVersion { get; } = Assembly.GetExecutingAssembly()
        .GetName().Version?.ToString(3) ?? "0.0.0";

    public GitHubRelease? LatestRelease { get; private set; }
    public bool IsUpdateAvailable { get; private set; }
    public bool IsChecking { get; private set; }
    public string StatusMessage { get; private set; } = "";

    public event Action? StateChanged;

    static UpdateManager()
    {
        Http.DefaultRequestHeaders.UserAgent.ParseAdd("ConsultUserMCP/1.0");
    }

    public async Task CheckForUpdatesAsync(bool manual = false)
    {
        var settings = SettingsManager.Shared.Settings;

        if (!manual && !ShouldAutoCheck(settings))
            return;

        IsChecking = true;
        StatusMessage = "Checking for updates...";
        StateChanged?.Invoke();

        try
        {
            var releases = await FetchReleasesAsync(settings.IncludePrereleaseUpdates);
            var latest = releases.FirstOrDefault();

            settings.LastUpdateCheckTime = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
            SettingsManager.Shared.Save();

            if (latest is null)
            {
                StatusMessage = "No releases found.";
                IsUpdateAvailable = false;
            }
            else
            {
                LatestRelease = latest;
                var remoteVersion = ParseVersion(latest.TagName);
                var currentVersion = ParseVersion(CurrentVersion);
                IsUpdateAvailable = remoteVersion > currentVersion
                    && latest.TagName.TrimStart('v') != settings.IgnoredUpdateVersion;

                settings.LatestKnownVersion = latest.TagName.TrimStart('v');
                SettingsManager.Shared.Save();

                StatusMessage = IsUpdateAvailable
                    ? $"Update available: v{latest.TagName.TrimStart('v')}"
                    : "You're up to date.";
            }
        }
        catch (Exception ex)
        {
            StatusMessage = $"Check failed: {ex.Message}";
            IsUpdateAvailable = false;
        }
        finally
        {
            IsChecking = false;
            StateChanged?.Invoke();
        }
    }

    public void IgnoreVersion(string version)
    {
        SettingsManager.Shared.Settings.IgnoredUpdateVersion = version;
        SettingsManager.Shared.Save();
        IsUpdateAvailable = false;
        StatusMessage = $"Version {version} ignored.";
        StateChanged?.Invoke();
    }

    public async Task<string?> DownloadUpdateAsync(IProgress<double>? progress = null)
    {
        if (LatestRelease is null) return null;

        var asset = LatestRelease.Assets
            .FirstOrDefault(a => a.Name.EndsWith(".zip", StringComparison.OrdinalIgnoreCase));
        if (asset is null) return null;

        var tempPath = Path.Combine(Path.GetTempPath(), "consult-user-mcp-update.zip");

        using var response = await Http.GetAsync(asset.BrowserDownloadUrl, HttpCompletionOption.ResponseHeadersRead);
        response.EnsureSuccessStatusCode();

        var totalBytes = response.Content.Headers.ContentLength ?? -1;
        await using var contentStream = await response.Content.ReadAsStreamAsync();
        await using var fileStream = new FileStream(tempPath, FileMode.Create, FileAccess.Write, FileShare.None);

        var buffer = new byte[81920];
        long downloaded = 0;
        int bytesRead;
        while ((bytesRead = await contentStream.ReadAsync(buffer)) > 0)
        {
            await fileStream.WriteAsync(buffer.AsMemory(0, bytesRead));
            downloaded += bytesRead;
            if (totalBytes > 0)
                progress?.Report((double)downloaded / totalBytes);
        }

        return tempPath;
    }

    public void ApplyUpdate(string zipPath)
    {
        var targetDir = AppDomain.CurrentDomain.BaseDirectory;
        var currentPid = Environment.ProcessId;

        // PowerShell script to wait for exit, extract, and restart
        var script = $"""
            Start-Sleep -Seconds 2
            Expand-Archive -Path '{zipPath}' -DestinationPath '{targetDir}' -Force
            Remove-Item -Path '{zipPath}' -Force
            Start-Process '{Path.Combine(targetDir, "ConsultUserMCP.exe")}'
            """;

        var psi = new ProcessStartInfo
        {
            FileName = "powershell.exe",
            Arguments = $"-NoProfile -ExecutionPolicy Bypass -Command \"{script}\"",
            CreateNoWindow = true,
            UseShellExecute = false,
        };
        Process.Start(psi);

        System.Windows.Application.Current.Shutdown();
    }

    private bool ShouldAutoCheck(DialogSettings settings)
    {
        if (!settings.AutoCheckForUpdatesEnabled) return false;
        var interval = settings.UpdateCheckCadence.MinimumInterval();
        if (interval is null) return false;
        var lastCheck = DateTimeOffset.FromUnixTimeSeconds((long)settings.LastUpdateCheckTime);
        return DateTimeOffset.UtcNow - lastCheck > interval;
    }

    private async Task<List<GitHubRelease>> FetchReleasesAsync(bool includePrerelease)
    {
        var url = includePrerelease ? ReleasesUrl : $"{ReleasesUrl}/latest";
        var request = new HttpRequestMessage(HttpMethod.Get, url);
        request.Headers.Accept.ParseAdd("application/vnd.github+json");

        var response = await Http.SendAsync(request);
        response.EnsureSuccessStatusCode();

        var json = await response.Content.ReadAsStringAsync();
        var options = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
        };

        if (includePrerelease)
            return JsonSerializer.Deserialize<List<GitHubRelease>>(json, options) ?? [];

        var single = JsonSerializer.Deserialize<GitHubRelease>(json, options);
        return single is not null ? [single] : [];
    }

    private static Version ParseVersion(string versionString)
    {
        var cleaned = versionString.TrimStart('v');
        return Version.TryParse(cleaned, out var v) ? v : new Version(0, 0, 0);
    }
}
