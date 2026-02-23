using System.Diagnostics;
using System.Windows;
using System.Windows.Controls;
using ConsultUserMCP.Services;

namespace ConsultUserMCP.Settings;

public partial class UninstallSettingsView : UserControl
{
    public UninstallSettingsView()
    {
        InitializeComponent();
        RefreshRemovalList();
    }

    private void RefreshRemovalList()
    {
        var keepData = KeepDataCheck.IsChecked == true;
        RemovalList.ItemsSource = UninstallManager.GetRemovalList(keepData);
    }

    private void OnKeepDataChanged(object sender, RoutedEventArgs e)
    {
        RefreshRemovalList();
    }

    private void OnUninstallClick(object sender, RoutedEventArgs e)
    {
        var result = MessageBox.Show(
            "This will remove the app and all MCP configurations. This cannot be undone.\n\n" +
            "After cleanup, the app will close. Use 'Add or Remove Programs' to complete the uninstall.",
            "Uninstall Consult User MCP?",
            MessageBoxButton.YesNo,
            MessageBoxImage.Warning);

        if (result != MessageBoxResult.Yes)
            return;

        var keepData = KeepDataCheck.IsChecked == true;
        UninstallManager.RunFastCleanup(keepData);

        MessageBox.Show(
            "MCP configurations have been removed.\n\n" +
            "To complete the uninstall, open 'Add or Remove Programs' and uninstall 'Consult User MCP'.",
            "Cleanup Complete",
            MessageBoxButton.OK,
            MessageBoxImage.Information);

        Application.Current.Shutdown();
    }
}
