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

        SetNormalIcon();
        _trayIcon.TrayMouseDoubleClick += (_, _) => OpenSettings();

        SnoozeManager.Shared.SnoozeChanged += OnSnoozeChanged;
    }

    public void SetNormalIcon()
    {
        if (_trayIcon is null) return;
        _trayIcon.Icon = CreateIconFromText("\U0001F4AC");
        _trayIcon.ToolTipText = "Consult User MCP";
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
                SetNormalIcon();
        });
    }

    private void OpenSettings()
    {
        if (_settingsWindow is { IsVisible: true })
        {
            _settingsWindow.Activate();
            return;
        }

        _settingsWindow = new SettingsWindow();
        _settingsWindow.Show();
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

    public void Dispose()
    {
        SnoozeManager.Shared.SnoozeChanged -= OnSnoozeChanged;
        _trayIcon?.Dispose();
        _settingsWindow?.Close();
    }
}
