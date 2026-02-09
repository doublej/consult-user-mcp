using System.IO;
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

        DispatcherUnhandledException += (_, args) =>
        {
            var logPath = Path.Combine(Path.GetTempPath(), "consult-user-mcp-error.log");
            File.WriteAllText(logPath, args.Exception.ToString());
            MessageBox.Show($"Unhandled error logged to:\n{logPath}", "Error",
                MessageBoxButton.OK, MessageBoxImage.Error);
            args.Handled = true;
        };

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
