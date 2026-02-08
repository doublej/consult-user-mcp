using System.Media;

namespace DialogCLI.Services;

public static class SoundPlayer
{
    public static void PlayDialogSound()
    {
        try
        {
            SystemSounds.Asterisk.Play();
        }
        catch
        {
            // Silently ignore sound playback failures
        }
    }
}
