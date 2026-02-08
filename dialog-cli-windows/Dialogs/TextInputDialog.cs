using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using DialogCLI.Components;
using DialogCLI.Models;
using DialogCLI.Theme;

namespace DialogCLI.Dialogs;

public class TextInputDialog : DialogBase
{
    public TextInputResponse Result { get; private set; }

    private readonly TextInputRequest _request;
    private readonly Control _inputField;

    public TextInputDialog(TextInputRequest request, string clientName)
    {
        _request = request;
        Result = new TextInputResponse { Dismissed = true };

        if (request.Hidden)
        {
            var pw = new PasswordBox
            {
                Password = request.DefaultValue,
                FontSize = DialogTheme.BodyFontSize,
                Foreground = DialogTheme.TextBrush,
                Background = DialogTheme.CardBrush,
                BorderBrush = DialogTheme.BorderBrush,
                BorderThickness = new Thickness(1),
                Padding = new Thickness(10, 8, 10, 8),
                CaretBrush = DialogTheme.TextBrush,
            };
            _inputField = pw;
        }
        else
        {
            var tb = new TextBox
            {
                Text = request.DefaultValue,
                FontSize = DialogTheme.BodyFontSize,
                Foreground = DialogTheme.TextBrush,
                Background = DialogTheme.CardBrush,
                BorderBrush = DialogTheme.BorderBrush,
                BorderThickness = new Thickness(1),
                Padding = new Thickness(10, 8, 10, 8),
                CaretBrush = DialogTheme.TextBrush,
                AcceptsReturn = false,
            };
            tb.SelectAll();
            _inputField = tb;
        }

        BuildUI(clientName);
    }

    private void BuildUI(string clientName)
    {
        var outer = CreateOuterBorder();
        var stack = new StackPanel();

        stack.Children.Add(DialogHeader.Create(_request.Title, _request.Body));

        // Input field
        _inputField.Margin = new Thickness(DialogTheme.Padding, 0, DialogTheme.Padding, 12);
        stack.Children.Add(_inputField);

        stack.Children.Add(DialogFooter.Create(
            new FooterButton("Cancel", false, () =>
            {
                Result = new TextInputResponse { Cancelled = true };
                Close();
            }),
            new FooterButton("Submit", true, Submit)
        ));

        outer.Child = stack;
        Content = outer;

        // Focus input after loading
        Loaded += (_, _) =>
        {
            _inputField.Focus();
            if (_inputField is TextBox tb)
                tb.SelectAll();
        };
    }

    protected override void OnWindowPreviewKeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Enter)
        {
            Submit();
            e.Handled = true;
            return;
        }
        base.OnWindowPreviewKeyDown(sender, e);
    }

    protected override void OnCancelled()
    {
        Result = new TextInputResponse { Cancelled = true, Dismissed = true };
        Close();
    }

    private void Submit()
    {
        var text = _inputField switch
        {
            TextBox tb => tb.Text,
            PasswordBox pb => pb.Password,
            _ => "",
        };

        Result = new TextInputResponse { Answer = text };
        Close();
    }
}
