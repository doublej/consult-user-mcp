namespace ConsultUserMCP.Models;

public class DialogSettings
{
    // Appearance
    public DialogPosition Position { get; set; } = DialogPosition.Left;
    public DialogSize Size { get; set; } = DialogSize.Regular;
    public SoundEffect SoundOnShow { get; set; } = SoundEffect.Subtle;
    public bool AnimationsEnabled { get; set; } = true;
    public bool AlwaysOnTop { get; set; } = true;

    // Behavior
    public bool ShowCommentField { get; set; } = true;
    public bool ButtonCooldownEnabled { get; set; } = true;
    public double ButtonCooldownDuration { get; set; } = 2.0;

    // Sound preferences
    public bool PlaySoundForQuestions { get; set; } = true;
    public bool PlaySoundForNotifications { get; set; }
    public bool MuteSoundsWhileSnoozed { get; set; } = true;

    // Updates
    public bool AutoCheckForUpdatesEnabled { get; set; } = true;
    public UpdateCheckCadence UpdateCheckCadence { get; set; } = UpdateCheckCadence.Weekly;
    public UpdateReminderInterval UpdateReminderInterval { get; set; } = UpdateReminderInterval.ThreeDays;
    public bool IncludePrereleaseUpdates { get; set; }
    public double LastUpdateCheckTime { get; set; }
    public string LatestKnownVersion { get; set; } = "";
    public string IgnoredUpdateVersion { get; set; } = "";

    // Snooze
    public DateTime? SnoozeUntil { get; set; }

    // Window state
    public double SettingsWindowLeft { get; set; } = double.NaN;
    public double SettingsWindowTop { get; set; } = double.NaN;
    public double SettingsWindowWidth { get; set; } = 780;
    public double SettingsWindowHeight { get; set; } = 600;
}
