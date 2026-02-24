using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using DialogCLI.Theme;

namespace DialogCLI.Components;

public record FooterButton(string Label, bool IsPrimary, Action OnClick);

public static class ProjectBadge
{
    public static FrameworkElement? Create()
    {
        var path = Services.DialogManager.Shared.ProjectPath;
        if (string.IsNullOrEmpty(path))
            return null;

        var folderName = System.IO.Path.GetFileName(path.TrimEnd('/', '\\'));
        if (string.IsNullOrEmpty(folderName))
            return null;

        var text = new TextBlock
        {
            Text = $"\uD83D\uDCC1 {folderName}",
            FontSize = DialogTheme.SmallFontSize,
            Foreground = DialogTheme.SecondaryTextBrush,
        };

        return new Border
        {
            Child = text,
            Background = new SolidColorBrush(Color.FromArgb(40, 255, 255, 255)),
            CornerRadius = new CornerRadius(4),
            Padding = new Thickness(8, 3, 8, 3),
            Margin = new Thickness(0, 0, 0, 8),
            HorizontalAlignment = HorizontalAlignment.Left,
        };
    }
}

public static class DialogHeader
{
    public static StackPanel Create(string title, string body)
    {
        var panel = new StackPanel { Margin = new Thickness(DialogTheme.Padding, DialogTheme.Padding, DialogTheme.Padding, 12) };

        var titleBlock = new TextBlock
        {
            Text = title,
            FontSize = DialogTheme.TitleFontSize,
            FontWeight = FontWeights.SemiBold,
            Foreground = DialogTheme.TextBrush,
            TextWrapping = TextWrapping.Wrap,
            Margin = new Thickness(0, 0, 0, 8),
        };
        panel.Children.Add(titleBlock);

        var badge = ProjectBadge.Create();
        if (badge != null)
            panel.Children.Add(badge);

        if (!string.IsNullOrEmpty(body))
        {
            var bodyBlock = SelectableMarkdownText.Create(body, DialogTheme.BodyFontSize, DialogTheme.SecondaryTextBrush);
            panel.Children.Add(bodyBlock);
        }

        return panel;
    }
}

public static class DialogFooter
{
    public static StackPanel Create(params FooterButton[] buttons)
        => Create("Esc to cancel \u2022 Enter to confirm", buttons);

    public static StackPanel Create(string hintText, params FooterButton[] buttons)
    {
        var panel = new StackPanel
        {
            Margin = new Thickness(DialogTheme.Padding, 8, DialogTheme.Padding, DialogTheme.Padding),
        };

        var hints = new TextBlock
        {
            Text = hintText,
            FontSize = DialogTheme.HintFontSize,
            Foreground = DialogTheme.SecondaryTextBrush,
            HorizontalAlignment = HorizontalAlignment.Center,
            Margin = new Thickness(0, 0, 0, 10),
        };
        panel.Children.Add(hints);

        var buttonPanel = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            HorizontalAlignment = HorizontalAlignment.Right,
        };

        foreach (var btn in buttons)
        {
            var button = CreateButton(btn.Label, btn.IsPrimary);
            button.IsTabStop = false;
            button.Click += (_, _) => btn.OnClick();
            buttonPanel.Children.Add(button);
        }

        panel.Children.Add(buttonPanel);
        return panel;
    }

    private static Button CreateButton(string label, bool isPrimary)
    {
        var button = new Button
        {
            Content = label,
            MinWidth = 80,
            Height = 36,
            Margin = new Thickness(6, 0, 0, 0),
            Padding = new Thickness(16, 0, 16, 0),
            FontSize = DialogTheme.BodyFontSize,
            FontWeight = isPrimary ? FontWeights.SemiBold : FontWeights.Normal,
            Cursor = Cursors.Hand,
            BorderThickness = new Thickness(1),
        };

        if (isPrimary)
        {
            button.Background = DialogTheme.AccentBrush;
            button.Foreground = Brushes.White;
            button.BorderBrush = DialogTheme.AccentBrush;
        }
        else
        {
            button.Background = DialogTheme.CardBrush;
            button.Foreground = DialogTheme.TextBrush;
            button.BorderBrush = DialogTheme.BorderBrush;
        }

        // Hover effects
        button.MouseEnter += (_, _) =>
        {
            button.Background = isPrimary
                ? DialogTheme.AccentHoverBrush
                : DialogTheme.CardHoverBrush;
        };
        button.MouseLeave += (_, _) =>
        {
            button.Background = isPrimary
                ? DialogTheme.AccentBrush
                : DialogTheme.CardBrush;
        };

        // Remove default button chrome
        button.FocusVisualStyle = null;
        button.Template = CreateButtonTemplate(isPrimary);

        return button;
    }

    private static ControlTemplate CreateButtonTemplate(bool isPrimary)
    {
        var template = new ControlTemplate(typeof(Button));
        var border = new FrameworkElementFactory(typeof(Border));
        border.Name = "border";
        border.SetBinding(Border.BackgroundProperty, new System.Windows.Data.Binding("Background") { RelativeSource = System.Windows.Data.RelativeSource.TemplatedParent });
        border.SetBinding(Border.BorderBrushProperty, new System.Windows.Data.Binding("BorderBrush") { RelativeSource = System.Windows.Data.RelativeSource.TemplatedParent });
        border.SetBinding(Border.BorderThicknessProperty, new System.Windows.Data.Binding("BorderThickness") { RelativeSource = System.Windows.Data.RelativeSource.TemplatedParent });
        border.SetValue(Border.CornerRadiusProperty, new CornerRadius(6));
        border.SetValue(Border.PaddingProperty, new Thickness(0));

        var presenter = new FrameworkElementFactory(typeof(ContentPresenter));
        presenter.SetValue(ContentPresenter.HorizontalAlignmentProperty, HorizontalAlignment.Center);
        presenter.SetValue(ContentPresenter.VerticalAlignmentProperty, VerticalAlignment.Center);
        border.AppendChild(presenter);

        template.VisualTree = border;
        return template;
    }
}
