using System.Diagnostics;
using System.Windows;
using System.Windows.Controls;
using ConsultUserMCP.Services;

namespace ConsultUserMCP.Settings;

public partial class ProjectsSettingsView : UserControl
{
    public ProjectsSettingsView()
    {
        InitializeComponent();
        Loaded += OnLoaded;
        Unloaded += OnUnloaded;
    }

    private void OnLoaded(object sender, RoutedEventArgs e)
    {
        ProjectManager.Shared.ProjectsChanged += RefreshList;
        RefreshList();
    }

    private void OnUnloaded(object sender, RoutedEventArgs e)
    {
        ProjectManager.Shared.ProjectsChanged -= RefreshList;
    }

    private void RefreshList()
    {
        Dispatcher.Invoke(() =>
        {
            var projects = ProjectManager.Shared.Projects;
            if (projects.Count == 0)
            {
                EmptyState.Visibility = Visibility.Visible;
                ProjectsScroll.Visibility = Visibility.Collapsed;
                ClearAllBtn.Visibility = Visibility.Collapsed;
            }
            else
            {
                EmptyState.Visibility = Visibility.Collapsed;
                ProjectsScroll.Visibility = Visibility.Visible;
                ClearAllBtn.Visibility = Visibility.Visible;
                ProjectsList.ItemsSource = null;
                ProjectsList.ItemsSource = projects;
            }
        });
    }

    private void OnOpenExplorer(object sender, RoutedEventArgs e)
    {
        if (sender is Button btn && btn.Tag is string path)
        {
            try { Process.Start("explorer.exe", path); }
            catch { }
        }
    }

    private void OnOpenTerminal(object sender, RoutedEventArgs e)
    {
        if (sender is Button btn && btn.Tag is string path)
        {
            try
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName = "cmd.exe",
                    Arguments = $"/K cd /d \"{path}\"",
                    UseShellExecute = true
                });
            }
            catch { }
        }
    }

    private void OnRemoveProject(object sender, RoutedEventArgs e)
    {
        if (sender is Button btn && btn.Tag is string path)
            ProjectManager.Shared.Remove(path);
    }

    private void OnClearAll(object sender, RoutedEventArgs e)
    {
        var result = MessageBox.Show(
            "Remove all projects from the list?",
            "Clear Projects",
            MessageBoxButton.YesNo,
            MessageBoxImage.Question
        );
        if (result == MessageBoxResult.Yes)
            ProjectManager.Shared.RemoveAll();
    }
}
