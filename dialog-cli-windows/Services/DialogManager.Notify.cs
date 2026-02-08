using System.Text.Json;
using System.Windows;
using DialogCLI.Dialogs;
using DialogCLI.Models;

namespace DialogCLI.Services;

public partial class DialogManager
{
    public int RunNotify(string json)
    {
        var request = JsonSerializer.Deserialize<NotifyRequest>(json, ReadOptions)
            ?? throw new JsonException("Deserialized to null");

        var app = new Application { ShutdownMode = ShutdownMode.OnExplicitShutdown };

        app.Startup += (_, _) =>
        {
            var window = new NotifyWindow(request, ClientName);
            window.Closed += (_, _) => app.Shutdown();
            window.Show();
        };

        app.Run();
        var result = new NotifyResponse { Success = true };
        WriteJson(result);
        HistoryManager.Record("notify", ClientName, request.Body, result);
        return 0;
    }
}
