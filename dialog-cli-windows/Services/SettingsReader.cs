using System.IO;
using System.Text.Json;
using System.Text.Json.Serialization;
using DialogCLI.Models;

namespace DialogCLI.Services;

/// <summary>
/// Reads settings written by the ConsultUserMCP tray app.
/// Falls back to defaults when the tray app isn't running or settings file doesn't exist.
/// </summary>
public static class SettingsReader
{
    private static readonly string SettingsPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "ConsultUserMCP", "settings.json"
    );

    private static readonly string SnoozeStatePath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "ConsultUserMCP", "snooze-state.json"
    );

    private static readonly string SnoozedRequestsPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "ConsultUserMCP", "snoozed-requests.json"
    );

    private static readonly JsonSerializerOptions Options = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) },
    };

    public static AppSettings Load()
    {
        if (!File.Exists(SettingsPath))
            return new AppSettings();

        try
        {
            var json = File.ReadAllText(SettingsPath);
            return JsonSerializer.Deserialize<AppSettings>(json, Options) ?? new();
        }
        catch
        {
            return new AppSettings();
        }
    }

    public static SnoozeInfo? GetSnoozeState()
    {
        if (!File.Exists(SnoozeStatePath))
            return null;

        try
        {
            var json = File.ReadAllText(SnoozeStatePath);
            var state = JsonSerializer.Deserialize<SnoozeInfo>(json, Options);
            if (state?.SnoozeUntil is null || state.SnoozeUntil <= DateTime.UtcNow)
                return null;
            return state;
        }
        catch
        {
            return null;
        }
    }

    public static void QueueSnoozedRequest(string clientName, string dialogType, string summary)
    {
        var dir = Path.GetDirectoryName(SnoozedRequestsPath)!;
        Directory.CreateDirectory(dir);

        List<SnoozedRequestEntry> entries = [];
        if (File.Exists(SnoozedRequestsPath))
        {
            try
            {
                var existing = File.ReadAllText(SnoozedRequestsPath);
                entries = JsonSerializer.Deserialize<List<SnoozedRequestEntry>>(existing, Options) ?? [];
            }
            catch { }
        }

        entries.Add(new SnoozedRequestEntry
        {
            Id = Guid.NewGuid().ToString(),
            Timestamp = DateTime.UtcNow,
            ClientName = clientName,
            DialogType = dialogType,
            Summary = summary,
        });

        var json = JsonSerializer.Serialize(entries, new JsonSerializerOptions(Options) { WriteIndented = true });
        File.WriteAllText(SnoozedRequestsPath, json);
    }
}

public class AppSettings
{
    public DialogPosition Position { get; set; } = DialogPosition.Left;
    public DialogSize Size { get; set; } = DialogSize.Regular;
    public bool AlwaysOnTop { get; set; } = true;
    public bool ShowCommentField { get; set; } = true;
    public bool ButtonCooldownEnabled { get; set; } = true;
    public double ButtonCooldownDuration { get; set; } = 2.0;
    public DateTime? SnoozeUntil { get; set; }
}

public class SnoozeInfo
{
    public DateTime? SnoozeUntil { get; set; }
}

public class SnoozedRequestEntry
{
    public string Id { get; set; } = "";
    public DateTime Timestamp { get; set; }
    public string ClientName { get; set; } = "";
    public string DialogType { get; set; } = "";
    public string Summary { get; set; } = "";
}
