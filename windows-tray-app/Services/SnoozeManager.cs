using System.Windows.Threading;
using ConsultUserMCP.Models;

namespace ConsultUserMCP.Services;

public class SnoozeManager : IDisposable
{
    public static SnoozeManager Shared { get; } = new();

    private readonly DispatcherTimer _timer;
    private SnoozeState _state = new();

    public bool IsActive => _state.SnoozeUntil.HasValue && _state.SnoozeUntil > DateTime.UtcNow;
    public int RemainingSeconds => IsActive
        ? (int)(_state.SnoozeUntil!.Value - DateTime.UtcNow).TotalSeconds
        : 0;
    public int SnoozedRequestCount => _state.SnoozedRequests.Count;

    /// <summary>Fires with (isActive, remainingSeconds) on every state change.</summary>
    public event Action<bool, int>? SnoozeChanged;

    private SnoozeManager()
    {
        _timer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(1) };
        _timer.Tick += OnTimerTick;
        LoadState();
        if (IsActive) _timer.Start();
    }

    public void StartSnooze(int minutes)
    {
        _state.SnoozeUntil = DateTime.UtcNow.AddMinutes(minutes);
        _state.SnoozedRequests.Clear();
        SaveState();

        // Also update the settings file so dialog-cli can detect snooze
        SettingsManager.Shared.Settings.SnoozeUntil = _state.SnoozeUntil;
        SettingsManager.Shared.Save();

        _timer.Start();
        SnoozeChanged?.Invoke(true, RemainingSeconds);
    }

    public void EndSnooze()
    {
        _timer.Stop();
        var missedCount = _state.SnoozedRequests.Count;
        _state.SnoozeUntil = null;
        _state.SnoozedRequests.Clear();
        SaveState();

        SettingsManager.Shared.Settings.SnoozeUntil = null;
        SettingsManager.Shared.Save();
        SettingsManager.Shared.ClearSnoozeState();

        SnoozeChanged?.Invoke(false, 0);
    }

    public void AddSnoozedRequest(string clientName, string dialogType, string summary)
    {
        if (!IsActive) return;
        _state.SnoozedRequests.Add(new SnoozedRequest
        {
            ClientName = clientName,
            DialogType = dialogType,
            Summary = summary,
        });
        SaveState();
    }

    private void OnTimerTick(object? sender, EventArgs e)
    {
        if (!IsActive)
        {
            EndSnooze();
            return;
        }
        SnoozeChanged?.Invoke(true, RemainingSeconds);
    }

    private void LoadState()
    {
        _state = SettingsManager.Shared.LoadSnoozeState();
        // Clear expired snooze
        if (_state.SnoozeUntil.HasValue && _state.SnoozeUntil <= DateTime.UtcNow)
        {
            _state.SnoozeUntil = null;
            _state.SnoozedRequests.Clear();
            SaveState();
        }
    }

    private void SaveState()
    {
        SettingsManager.Shared.SaveSnoozeState(_state);
    }

    public void Dispose()
    {
        _timer.Stop();
    }
}
