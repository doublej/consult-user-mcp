using System.IO;
using System.Text.Json;

namespace DialogCLI.Services;

public static class HistoryManager
{
    private static readonly string HistoryDir = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "ConsultUserMCP", "history"
    );

    private static readonly JsonSerializerOptions WriteOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        WriteIndented = false,
    };

    public static void Record(string dialogType, string clientName, string summary, object? result)
    {
        try
        {
            Directory.CreateDirectory(HistoryDir);

            var entry = new
            {
                timestamp = DateTime.UtcNow.ToString("O"),
                dialogType,
                clientName,
                summary,
                projectPath = DialogManager.Shared.ProjectPath,
            };

            var fileName = $"{DateTime.UtcNow:yyyy-MM-dd}.jsonl";
            var filePath = Path.Combine(HistoryDir, fileName);
            var line = JsonSerializer.Serialize(entry, WriteOptions);
            File.AppendAllText(filePath, line + "\n");

            Prune();
        }
        catch
        {
            // Silently ignore history write failures
        }
    }

    private static void Prune()
    {
        try
        {
            var cutoff = DateTime.UtcNow.AddDays(-30);
            foreach (var file in Directory.GetFiles(HistoryDir, "*.jsonl"))
            {
                var name = Path.GetFileNameWithoutExtension(file);
                if (DateTime.TryParse(name, out var date) && date < cutoff)
                    File.Delete(file);
            }
        }
        catch { }
    }
}
