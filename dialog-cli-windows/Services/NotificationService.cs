using DialogCLI.Models;
using Microsoft.Toolkit.Uwp.Notifications;

namespace DialogCLI.Services;

public static class NotificationService
{
    public static NotifyResponse Show(NotifyRequest request, string clientName)
    {
        try
        {
            var builder = new ToastContentBuilder()
                .AddText(clientName)
                .AddText(request.Body);

            if (!request.Sound)
                builder.AddAudio(new ToastAudio { Silent = true });

            builder.Show();
            return new NotifyResponse { Success = true };
        }
        catch
        {
            return new NotifyResponse { Success = false };
        }
    }
}
