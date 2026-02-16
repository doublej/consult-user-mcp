using System.Text.Json;
using DialogCLI.Models;
using DialogCLI.Services;

namespace DialogCLI;

public static class Program
{
    [STAThread]
    public static int Main(string[] args)
    {
        if (args.Length > 0 && args[0] is "--version" or "-v")
        {
            Console.WriteLine("dialog-cli 0.1.0");
            return 0;
        }

        if (args.Length < 1)
        {
            Console.Error.WriteLine("Usage: dialog-cli <command> [json]");
            Console.Error.WriteLine("Commands: confirm, choose, textInput, notify, preview, questions, pulse");
            return 1;
        }

        var command = args[0];
        var mgr = DialogManager.Shared;
        var clientName = Environment.GetEnvironmentVariable("MCP_CLIENT_NAME") ?? "MCP";
        mgr.SetClientName(clientName);

        var projectPath = Environment.GetEnvironmentVariable("MCP_PROJECT_PATH");
        if (!string.IsNullOrEmpty(projectPath))
            mgr.SetProjectPath(projectPath);

        var theme = Environment.GetEnvironmentVariable("DIALOG_THEME");
        if (!string.IsNullOrEmpty(theme))
            DialogCLI.Theme.DialogTheme.ApplyTheme(theme);

        // Load tray app settings (falls back to defaults if file missing)
        var settings = SettingsReader.Load();
        mgr.ApplySettings(settings);

        if (command == "pulse")
        {
            DialogManager.WriteJson(new { success = true });
            return 0;
        }

        if (args.Length < 2)
        {
            Console.Error.WriteLine("Usage: dialog-cli <command> <json>");
            return 1;
        }

        // Check snooze state (skip for notify/preview - those are fire-and-forget)
        if (command != "notify" && command != "preview")
        {
            var snooze = SettingsReader.GetSnoozeState();
            if (snooze is not null)
            {
                var remaining = (int)(snooze.SnoozeUntil!.Value - DateTime.UtcNow).TotalSeconds;
                SettingsReader.QueueSnoozedRequest(clientName, command, ExtractSummary(args[1]));
                WriteSnoozedResponse(command, remaining);
                return 0;
            }
        }

        var json = args[1];

        try
        {
            return command switch
            {
                "confirm" => mgr.RunDialog<ConfirmRequest, ConfirmResponse>(json, mgr.ShowConfirm),
                "choose" => mgr.RunDialog<ChooseRequest, ChoiceResponse>(json, mgr.ShowChoose),
                "textInput" => mgr.RunDialog<TextInputRequest, TextInputResponse>(json, mgr.ShowTextInput),
                "notify" => mgr.RunNotify(json),
                "preview" => mgr.RunPreview(json),
                "questions" => mgr.RunDialog<QuestionsRequest, QuestionsResponse>(json, mgr.ShowQuestions),
                _ => Error($"Unknown command: {command}"),
            };
        }
        catch (JsonException ex)
        {
            Console.Error.WriteLine($"Invalid JSON for '{command}': {ex.Message}");
            return 1;
        }
    }

    private static void WriteSnoozedResponse(string command, int remaining)
    {
        var instruction = SnoozeActiveInstruction(remaining);
        switch (command)
        {
            case "confirm":
                DialogManager.WriteJson(new ConfirmResponse { Snoozed = true, RemainingSeconds = remaining, Instruction = instruction });
                break;
            case "choose":
                DialogManager.WriteJson(new ChoiceResponse { Snoozed = true, RemainingSeconds = remaining, Instruction = instruction });
                break;
            case "textInput":
                DialogManager.WriteJson(new TextInputResponse { Snoozed = true, RemainingSeconds = remaining, Instruction = instruction });
                break;
            case "questions":
                DialogManager.WriteJson(new QuestionsResponse { Snoozed = true, RemainingSeconds = remaining, Instruction = instruction });
                break;
            default:
                DialogManager.WriteJson(new { snoozed = true, remainingSeconds = remaining, instruction });
                break;
        }
    }

    private static string SnoozeActiveInstruction(int remaining)
    {
        return $"Snooze active. Wait {remaining} seconds before re-asking.";
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

    private static int Error(string message)
    {
        Console.Error.WriteLine(message);
        return 1;
    }
}
