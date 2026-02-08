using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Threading;
using DialogCLI.Components;
using DialogCLI.Models;
using DialogCLI.Services;
using DialogCLI.Theme;

namespace DialogCLI.Dialogs;

public class NotifyWindow : Window
{
    public NotifyWindow(NotifyRequest request, string clientName)
    {
        WindowStyle = WindowStyle.None;
        AllowsTransparency = true;
        Background = Brushes.Transparent;
        ResizeMode = ResizeMode.NoResize;
        ShowInTaskbar = false;
        Topmost = true;
        FontFamily = DialogTheme.FontFamily;
        SizeToContent = SizeToContent.Height;
        Width = 320;

        BuildUI(request, clientName);
        PositionTopRight();
        StartAutoClose();

        MouseLeftButtonDown += (_, _) => Close();
    }

    private void BuildUI(NotifyRequest request, string clientName)
    {
        var outer = new Border
        {
            Background = DialogTheme.BackgroundBrush,
            CornerRadius = new CornerRadius(DialogTheme.CornerRadius),
            BorderBrush = DialogTheme.BorderBrush,
            BorderThickness = new Thickness(1),
            Padding = new Thickness(16),
            Effect = new System.Windows.Media.Effects.DropShadowEffect
            {
                BlurRadius = 20,
                ShadowDepth = 4,
                Opacity = 0.5,
                Color = Colors.Black,
            },
        };

        var stack = new StackPanel();

        stack.Children.Add(new TextBlock
        {
            Text = clientName,
            FontSize = DialogTheme.SmallFontSize,
            Foreground = DialogTheme.SecondaryTextBrush,
            Margin = new Thickness(0, 0, 0, 4),
        });

        var badge = ProjectBadge.Create();
        if (badge != null)
            stack.Children.Add(badge);

        stack.Children.Add(new TextBlock
        {
            Text = request.Body,
            FontSize = DialogTheme.BodyFontSize,
            Foreground = DialogTheme.TextBrush,
            TextWrapping = TextWrapping.Wrap,
            LineHeight = 20,
        });

        outer.Child = stack;
        Content = outer;
    }

    private void PositionTopRight()
    {
        Loaded += (_, _) =>
        {
            var workArea = SystemParameters.WorkArea;
            Left = workArea.Right - Width - 20;
            Top = workArea.Top + 20;
            if (request.Sound)
                SoundPlayer.PlayDialogSound();
        };
    }

    private void StartAutoClose()
    {
        var timer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(4) };
        timer.Tick += (_, _) => { timer.Stop(); Close(); };
        timer.Start();
    }
}
