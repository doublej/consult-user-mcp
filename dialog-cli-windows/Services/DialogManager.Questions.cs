using DialogCLI.Components;
using DialogCLI.Dialogs;
using DialogCLI.Models;

namespace DialogCLI.Services;

public partial class DialogManager
{
    public QuestionsResponse ShowQuestions(QuestionsRequest req, string clientName)
    {
        DialogBase dialog = req.Mode == "accordion"
            ? new AccordionDialog(req, clientName)
            : new WizardDialog(req, clientName);

        PositionAndShow(dialog, req.Position);
        return req.Mode == "accordion"
            ? ((AccordionDialog)dialog).Result
            : ((WizardDialog)dialog).Result;
    }
}
