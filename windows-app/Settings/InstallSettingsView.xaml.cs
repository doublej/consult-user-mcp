using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using ConsultUserMCP.Models;
using ConsultUserMCP.Services;

namespace ConsultUserMCP.Settings;

public partial class InstallSettingsView : UserControl
{
    private readonly InstallAnswers _answers = new();
    private int _step; // 0=target, 1=basePrompt, 2=confirm
    private InstallResult? _result;

    public InstallSettingsView()
    {
        InitializeComponent();
        Loaded += (_, _) => RefreshTargetBadges();
    }

    // --- Target Selection ---

    private void OnSelectClaude(object sender, MouseButtonEventArgs e) => SelectTarget(InstallTarget.ClaudeDesktop);
    private void OnSelectClaudeCode(object sender, MouseButtonEventArgs e) => SelectTarget(InstallTarget.ClaudeCode);
    private void OnSelectCodex(object sender, MouseButtonEventArgs e) => SelectTarget(InstallTarget.Codex);

    private void SelectTarget(InstallTarget target)
    {
        _answers.Target = target;
        UpdateTargetCards();
    }

    private void UpdateTargetCards()
    {
        var selected = _answers.Target;
        SetCardState(CardClaude, RadioClaude, selected == InstallTarget.ClaudeDesktop);
        SetCardState(CardClaudeCode, RadioClaudeCode, selected == InstallTarget.ClaudeCode);
        SetCardState(CardCodex, RadioCodex, selected == InstallTarget.Codex);
    }

    private static void SetCardState(System.Windows.Controls.Border card,
        System.Windows.Shapes.Ellipse radio, bool active)
    {
        var accent = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#3B82F6"));
        var border = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#333"));

        card.BorderBrush = active ? accent : border;
        radio.Stroke = active ? accent : new SolidColorBrush((Color)ColorConverter.ConvertFromString("#555"));
        radio.Fill = active ? accent : Brushes.Transparent;
    }

    private void RefreshTargetBadges()
    {
        SetBadge(BadgeClaude, BadgeClaudeText, InstallTarget.ClaudeDesktop);
        SetBadge(BadgeClaudeCode, BadgeClaudeCodeText, InstallTarget.ClaudeCode);
        SetBadge(BadgeCodex, BadgeCodexText, InstallTarget.Codex);
        UpdateTargetCards();
    }

    private static void SetBadge(System.Windows.Controls.Border badge, TextBlock label, InstallTarget target)
    {
        if (MCPInstaller.IsConfigured(target))
        {
            if (target.SupportsBasePrompt() && BasePromptInstaller.IsUpdateAvailable(target))
            {
                badge.Visibility = Visibility.Visible;
                badge.Background = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#3A2A10"));
                label.Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#F59E0B"));
                label.Text = "Update available";
            }
            else
            {
                badge.Visibility = Visibility.Visible;
                badge.Background = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#1A3A1A"));
                label.Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#4ADE80"));
                label.Text = "Installed";
            }
        }
        else
        {
            badge.Visibility = Visibility.Collapsed;
        }
    }

    // --- Navigation ---

    private void OnNext(object sender, RoutedEventArgs e)
    {
        switch (_step)
        {
            case 0:
                if (_answers.Target.SupportsBasePrompt())
                {
                    PrepareBasePromptDefaults();
                    GoToStep(1);
                }
                else
                {
                    _answers.IncludeBasePrompt = false;
                    PrepareConfirmation();
                    GoToStep(2);
                }
                break;
            case 1:
                PrepareConfirmation();
                GoToStep(2);
                break;
        }
    }

    private void OnBack(object sender, RoutedEventArgs e)
    {
        switch (_step)
        {
            case 1:
                GoToStep(0);
                break;
            case 2:
                GoToStep(_answers.Target.SupportsBasePrompt() ? 1 : 0);
                break;
        }
    }

    private void OnStartOver(object sender, RoutedEventArgs e)
    {
        _answers.Target = InstallTarget.ClaudeCode;
        _answers.IncludeBasePrompt = true;
        _answers.BasePromptMode = BasePromptInstallMode.CreateNew;
        _result = null;
        RefreshTargetBadges();
        GoToStep(0);
    }

    private void GoToStep(int step)
    {
        _step = step;
        TargetStep.Visibility = step == 0 ? Visibility.Visible : Visibility.Collapsed;
        BasePromptStep.Visibility = step == 1 ? Visibility.Visible : Visibility.Collapsed;
        ConfirmStep.Visibility = step == 2 ? Visibility.Visible : Visibility.Collapsed;
        SummaryPanel.Visibility = _result is null ? Visibility.Visible : Visibility.Collapsed;
        ResultPanel.Visibility = _result is not null ? Visibility.Visible : Visibility.Collapsed;
        UpdateProgress();
    }

    private void UpdateProgress()
    {
        var accent = (Color)ColorConverter.ConvertFromString("#3B82F6");
        var dim = (Color)ColorConverter.ConvertFromString("#333");
        var textActive = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#E6E6E6"));
        var textDim = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#606060"));

        Step1Dot.Fill = new SolidColorBrush(_step >= 0 ? accent : dim);
        Step2Dot.Fill = new SolidColorBrush(_step >= 1 ? accent : dim);
        Step3Dot.Fill = new SolidColorBrush(_step >= 2 ? accent : dim);
        Step1Label.Foreground = _step >= 0 ? textActive : textDim;
        Step2Label.Foreground = _step >= 1 ? textActive : textDim;
        Step3Label.Foreground = _step >= 2 ? textActive : textDim;

        ProgressPanel.Visibility = _result is null ? Visibility.Visible : Visibility.Collapsed;
    }

    // --- Base Prompt Step ---

    private void PrepareBasePromptDefaults()
    {
        var target = _answers.Target;
        var fileName = target.BasePromptFileName() ?? "CLAUDE.md";
        BasePromptDescription.Text = $"Add instructions to {fileName} to help Claude use the MCP tools correctly.";

        if (BasePromptInstaller.DetectExisting(target))
        {
            var info = BasePromptInstaller.DetectInstalledInfo(target);
            FileStatusPanel.Visibility = Visibility.Visible;

            if (info is not null && BasePromptInstaller.IsUpdateAvailable(target))
            {
                FileStatusIcon.Text = "\u2B06"; // up arrow
                FileStatusIcon.Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#F59E0B"));
                FileStatusText.Text = $"Update available (v{info.Version} \u2192 v{BasePromptInstaller.BundledVersion})";
                FileStatusText.Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#F59E0B"));
                _answers.BasePromptMode = BasePromptInstallMode.Update;
            }
            else if (info is not null)
            {
                FileStatusIcon.Text = "\u2714"; // check
                FileStatusIcon.Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#4ADE80"));
                FileStatusText.Text = $"Usage hints installed (v{BasePromptInstaller.BundledVersion})";
                FileStatusText.Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#4ADE80"));
                _answers.BasePromptMode = BasePromptInstallMode.Skip;
            }
            else
            {
                FileStatusIcon.Text = "\u26A0"; // warning
                FileStatusIcon.Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#F59E0B"));
                FileStatusText.Text = $"{fileName} already exists";
                FileStatusText.Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#F59E0B"));
                _answers.BasePromptMode = BasePromptInstallMode.AppendSection;
            }

            RebuildModeOptions();
        }
        else
        {
            FileStatusPanel.Visibility = Visibility.Collapsed;
            ModeOptionsPanel.Visibility = Visibility.Collapsed;
            _answers.BasePromptMode = BasePromptInstallMode.CreateNew;
        }

        IncludeBasePromptCheck.IsChecked = _answers.IncludeBasePrompt;
        UpdateModeVisibility();
    }

    private void OnIncludeToggled(object sender, RoutedEventArgs e)
    {
        _answers.IncludeBasePrompt = IncludeBasePromptCheck.IsChecked == true;
        UpdateModeVisibility();
    }

    private void UpdateModeVisibility()
    {
        var showModes = _answers.IncludeBasePrompt
            && BasePromptInstaller.DetectExisting(_answers.Target);
        ModeOptionsPanel.Visibility = showModes ? Visibility.Visible : Visibility.Collapsed;
    }

    private void RebuildModeOptions()
    {
        ModeOptionsList.Children.Clear();
        var info = BasePromptInstaller.DetectInstalledInfo(_answers.Target);
        var updateAvailable = BasePromptInstaller.IsUpdateAvailable(_answers.Target);

        if (updateAvailable)
        {
            ModeOptionsTitle.Text = "UPDATE OPTIONS";
            AddModeOption(BasePromptInstallMode.Update, "Update hints", "Replace with latest version");
            AddModeOption(BasePromptInstallMode.Skip, "Keep existing", "Don't update usage hints");
        }
        else if (info is not null)
        {
            ModeOptionsTitle.Text = "EXISTING FILE";
            AddModeOption(BasePromptInstallMode.Skip, "Already installed", "Usage hints are up to date");
        }
        else
        {
            ModeOptionsTitle.Text = "EXISTING FILE";
            AddModeOption(BasePromptInstallMode.AppendSection, "Append section", "Add hints to existing file");
            AddModeOption(BasePromptInstallMode.Skip, "Skip", "Don't add usage hints");
        }
    }

    private void AddModeOption(BasePromptInstallMode mode, string title, string description)
    {
        var isSelected = _answers.BasePromptMode == mode;
        var accent = (Color)ColorConverter.ConvertFromString("#3B82F6");

        var border = new System.Windows.Controls.Border
        {
            Background = new SolidColorBrush(isSelected
                ? (Color)ColorConverter.ConvertFromString("#1E2A3A")
                : (Color)ColorConverter.ConvertFromString("#2A2A2A")),
            CornerRadius = new CornerRadius(6),
            BorderThickness = new Thickness(1),
            BorderBrush = new SolidColorBrush(isSelected ? accent : (Color)ColorConverter.ConvertFromString("#333")),
            Padding = new Thickness(12),
            Margin = new Thickness(0, 0, 0, 6),
            Cursor = Cursors.Hand,
        };

        var grid = new Grid();
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        var text = new StackPanel();
        text.Children.Add(new TextBlock
        {
            Text = title,
            Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#E6E6E6")),
            FontSize = 12,
            FontWeight = FontWeights.Medium,
            FontFamily = new FontFamily("Segoe UI"),
        });
        text.Children.Add(new TextBlock
        {
            Text = description,
            Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#808080")),
            FontSize = 10,
            FontFamily = new FontFamily("Segoe UI"),
            Margin = new Thickness(0, 2, 0, 0),
        });
        Grid.SetColumn(text, 0);
        grid.Children.Add(text);

        var radio = new System.Windows.Shapes.Ellipse
        {
            Width = 16,
            Height = 16,
            Stroke = new SolidColorBrush(isSelected ? accent : (Color)ColorConverter.ConvertFromString("#555")),
            StrokeThickness = 2,
            Fill = isSelected ? new SolidColorBrush(accent) : Brushes.Transparent,
            VerticalAlignment = VerticalAlignment.Center,
        };
        Grid.SetColumn(radio, 1);
        grid.Children.Add(radio);

        border.Child = grid;

        var capturedMode = mode;
        border.MouseLeftButtonDown += (_, _) =>
        {
            _answers.BasePromptMode = capturedMode;
            RebuildModeOptions();
        };

        ModeOptionsList.Children.Add(border);
    }

    // --- Confirmation Step ---

    private void PrepareConfirmation()
    {
        SummaryConfigPath.Text = _answers.Target.DisplayConfigPath();

        var showPrompt = _answers.Target.SupportsBasePrompt()
            && _answers.IncludeBasePrompt
            && _answers.BasePromptMode != BasePromptInstallMode.Skip;

        SummaryBasePromptPanel.Visibility = showPrompt ? Visibility.Visible : Visibility.Collapsed;
        if (showPrompt)
            SummaryBasePromptPath.Text = _answers.Target.DisplayBasePromptPath() ?? "";

        SummaryPanel.Visibility = Visibility.Visible;
        ResultPanel.Visibility = Visibility.Collapsed;
    }

    private void OnInstall(object sender, RoutedEventArgs e)
    {
        var mcpSuccess = false;
        try { mcpSuccess = MCPInstaller.ConfigureTarget(_answers.Target); }
        catch { /* handled below */ }

        var promptSuccess = true;
        string? promptError = null;
        if (_answers.Target.SupportsBasePrompt()
            && _answers.IncludeBasePrompt
            && _answers.BasePromptMode != BasePromptInstallMode.Skip)
        {
            try { BasePromptInstaller.Install(_answers.Target, _answers.BasePromptMode); }
            catch (Exception ex)
            {
                promptSuccess = false;
                promptError = ex.Message;
            }
        }

        _result = new InstallResult
        {
            McpConfigSuccess = mcpSuccess,
            BasePromptSuccess = promptSuccess,
            BasePromptError = promptError,
        };

        ShowResult();
    }

    private void ShowResult()
    {
        if (_result is null) return;

        SummaryPanel.Visibility = Visibility.Collapsed;
        ResultPanel.Visibility = Visibility.Visible;
        UpdateProgress();

        if (_result.IsFullySuccessful)
        {
            ResultBanner.Background = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#0A2A0A"));
            ResultIcon.Text = "\u2714";
            ResultIcon.Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#4ADE80"));
            ResultTitle.Text = "Installation Complete";
            ResultSubtitle.Text = $"Restart {_answers.Target.DisplayName()} to activate the MCP server.";
        }
        else
        {
            ResultBanner.Background = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#2A1A0A"));
            ResultIcon.Text = "\u26A0";
            ResultIcon.Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#F59E0B"));
            ResultTitle.Text = "Partial Installation";
            ResultSubtitle.Text = "Some items could not be installed. Check details below.";
        }

        ResultItems.Children.Clear();
        AddResultItem(_result.McpConfigSuccess, "MCP Configuration",
            _result.McpConfigSuccess ? "Installed" : "Failed");

        if (_answers.Target.SupportsBasePrompt()
            && _answers.IncludeBasePrompt
            && _answers.BasePromptMode != BasePromptInstallMode.Skip)
        {
            AddResultItem(_result.BasePromptSuccess, "Usage Hints",
                _result.BasePromptSuccess ? "Installed" : (_result.BasePromptError ?? "Failed"));
        }

        NextStepsText.Text = $"Restart {_answers.Target.DisplayName()} to load the MCP server";
    }

    private void AddResultItem(bool success, string title, string detail)
    {
        var panel = new StackPanel { Orientation = Orientation.Horizontal, Margin = new Thickness(0, 0, 0, 8) };

        panel.Children.Add(new TextBlock
        {
            Text = success ? "\u2714" : "\u2718",
            Foreground = new SolidColorBrush(success
                ? (Color)ColorConverter.ConvertFromString("#4ADE80")
                : (Color)ColorConverter.ConvertFromString("#EF4444")),
            FontSize = 14,
            Margin = new Thickness(0, 0, 10, 0),
            VerticalAlignment = VerticalAlignment.Center,
        });

        var text = new StackPanel();
        text.Children.Add(new TextBlock
        {
            Text = title,
            Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#E6E6E6")),
            FontSize = 13,
            FontWeight = FontWeights.Medium,
            FontFamily = new FontFamily("Segoe UI"),
        });
        text.Children.Add(new TextBlock
        {
            Text = detail,
            Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#808080")),
            FontSize = 11,
            FontFamily = new FontFamily("Segoe UI"),
        });
        panel.Children.Add(text);

        ResultItems.Children.Add(panel);
    }
}
