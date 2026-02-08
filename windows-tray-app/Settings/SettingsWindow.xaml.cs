using System.Windows;
using System.Windows.Controls;
using ConsultUserMCP.Services;

namespace ConsultUserMCP.Settings;

public partial class SettingsWindow : Window
{
    private readonly GeneralSettingsView _generalView = new();
    private readonly UpdatesSettingsView _updatesView = new();
    private readonly ProjectsSettingsView _projectsView = new();
    private readonly AboutSettingsView _aboutView = new();
    private readonly HistorySettingsView _historyView = new();

    public SettingsWindow()
    {
        InitializeComponent();
        RestoreWindowPosition();
        Closing += OnClosing;
    }

    private void OnSectionChanged(object sender, SelectionChangedEventArgs e)
    {
        ContentArea.Content = SectionList.SelectedIndex switch
        {
            0 => _generalView,
            1 => _updatesView,
            2 => _projectsView,
            3 => _aboutView,
            4 => _historyView,
            _ => _generalView,
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
