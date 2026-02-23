using System.Windows;
using System.Windows.Controls;
using ConsultUserMCP.Services;

namespace ConsultUserMCP.Settings;

public partial class SettingsWindow : Window
{
    private readonly InstallSettingsView _installView = new();
    private readonly GeneralSettingsView _generalView = new();
    private readonly UpdatesSettingsView _updatesView = new();
    private readonly ProjectsSettingsView _projectsView = new();
    private readonly AboutSettingsView _aboutView = new();
    private readonly HistorySettingsView _historyView = new();
    private readonly UninstallSettingsView _uninstallView = new();

    public SettingsWindow()
    {
        InitializeComponent();
        ContentArea.Content = _installView;
        RestoreWindowPosition();
        Closing += OnClosing;
    }

    private void OnSectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (ContentArea is null) return;

        ContentArea.Content = SectionList.SelectedIndex switch
        {
            0 => _installView,
            1 => _generalView,
            2 => _updatesView,
            3 => _projectsView,
            4 => _aboutView,
            5 => _historyView,
            6 => _uninstallView,
            _ => _installView,
        };
    }

    private void RestoreWindowPosition()
    {
        var s = SettingsManager.Shared.Settings;
        if (!double.IsNaN(s.SettingsWindowLeft))
        {
            Left = s.SettingsWindowLeft;
            Top = s.SettingsWindowTop;
            WindowStartupLocation = WindowStartupLocation.Manual;
        }
        Width = s.SettingsWindowWidth;
        Height = s.SettingsWindowHeight;
    }

    private void OnClosing(object? sender, System.ComponentModel.CancelEventArgs e)
    {
        var s = SettingsManager.Shared.Settings;
        s.SettingsWindowLeft = Left;
        s.SettingsWindowTop = Top;
        s.SettingsWindowWidth = Width;
        s.SettingsWindowHeight = Height;
        SettingsManager.Shared.Save();
    }
}
