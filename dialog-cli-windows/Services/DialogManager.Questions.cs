using DialogCLI.Components;
using DialogCLI.Dialogs;
using DialogCLI.Models;

namespace DialogCLI.Services;

public partial class DialogManager
{
    public QuestionsResponse ShowQuestions(QuestionsRequest req, string clientName)
    {
        var dialog = new WizardDialog(req, clientName);

        PositionAndShow(dialog, req.Position);
        return dialog.Result;
    }
}
