using System.Reflection;
using ConsultUserMCP.Models;
using Velopack;
using Velopack.Sources;

namespace ConsultUserMCP.Services;

public class UpdateManager
{
    public static UpdateManager Shared { get; } = new();

    private readonly Velopack.UpdateManager _manager = new(
        new GithubSource("https://github.com/jurrejan/consult-user-mcp", null, false));

    public string CurrentVersion { get; } = Assembly.GetExecutingAssembly()
        .GetName().Version?.ToString(3) ?? "0.0.0";

    public bool IsUpdateAvailable { get; private set; }
    public bool IsChecking { get; private set; }
    public string StatusMessage { get; private set; } = "";

    public event Action? StateChanged;

    private UpdateInfo? _updateInfo;

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
            _updateInfo = await _manager.CheckForUpdatesAsync();

            settings.LastUpdateCheckTime = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
            SettingsManager.Shared.Save();

            if (_updateInfo is null)
            {
                StatusMessage = "You're up to date.";
                IsUpdateAvailable = false;
            }
            else
            {
                var remoteVersion = _updateInfo.TargetFullRelease.Version.ToString();
                IsUpdateAvailable = remoteVersion != settings.IgnoredUpdateVersion;

                settings.LatestKnownVersion = remoteVersion;
                SettingsManager.Shared.Save();

                StatusMessage = IsUpdateAvailable
                    ? $"Update available: v{remoteVersion}"
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

    public async Task DownloadAndApplyAsync()
    {
        if (_updateInfo is null) return;

        StatusMessage = "Downloading update...";
        StateChanged?.Invoke();

        try
        {
            await _manager.DownloadUpdatesAsync(_updateInfo);
            _manager.ApplyUpdatesAndRestart(_updateInfo);
        }
        catch (Exception ex)
        {
            StatusMessage = $"Update failed: {ex.Message}";
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

    private bool ShouldAutoCheck(DialogSettings settings)
    {
        if (!settings.AutoCheckForUpdatesEnabled) return false;
        var interval = settings.UpdateCheckCadence.MinimumInterval();
        if (interval is null) return false;
        var lastCheck = DateTimeOffset.FromUnixTimeSeconds((long)settings.LastUpdateCheckTime);
        return DateTimeOffset.UtcNow - lastCheck > interval;
    }
}
