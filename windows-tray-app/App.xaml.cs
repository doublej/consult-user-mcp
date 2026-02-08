using System.Windows;
using ConsultUserMCP.Services;
using ConsultUserMCP.TrayIcon;

namespace ConsultUserMCP;

public partial class App : Application
{
    private TrayManager? _trayManager;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        SettingsManager.Shared.Load();

        _trayManager = new TrayManager();
        _trayManager.Initialize();

        // Auto-check for updates on launch (respects cadence settings)
        _ = UpdateManager.Shared.CheckForUpdatesAsync();
    }

    protected override void OnExit(ExitEventArgs e)
    {
        _trayManager?.Dispose();
        base.OnExit(e);
    }
}
