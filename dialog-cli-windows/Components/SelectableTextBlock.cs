using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace DialogCLI.Components;

public static class SelectableTextBlock
{
    public static TextBox Create(string text, double fontSize, Brush foreground)
    {
        return new TextBox
        {
            Text = text,
            IsReadOnly = true,
            BorderThickness = new Thickness(0),
            Background = Brushes.Transparent,
            Foreground = foreground,
            FontSize = fontSize,
            TextWrapping = TextWrapping.Wrap,
            Padding = new Thickness(0),
            IsTabStop = false,
            Cursor = System.Windows.Input.Cursors.IBeam,
        };
    }

    public static TextBox Create(string text, double fontSize, Brush foreground, Thickness margin)
    {
        var textBox = Create(text, fontSize, foreground);
        textBox.Margin = margin;
        return textBox;
    }
}
