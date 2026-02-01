using System.Text.Json;
using System.Text.Json.Serialization;
using System.Windows;
using DialogCLI.Components;
using DialogCLI.Dialogs;
using DialogCLI.Models;
using DialogCLI.Services;

namespace DialogCLI;

public static class Program
{
    private static readonly JsonSerializerOptions ReadOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) },
    };

    private static readonly JsonSerializerOptions WriteOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
        Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) },
    };

    [STAThread]
    public static int Main(string[] args)
    {
        if (args.Length > 0 && args[0] is "--version" or "-v")
        {
            Console.WriteLine("dialog-cli-windows 0.1.0");
            return 0;
        }

        if (args.Length < 1)
        {
            Console.Error.WriteLine("Usage: dialog-cli-windows <command> [json]");
            Console.Error.WriteLine("Commands: confirm, choose, textInput, notify, questions, pulse");
            return 1;
        }

        var command = args[0];
        var clientName = Environment.GetEnvironmentVariable("MCP_CLIENT_NAME") ?? "MCP";

        // Pulse: no JSON needed
        if (command == "pulse")
        {
            WriteJson(new { success = true });
            return 0;
        }

        if (args.Length < 2)
        {
            Console.Error.WriteLine("Usage: dialog-cli-windows <command> <json>");
            return 1;
        }

        var json = args[1];

        try
        {
            return command switch
            {
                "confirm" => RunDialog<ConfirmRequest, ConfirmResponse>(json, clientName, ShowConfirm),
                "choose" => RunDialog<ChooseRequest, ChoiceResponse>(json, clientName, ShowChoose),
                "textInput" => RunDialog<TextInputRequest, TextInputResponse>(json, clientName, ShowTextInput),
                "notify" => RunNotify(json, clientName),
                "questions" => RunDialog<QuestionsRequest, QuestionsResponse>(json, clientName, ShowQuestions),
                _ => Error($"Unknown command: {command}"),
            };
        }
        catch (JsonException ex)
        {
            Console.Error.WriteLine($"Invalid JSON for '{command}': {ex.Message}");
            return 1;
        }
    }

    private static int RunDialog<TReq, TRes>(string json, string clientName, Func<TReq, string, TRes> showDialog)
    {
        var request = JsonSerializer.Deserialize<TReq>(json, ReadOptions)
            ?? throw new JsonException("Deserialized to null");

        // WPF requires an Application instance
        var app = new Application { ShutdownMode = ShutdownMode.OnExplicitShutdown };
        TRes? result = default;

        app.Startup += (_, _) =>
        {
            result = showDialog(request, clientName);
            app.Shutdown();
        };

        app.Run();
        WriteJson(result!);
        return 0;
    }

    private static ConfirmResponse ShowConfirm(ConfirmRequest req, string clientName)
    {
        var dialog = new ConfirmDialog(req, clientName);
        PositionAndShow(dialog, req.Position);
        return dialog.Result;
    }

    private static ChoiceResponse ShowChoose(ChooseRequest req, string clientName)
    {
        var dialog = new ChooseDialog(req, clientName);
        PositionAndShow(dialog, req.Position);
        return dialog.Result;
    }

    private static TextInputResponse ShowTextInput(TextInputRequest req, string clientName)
    {
        var dialog = new TextInputDialog(req, clientName);
        PositionAndShow(dialog, req.Position);
        return dialog.Result;
    }

    private static QuestionsResponse ShowQuestions(QuestionsRequest req, string clientName)
    {
        DialogBase dialog = req.Mode == "accordion"
            ? new AccordionDialog(req, clientName)
            : new WizardDialog(req, clientName);

        PositionAndShow(dialog, req.Position);
        return req.Mode == "accordion"
            ? ((AccordionDialog)dialog).Result
            : ((WizardDialog)dialog).Result;
    }

    private static void PositionAndShow(DialogBase dialog, DialogPosition position)
    {
        dialog.Loaded += (_, _) => WindowPositioner.Position(dialog, position);
        dialog.ShowDialog();
    }

    private static int RunNotify(string json, string clientName)
    {
        var request = JsonSerializer.Deserialize<NotifyRequest>(json, ReadOptions)
            ?? throw new JsonException("Deserialized to null");

        var result = NotificationService.Show(request, clientName);
        WriteJson(result);
        return 0;
    }

    private static void WriteJson<T>(T value)
    {
        Console.WriteLine(JsonSerializer.Serialize(value, WriteOptions));
    }

    private static int Error(string message)
    {
        Console.Error.WriteLine(message);
        return 1;
    }
}
