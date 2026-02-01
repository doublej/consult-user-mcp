using System.Windows;
using System.Windows.Forms;
using DialogCLI.Models;

namespace DialogCLI.Services;

public static class WindowPositioner
{
    public static void Position(Window window, DialogPosition position)
    {
        var screen = Screen.PrimaryScreen?.WorkingArea
            ?? new System.Drawing.Rectangle(0, 0, 1920, 1080);

        var dpi = GetDpiScale(window);
        var screenWidth = screen.Width / dpi;
        var screenHeight = screen.Height / dpi;
        var screenLeft = screen.Left / dpi;
        var screenTop = screen.Top / dpi;

        double x = position switch
        {
            DialogPosition.Left => screenLeft + 40,
            DialogPosition.Right => screenLeft + screenWidth - window.Width - 40,
            _ => screenLeft + (screenWidth - window.Width) / 2,
        };

        double y = screenTop + 80;

        window.Left = x;
        window.Top = y;
    }

    private static double GetDpiScale(Window window)
    {
        var source = PresentationSource.FromVisual(window);
        return source?.CompositionTarget?.TransformToDevice.M11 ?? 1.0;
    }
}
