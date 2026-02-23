using Velopack;

namespace ConsultUserMCP;

public static class Program
{
    [STAThread]
    public static void Main(string[] args)
    {
        VelopackApp.Build()
            .OnFirstRun(v => Services.MCPInstaller.Configure())
            .OnBeforeUninstallFastCallback(v => Services.UninstallManager.RunFastCleanup())
            .Run();

        var app = new App();
        app.InitializeComponent();
        app.Run();
    }
}
