using System.Windows;
using System.Windows.Controls;
using ConsultUserMCP.Models;
using ConsultUserMCP.Services;

namespace ConsultUserMCP.Settings;

public partial class UpdatesSettingsView : UserControl
{
    private bool _loading = true;

    public UpdatesSettingsView()
    {
        InitializeComponent();
        Loaded += OnLoaded;
    }

    private void OnLoaded(object sender, RoutedEventArgs e)
    {
        LoadSettings();
        UpdateManager.Shared.StateChanged += OnUpdateStateChanged;
        RefreshStatus();
    }

    private void LoadSettings()
    {
        _loading = true;
        var s = SettingsManager.Shared.Settings;

        VersionText.Text = $"v{UpdateManager.Shared.CurrentVersion}";
        AutoCheckBox.IsChecked = s.AutoCheckForUpdatesEnabled;
        CadenceCombo.SelectedIndex = (int)s.UpdateCheckCadence;
        ReminderCombo.SelectedIndex = (int)s.UpdateReminderInterval;
        PrereleaseCheck.IsChecked = s.IncludePrereleaseUpdates;

        _loading = false;
    }

    private void RefreshStatus()
    {
        var um = UpdateManager.Shared;
        StatusText.Text = um.StatusMessage.Length > 0
            ? um.StatusMessage
            : "Not checked yet.";
        CheckNowButton.IsEnabled = !um.IsChecking;
        CheckNowButton.Content = um.IsChecking ? "Checking..." : "Check Now";
    }

    private void OnAutoCheckToggled(object sender, RoutedEventArgs e)
    {
        if (_loading) return;
        SettingsManager.Shared.Settings.AutoCheckForUpdatesEnabled = AutoCheckBox.IsChecked == true;
        SettingsManager.Shared.Save();
    }

    private void OnCadenceChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_loading) return;
        SettingsManager.Shared.Settings.UpdateCheckCadence = (UpdateCheckCadence)CadenceCombo.SelectedIndex;
        SettingsManager.Shared.Save();
    }

    private void OnReminderChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_loading) return;
        SettingsManager.Shared.Settings.UpdateReminderInterval = (UpdateReminderInterval)ReminderCombo.SelectedIndex;
        SettingsManager.Shared.Save();
    }

    private void OnPrereleaseToggled(object sender, RoutedEventArgs e)
    {
        if (_loading) return;
        SettingsManager.Shared.Settings.IncludePrereleaseUpdates = PrereleaseCheck.IsChecked == true;
        SettingsManager.Shared.Save();
    }

    private async void OnCheckNow(object sender, RoutedEventArgs e)
    {
        await UpdateManager.Shared.CheckForUpdatesAsync(manual: true);
    }

    private void OnUpdateStateChanged()
    {
        Dispatcher.Invoke(RefreshStatus);
    }
}
