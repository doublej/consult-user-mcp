using System.IO;
using System.Text.Json;
using System.Windows;
using System.Windows.Controls;

namespace ConsultUserMCP.Settings;

public partial class HistorySettingsView : UserControl
{
    private static readonly string HistoryDir = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "ConsultUserMCP", "history"
    );

    public HistorySettingsView()
    {
        InitializeComponent();
        Loaded += OnLoaded;
    }

    private void OnLoaded(object sender, RoutedEventArgs e)
    {
        LoadHistory();
    }

    private void LoadHistory()
    {
        if (!Directory.Exists(HistoryDir))
        {
            ShowEmpty();
            return;
        }

        var entries = new List<HistoryEntry>();
        var files = Directory.GetFiles(HistoryDir, "*.jsonl")
            .OrderByDescending(f => f)
            .Take(3);

        foreach (var file in files)
        {
            try
            {
                foreach (var line in File.ReadLines(file))
                {
                    if (string.IsNullOrWhiteSpace(line)) continue;
                    try
                    {
                        using var doc = JsonDocument.Parse(line);
                        var root = doc.RootElement;
                        entries.Add(new HistoryEntry
                        {
                            Type = root.TryGetProperty("dialogType", out var dt) ? dt.GetString() ?? "" : "",
                            Summary = Truncate(root.TryGetProperty("summary", out var s) ? s.GetString() ?? "" : "", 60),
                            Time = root.TryGetProperty("timestamp", out var ts) && DateTime.TryParse(ts.GetString(), out var d)
                                ? d.ToLocalTime().ToString("HH:mm")
                                : "",
                        });
                    }
                    catch { /* skip malformed lines */ }
                }
            }
            catch { /* skip unreadable files */ }
        }

        if (entries.Count == 0)
        {
            ShowEmpty();
            return;
        }

        entries.Reverse();
        EmptyState.Visibility = Visibility.Collapsed;
        HistoryList.Visibility = Visibility.Visible;
        HistoryList.ItemsSource = entries.Take(50);
    }

    private void ShowEmpty()
    {
        EmptyState.Visibility = Visibility.Visible;
        HistoryList.Visibility = Visibility.Collapsed;
    }

    private static string Truncate(string s, int maxLength)
        => s.Length <= maxLength ? s : s[..maxLength] + "...";
}

public class HistoryEntry
{
    public string Type { get; set; } = "";
    public string Summary { get; set; } = "";
    public string Time { get; set; } = "";
}
