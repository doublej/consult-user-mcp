using DialogCLI.Dialogs;
using DialogCLI.Models;

namespace DialogCLI.Services;

public partial class DialogManager
{
    public TextInputResponse ShowTextInput(TextInputRequest req, string clientName)
    {
        var dialog = new TextInputDialog(req, clientName);
        PositionAndShow(dialog, req.Position);
        return dialog.Result;
    }
}
