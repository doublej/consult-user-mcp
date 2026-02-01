using System.Windows;
using DialogCLI.Models;

namespace DialogCLI.Services;

public static class WindowPositioner
{
    public static void Position(Window window, DialogPosition position)
    {
        var workArea = SystemParameters.WorkArea;

        var dpi = GetDpiScale(window);
        var screenWidth = workArea.Width;
        var screenHeight = workArea.Height;
        var screenLeft = workArea.Left;
        var screenTop = workArea.Top;

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
