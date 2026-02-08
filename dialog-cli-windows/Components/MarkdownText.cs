using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Documents;
using System.Windows.Media;
using DialogCLI.Theme;

namespace DialogCLI.Components;

public static class MarkdownText
{
    public static TextBlock Create(string text, double fontSize, Brush foreground)
    {
        var textBlock = new TextBlock
        {
            FontSize = fontSize,
            Foreground = foreground,
            TextWrapping = TextWrapping.Wrap,
            LineHeight = 20,
        };

        ParseInlines(text, textBlock.Inlines);
        return textBlock;
    }

    private static void ParseInlines(string text, InlineCollection inlines)
    {
        // Pattern matches: **bold**, *italic*, `code`, [text](url)
        var pattern = @"(\*\*(.+?)\*\*)|(\*(.+?)\*)|(`(.+?)`)|(\[(.+?)\]\((.+?)\))";
        int lastIndex = 0;

        foreach (Match match in Regex.Matches(text, pattern))
        {
            if (match.Index > lastIndex)
                inlines.Add(new Run(text[lastIndex..match.Index]));

            if (match.Groups[1].Success) // **bold**
            {
                inlines.Add(new Bold(new Run(match.Groups[2].Value)));
            }
            else if (match.Groups[3].Success) // *italic*
            {
                inlines.Add(new Italic(new Run(match.Groups[4].Value)));
            }
            else if (match.Groups[5].Success) // `code`
            {
                inlines.Add(new Run(match.Groups[6].Value)
                {
                    FontFamily = new FontFamily("Consolas"),
                    Background = new SolidColorBrush(Color.FromArgb(60, 255, 255, 255)),
                });
            }
            else if (match.Groups[7].Success) // [text](url)
            {
                var link = new Hyperlink(new Run(match.Groups[8].Value))
                {
                    NavigateUri = new Uri(match.Groups[9].Value, UriKind.Absolute),
                    Foreground = DialogTheme.AccentBrush,
                    TextDecorations = null,
                };
                link.RequestNavigate += (_, e) =>
                {
                    System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
                    {
                        FileName = e.Uri.AbsoluteUri,
                        UseShellExecute = true,
                    });
                    e.Handled = true;
                };
                inlines.Add(link);
            }

            lastIndex = match.Index + match.Length;
        }

        if (lastIndex < text.Length)
            inlines.Add(new Run(text[lastIndex..]));
    }
}
