using System.Windows;
using System.Windows.Controls;
using ConsultUserMCP.Models;
using ConsultUserMCP.Services;

namespace ConsultUserMCP.Settings;

public partial class GeneralSettingsView : UserControl
{
    private bool _loading = true;

    public GeneralSettingsView()
    {
        InitializeComponent();
        Loaded += OnLoaded;
    }

    private void OnLoaded(object sender, RoutedEventArgs e)
    {
        LoadSettings();
        SnoozeManager.Shared.SnoozeChanged += OnSnoozeChanged;
        UpdateSnoozeBanner();
    }

    private void LoadSettings()
    {
        _loading = true;
        var s = SettingsManager.Shared.Settings;

        PositionCombo.SelectedIndex = (int)s.Position;
        SizeCombo.SelectedIndex = (int)s.Size;
        SoundCombo.SelectedIndex = (int)s.SoundOnShow;

        AnimationsCheck.IsChecked = s.AnimationsEnabled;
        AlwaysOnTopCheck.IsChecked = s.AlwaysOnTop;
        ShowCommentCheck.IsChecked = s.ShowCommentField;

        CooldownCheck.IsChecked = s.ButtonCooldownEnabled;
        CooldownSlider.Value = s.ButtonCooldownDuration;
        CooldownLabel.Text = $"{s.ButtonCooldownDuration:F1}s";
        CooldownPanel.Visibility = s.ButtonCooldownEnabled ? Visibility.Visible : Visibility.Collapsed;

        SoundQuestionsCheck.IsChecked = s.PlaySoundForQuestions;
        SoundNotificationsCheck.IsChecked = s.PlaySoundForNotifications;
        MuteSnoozedCheck.IsChecked = s.MuteSoundsWhileSnoozed;

        _loading = false;
    }

    private void OnPositionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_loading) return;
        SettingsManager.Shared.Settings.Position = (DialogPosition)PositionCombo.SelectedIndex;
        SettingsManager.Shared.Save();
    }

    private void OnSizeChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_loading) return;
        SettingsManager.Shared.Settings.Size = (DialogSize)SizeCombo.SelectedIndex;
        SettingsManager.Shared.Save();
    }

    private void OnSoundChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_loading) return;
        SettingsManager.Shared.Settings.SoundOnShow = (SoundEffect)SoundCombo.SelectedIndex;
        SettingsManager.Shared.Save();
    }

    private void OnSettingToggled(object sender, RoutedEventArgs e)
    {
        if (_loading) return;
        var s = SettingsManager.Shared.Settings;
        s.AnimationsEnabled = AnimationsCheck.IsChecked == true;
        s.AlwaysOnTop = AlwaysOnTopCheck.IsChecked == true;
        s.ShowCommentField = ShowCommentCheck.IsChecked == true;
        s.ButtonCooldownEnabled = CooldownCheck.IsChecked == true;
        s.PlaySoundForQuestions = SoundQuestionsCheck.IsChecked == true;
        s.PlaySoundForNotifications = SoundNotificationsCheck.IsChecked == true;
        s.MuteSoundsWhileSnoozed = MuteSnoozedCheck.IsChecked == true;

        CooldownPanel.Visibility = s.ButtonCooldownEnabled ? Visibility.Visible : Visibility.Collapsed;

        SettingsManager.Shared.Save();
    }

    private void OnCooldownChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        if (_loading) return;
        SettingsManager.Shared.Settings.ButtonCooldownDuration = CooldownSlider.Value;
        CooldownLabel.Text = $"{CooldownSlider.Value:F1}s";
        SettingsManager.Shared.Save();
    }

    private void OnEndSnooze(object sender, RoutedEventArgs e)
    {
        SnoozeManager.Shared.EndSnooze();
    }

    private void OnSnoozeChanged(bool isActive, int remainingSeconds)
    {
        Dispatcher.Invoke(() => UpdateSnoozeBanner());
    }

    private void UpdateSnoozeBanner()
    {
        if (SnoozeManager.Shared.IsActive)
        {
            SnoozeBanner.Visibility = Visibility.Visible;
            var remaining = SnoozeManager.Shared.RemainingSeconds;
            var minutes = remaining / 60;
            var seconds = remaining % 60;
            SnoozeTimerText.Text = $"Snoozed - {minutes}:{seconds:D2} remaining";
            SnoozeMissedText.Text = $"{SnoozeManager.Shared.SnoozedRequestCount} missed dialogs";
        }
        else
        {
            SnoozeBanner.Visibility = Visibility.Collapsed;
        }
    }
}
