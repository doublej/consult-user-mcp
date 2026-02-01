using System.Windows;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Shapes;
using DialogCLI.Theme;

namespace DialogCLI.Components;

/// <summary>
/// Base class for all dialog windows. Provides borderless, dark-themed, draggable window.
/// </summary>
public abstract class DialogBase : Window
{
    protected DialogBase()
    {
        WindowStyle = WindowStyle.None;
        AllowsTransparency = true;
        Background = Brushes.Transparent;
        ResizeMode = ResizeMode.NoResize;
        ShowInTaskbar = false;
        Topmost = true;
        FontFamily = DialogTheme.FontFamily;
        Width = DialogTheme.MinWidth;
        SizeToContent = SizeToContent.Height;

        // Allow dragging the window
        MouseLeftButtonDown += (_, e) =>
        {
            if (e.ChangedButton == MouseButton.Left)
                DragMove();
        };

        // Escape key closes dialog
        KeyDown += OnWindowKeyDown;
    }

    protected virtual void OnWindowKeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Escape)
        {
            OnCancelled();
            e.Handled = true;
        }
    }

    protected abstract void OnCancelled();

    /// <summary>
    /// Creates the outer rounded-rect border that wraps all dialog content.
    /// </summary>
    protected System.Windows.Controls.Border CreateOuterBorder()
    {
        return new System.Windows.Controls.Border
        {
            Background = DialogTheme.BackgroundBrush,
            CornerRadius = new CornerRadius(DialogTheme.CornerRadius),
            BorderBrush = DialogTheme.BorderBrush,
            BorderThickness = new Thickness(1),
            Padding = new Thickness(0),
            Effect = new System.Windows.Media.Effects.DropShadowEffect
            {
                BlurRadius = 20,
                ShadowDepth = 4,
                Opacity = 0.5,
                Color = Colors.Black,
            },
        };
    }
}
