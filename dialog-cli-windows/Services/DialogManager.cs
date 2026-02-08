using System.Text.Json;
using System.Text.Json.Serialization;
using System.Windows;
using DialogCLI.Components;
using DialogCLI.Models;

namespace DialogCLI.Services;

public partial class DialogManager
{
    public static DialogManager Shared { get; } = new();

    public string ClientName { get; private set; } = "MCP";
    public string? ProjectPath { get; private set; }

    public static readonly JsonSerializerOptions ReadOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) },
    };

    public static readonly JsonSerializerOptions WriteOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
        Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) },
    };

    public AppSettings? AppSettings { get; private set; }

    public void SetClientName(string name) => ClientName = name;
    public void SetProjectPath(string path) => ProjectPath = path;

    public void ApplySettings(AppSettings settings) => AppSettings = settings;

    public int RunDialog<TReq, TRes>(string json, Func<TReq, string, TRes> showDialog)
    {
        var request = JsonSerializer.Deserialize<TReq>(json, ReadOptions)
            ?? throw new JsonException("Deserialized to null");

        var app = new Application { ShutdownMode = ShutdownMode.OnExplicitShutdown };
        TRes? result = default;

        app.Startup += (_, _) =>
        {
            result = showDialog(request, ClientName);
            app.Shutdown();
        };

        app.Run();
        WriteJson(result!);

        var dialogType = typeof(TReq).Name.Replace("Request", "").ToLowerInvariant();
        HistoryManager.Record(dialogType, ClientName, ExtractSummary(json), result);

        return 0;
    }

    public void PositionAndShow(DialogBase dialog, DialogPosition position)
    {
        dialog.Loaded += (_, _) => WindowPositioner.Position(dialog, position);
        dialog.ShowDialog();
    }

    public static void WriteJson<T>(T value)
    {
        Console.WriteLine(JsonSerializer.Serialize(value, WriteOptions));
    }

    private static string ExtractSummary(string json)
    {
        try
        {
            using var doc = JsonDocument.Parse(json);
            if (doc.RootElement.TryGetProperty("body", out var body))
                return body.GetString() ?? "";
            if (doc.RootElement.TryGetProperty("title", out var title))
                return title.GetString() ?? "";
        }
        catch { }
        return "";
    }
}
