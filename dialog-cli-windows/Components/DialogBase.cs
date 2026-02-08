using System.Windows;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Shapes;
using DialogCLI.Models;
using DialogCLI.Services;
using DialogCLI.Theme;

namespace DialogCLI.Components;

/// <summary>
/// Base class for all dialog windows. Provides borderless, dark-themed, draggable window.
/// </summary>
public abstract class DialogBase : Window
{
    protected readonly CooldownManager Cooldown = new();

    protected DialogBase()
    {
        WindowStyle = WindowStyle.None;
        AllowsTransparency = true;
        Background = Brushes.Transparent;
        ResizeMode = ResizeMode.NoResize;
        ShowInTaskbar = false;
        FontFamily = DialogTheme.FontFamily;
        SizeToContent = SizeToContent.Height;

        // Apply tray app settings if available
        var settings = Services.DialogManager.Shared.AppSettings;
        Topmost = settings?.AlwaysOnTop ?? true;
        var scale = settings?.Size.Scale() ?? 1.0;
        Width = DialogTheme.MinWidth * scale;

        // Allow dragging the window
        MouseLeftButtonDown += (_, e) =>
        {
            if (e.ChangedButton == MouseButton.Left)
                DragMove();
        };

        // Tunneling phase — fires before WPF buttons consume Enter/Space
        PreviewKeyDown += OnWindowPreviewKeyDown;

        // Block input briefly after dialog appears to prevent accidental keypresses
        Loaded += (_, _) =>
        {
            Cooldown.Start(2.0);
            SoundPlayer.PlayDialogSound();
        };
    }

    protected virtual void OnWindowPreviewKeyDown(object sender, KeyEventArgs e)
    {
        if (Cooldown.IsCoolingDown) { e.Handled = true; return; }
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
