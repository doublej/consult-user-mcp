using System.Text.Json;
using System.Windows;
using DialogCLI.Dialogs;
using DialogCLI.Models;

namespace DialogCLI.Services;

public partial class DialogManager
{
    public int RunPreview(string json)
    {
        var request = JsonSerializer.Deserialize<PreviewRequest>(json, ReadOptions)
            ?? throw new JsonException("Deserialized to null");

        var app = new Application { ShutdownMode = ShutdownMode.OnExplicitShutdown };

        app.Startup += (_, _) =>
        {
            var window = new PreviewWindow(request, ClientName);
            window.Closed += (_, _) => app.Shutdown();
            window.Show();
        };

        app.Run();
        var result = new PreviewResponse { Success = true };
        WriteJson(result);
        return 0;
    }
}
