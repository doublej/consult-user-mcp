using System.Windows;
using System.Windows.Controls;
using DialogCLI.Theme;

namespace DialogCLI.Components;

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

        var bodyBlock = new TextBlock
        {
            Text = body,
            FontSize = DialogTheme.BodyFontSize,
            Foreground = DialogTheme.SecondaryTextBrush,
            TextWrapping = TextWrapping.Wrap,
            LineHeight = 20,
        };
        panel.Children.Add(bodyBlock);

        return panel;
    }
}
