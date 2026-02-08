using DialogCLI.Dialogs;
using DialogCLI.Models;

namespace DialogCLI.Services;

public partial class DialogManager
{
    public ChoiceResponse ShowChoose(ChooseRequest req, string clientName)
    {
        var dialog = new ChooseDialog(req, clientName);
        PositionAndShow(dialog, req.Position);
        return dialog.Result;
    }
}
