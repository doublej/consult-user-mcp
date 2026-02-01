using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using DialogCLI.Components;
using DialogCLI.Models;
using DialogCLI.Theme;

namespace DialogCLI.Dialogs;

public class ConfirmDialog : DialogBase
{
    public ConfirmResponse Result { get; private set; }

    private readonly ConfirmRequest _request;

    public ConfirmDialog(ConfirmRequest request, string clientName)
    {
        _request = request;
        Result = new ConfirmResponse { Dismissed = true };
        BuildUI(clientName);
    }

    private void BuildUI(string clientName)
    {
        var outer = CreateOuterBorder();
        var stack = new StackPanel();

        stack.Children.Add(DialogHeader.Create(_request.Title, _request.Body));

        stack.Children.Add(DialogFooter.Create(
            new FooterButton(_request.CancelLabel, false, () =>
            {
                Result = new ConfirmResponse
                {
                    Confirmed = false,
                    Cancelled = true,
                    Answer = _request.CancelLabel,
                };
                Close();
            }),
            new FooterButton(_request.ConfirmLabel, true, Confirm)
        ));

        outer.Child = stack;
        Content = outer;
    }

    protected override void OnWindowPreviewKeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Enter)
        {
            Confirm();
            e.Handled = true;
            return;
        }
        base.OnWindowPreviewKeyDown(sender, e);
    }

    protected override void OnCancelled()
    {
        Result = new ConfirmResponse
        {
            Confirmed = false,
            Cancelled = true,
            Answer = _request.CancelLabel,
        };
        Close();
    }

    private void Confirm()
    {
        Result = new ConfirmResponse
        {
            Confirmed = true,
            Answer = _request.ConfirmLabel,
        };
        Close();
    }
}
