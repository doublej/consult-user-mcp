using DialogCLI.Dialogs;
using DialogCLI.Models;

namespace DialogCLI.Services;

public partial class DialogManager
{
    public ConfirmResponse ShowConfirm(ConfirmRequest req, string clientName)
    {
        var dialog = new ConfirmDialog(req, clientName);
        PositionAndShow(dialog, req.Position);
        return dialog.Result;
    }
}
