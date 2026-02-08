using System.Windows.Threading;

namespace DialogCLI.Services;

/// <summary>
/// Blocks keyboard input for a configurable duration after dialog appears,
/// preventing accidental double-clicks/keypresses.
/// </summary>
public class CooldownManager
{
    private bool _coolingDown;
    private readonly DispatcherTimer _timer;
    private Action? _onComplete;

    public bool IsCoolingDown => _coolingDown;

    public CooldownManager()
    {
        _timer = new DispatcherTimer();
        _timer.Tick += (_, _) =>
        {
            _timer.Stop();
            _coolingDown = false;
            _onComplete?.Invoke();
        };
    }

    public void Start(double durationSeconds, Action? onComplete = null)
    {
        var settings = DialogManager.Shared.AppSettings;
        if (settings is not null && !settings.ButtonCooldownEnabled)
            return;

        var duration = settings?.ButtonCooldownDuration ?? durationSeconds;
        _coolingDown = true;
        _onComplete = onComplete;
        _timer.Interval = TimeSpan.FromSeconds(duration);
        _timer.Start();
    }
}
