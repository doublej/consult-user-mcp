using System.Windows;
using System.Windows.Media;

namespace DialogCLI.Theme;

public static class DialogTheme
{
    // Colors
    public static readonly Color BackgroundColor = Color.FromRgb(30, 30, 30);
    public static readonly Color CardColor = Color.FromRgb(45, 45, 45);
    public static readonly Color CardHoverColor = Color.FromRgb(55, 55, 55);
    public static readonly Color TextColor = Color.FromRgb(230, 230, 230);
    public static readonly Color SecondaryTextColor = Color.FromRgb(160, 160, 160);
    public static readonly Color AccentColor = Color.FromRgb(59, 130, 246);
    public static readonly Color AccentHoverColor = Color.FromRgb(96, 165, 250);
    public static readonly Color BorderColor = Color.FromRgb(60, 60, 60);
    public static readonly Color SelectedColor = Color.FromRgb(59, 130, 246);
    public static readonly Color DangerColor = Color.FromRgb(239, 68, 68);

    // Brushes (cached)
    public static readonly SolidColorBrush BackgroundBrush = new(BackgroundColor);
    public static readonly SolidColorBrush CardBrush = new(CardColor);
    public static readonly SolidColorBrush CardHoverBrush = new(CardHoverColor);
    public static readonly SolidColorBrush TextBrush = new(TextColor);
    public static readonly SolidColorBrush SecondaryTextBrush = new(SecondaryTextColor);
    public static readonly SolidColorBrush AccentBrush = new(AccentColor);
    public static readonly SolidColorBrush AccentHoverBrush = new(AccentHoverColor);
    public static readonly SolidColorBrush BorderBrush = new(BorderColor);
    public static readonly SolidColorBrush TransparentBrush = Brushes.Transparent;

    // Sizing
    public const double MinWidth = 420;
    public const double MinHeight = 300;
    public const double MaxHeightRatio = 0.85;
    public const double CornerRadius = 12;
    public const double CardCornerRadius = 8;
    public const double Padding = 20;

    // Fonts
    public static readonly FontFamily FontFamily = new("Segoe UI");
    public const double TitleFontSize = 16;
    public const double BodyFontSize = 14;
    public const double SmallFontSize = 12;
    public const double HintFontSize = 11;
}
