namespace ConsultUserMCP.Models;

public enum DialogPosition
{
    Left,
    Center,
    Right,
}

public enum DialogSize
{
    Compact,
    Regular,
    Large,
}

public enum SoundEffect
{
    None,
    Subtle,
    Pop,
    Chime,
}

public enum UpdateCheckCadence
{
    Daily,
    Weekly,
    Manual,
}

public enum UpdateReminderInterval
{
    OneDay,
    ThreeDays,
    SevenDays,
}

public static class EnumExtensions
{
    public static double Scale(this DialogSize size) => size switch
    {
        DialogSize.Compact => 0.85,
        DialogSize.Large => 1.2,
        _ => 1.0,
    };

    public static TimeSpan? MinimumInterval(this UpdateCheckCadence cadence) => cadence switch
    {
        UpdateCheckCadence.Daily => TimeSpan.FromDays(1),
        UpdateCheckCadence.Weekly => TimeSpan.FromDays(7),
        _ => null,
    };

    public static TimeSpan Interval(this UpdateReminderInterval reminder) => reminder switch
    {
        UpdateReminderInterval.OneDay => TimeSpan.FromDays(1),
        UpdateReminderInterval.ThreeDays => TimeSpan.FromDays(3),
        UpdateReminderInterval.SevenDays => TimeSpan.FromDays(7),
        _ => TimeSpan.FromDays(3),
    };
}
