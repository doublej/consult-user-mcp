using System.IO;
using System.Text.Json;
using System.Text.Json.Serialization;
using ConsultUserMCP.Models;

namespace ConsultUserMCP.Services;

public class SettingsManager
{
    public static SettingsManager Shared { get; } = new();

    private static readonly string AppDataDir = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "ConsultUserMCP"
    );

    private static readonly string SettingsPath = Path.Combine(AppDataDir, "settings.json");
    private static readonly string SnoozeStatePath = Path.Combine(AppDataDir, "snooze-state.json");

    public static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
        WriteIndented = true,
        Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) },
    };

    public DialogSettings Settings { get; private set; } = new();

    public event Action? SettingsChanged;

    public void Load()
    {
        EnsureDirectory();
        if (!File.Exists(SettingsPath)) return;

        try
        {
            var json = File.ReadAllText(SettingsPath);
            Settings = JsonSerializer.Deserialize<DialogSettings>(json, JsonOptions) ?? new();
        }
        catch
        {
            Settings = new();
        }
    }

    public void Save()
    {
        EnsureDirectory();
        var json = JsonSerializer.Serialize(Settings, JsonOptions);
        var tempPath = SettingsPath + ".tmp";
        File.WriteAllText(tempPath, json);
        File.Move(tempPath, SettingsPath, overwrite: true);
        SettingsChanged?.Invoke();
    }

    public SnoozeState LoadSnoozeState()
    {
        if (!File.Exists(SnoozeStatePath))
            return new SnoozeState();

        try
        {
            var json = File.ReadAllText(SnoozeStatePath);
            return JsonSerializer.Deserialize<SnoozeState>(json, JsonOptions) ?? new();
        }
        catch
        {
            return new SnoozeState();
        }
    }

    public void SaveSnoozeState(SnoozeState state)
    {
        EnsureDirectory();
        var json = JsonSerializer.Serialize(state, JsonOptions);
        var tempPath = SnoozeStatePath + ".tmp";
        File.WriteAllText(tempPath, json);
        File.Move(tempPath, SnoozeStatePath, overwrite: true);
    }

    public void ClearSnoozeState()
    {
        if (File.Exists(SnoozeStatePath))
            File.Delete(SnoozeStatePath);
    }

    private static void EnsureDirectory()
    {
        Directory.CreateDirectory(AppDataDir);
    }

    public static string GetSettingsPath() => SettingsPath;
    public static string GetSnoozeStatePath() => SnoozeStatePath;
    public static string GetAppDataDir() => AppDataDir;
}
