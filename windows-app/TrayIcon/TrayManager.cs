using System.Drawing;
using System.IO;
using System.Windows;
using ConsultUserMCP.Services;
using ConsultUserMCP.Settings;
using Hardcodet.Wpf.TaskbarNotification;

namespace ConsultUserMCP.TrayIcon;

public class TrayManager : IDisposable
{
    private TaskbarIcon? _trayIcon;
    private SettingsWindow? _settingsWindow;

    public void Initialize()
    {
        _trayIcon = new TaskbarIcon
        {
            ToolTipText = "Consult User MCP",
            ContextMenu = TrayMenu.Build(
                onSettings: OpenSettings,
                onCheckUpdates: CheckForUpdates,
                onQuit: Quit
            ),
        };

        UpdateIcon();
        _trayIcon.TrayMouseDoubleClick += (_, _) => OpenSettings();

        SnoozeManager.Shared.SnoozeChanged += OnSnoozeChanged;
        Services.UpdateManager.Shared.StateChanged += OnUpdateStateChanged;
    }

    public void SetNormalIcon()
    {
        if (_trayIcon is null) return;
        _trayIcon.Icon = CreateIconFromText("\U0001F4AC");
        _trayIcon.ToolTipText = "Consult User MCP";
    }

    public void SetUpdateAvailableIcon(string version)
    {
        if (_trayIcon is null) return;
        _trayIcon.Icon = CreateIconWithBadge("\U0001F4AC");
        _trayIcon.ToolTipText = $"Consult User MCP - Update available: v{version}";
    }

    public void SetSnoozedIcon(int remainingSeconds)
    {
        if (_trayIcon is null) return;
        _trayIcon.Icon = CreateIconFromText("\U0001F319");
        var minutes = remainingSeconds / 60;
        var seconds = remainingSeconds % 60;
        _trayIcon.ToolTipText = $"Consult User MCP - Snoozed ({minutes}:{seconds:D2} remaining)";
    }

    private void OnSnoozeChanged(bool isActive, int remainingSeconds)
    {
        Application.Current.Dispatcher.Invoke(() =>
        {
            if (isActive)
                SetSnoozedIcon(remainingSeconds);
            else
                UpdateIcon();
        });
    }

    private void OnUpdateStateChanged()
    {
        Application.Current.Dispatcher.Invoke(UpdateIcon);
    }

    private void UpdateIcon()
    {
        if (SnoozeManager.Shared.IsActive)
            return; // Snooze icon takes priority

        if (Services.UpdateManager.Shared.IsUpdateAvailable)
        {
            var version = SettingsManager.Shared.Settings.LatestKnownVersion ?? "";
            SetUpdateAvailableIcon(version);
        }
        else
        {
            SetNormalIcon();
        }
    }

    private void OpenSettings()
    {
        try
        {
            if (_settingsWindow is { IsVisible: true })
            {
                _settingsWindow.Activate();
                return;
            }

            _settingsWindow = new SettingsWindow();
            _settingsWindow.Show();
        }
        catch (Exception ex)
        {
            var logPath = Path.Combine(Path.GetTempPath(), "consult-user-mcp-error.log");
            File.WriteAllText(logPath, ex.ToString());
            MessageBox.Show($"Failed to open settings. Error logged to:\n{logPath}", "Error",
                MessageBoxButton.OK, MessageBoxImage.Error);
        }
    }

    private void CheckForUpdates()
    {
        _ = UpdateManager.Shared.CheckForUpdatesAsync(manual: true);
    }

    private void Quit()
    {
        SnoozeManager.Shared.Dispose();
        _trayIcon?.Dispose();
        Application.Current.Shutdown();
    }

    private static Icon CreateIconFromText(string text)
    {
        using var bmp = new Bitmap(32, 32);
        using var g = Graphics.FromImage(bmp);
        g.Clear(Color.Transparent);
        using var font = new Font("Segoe UI Emoji", 20, System.Drawing.FontStyle.Regular);
        using var brush = new SolidBrush(Color.White);
        g.DrawString(text, font, brush, -2, 0);
        return System.Drawing.Icon.FromHandle(bmp.GetHicon());
    }

    private static Icon CreateIconWithBadge(string text)
    {
        using var bmp = new Bitmap(32, 32);
        using var g = Graphics.FromImage(bmp);
        g.Clear(Color.Transparent);
        g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;

        // Draw base emoji
        using var font = new Font("Segoe UI Emoji", 20, System.Drawing.FontStyle.Regular);
        using var brush = new SolidBrush(Color.White);
        g.DrawString(text, font, brush, -2, 0);

        // Draw orange badge dot in top-right corner
        using var badgeBrush = new SolidBrush(Color.FromArgb(255, 140, 0)); // Orange
        g.FillEllipse(badgeBrush, 22, 0, 10, 10);

        return System.Drawing.Icon.FromHandle(bmp.GetHicon());
    }

    public void Dispose()
    {
        SnoozeManager.Shared.SnoozeChanged -= OnSnoozeChanged;
        Services.UpdateManager.Shared.StateChanged -= OnUpdateStateChanged;
        _trayIcon?.Dispose();
        _settingsWindow?.Close();
    }
}
