namespace DialogCLI.Models;

public enum DialogSize
{
    Compact,
    Regular,
    Large,
}

public static class DialogSizeExtensions
{
    public static double Scale(this DialogSize size) => size switch
    {
        DialogSize.Compact => 0.85,
        DialogSize.Large => 1.2,
        _ => 1.0,
    };
}
