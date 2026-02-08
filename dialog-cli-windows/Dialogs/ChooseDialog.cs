using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using DialogCLI.Components;
using DialogCLI.Models;
using DialogCLI.Theme;

namespace DialogCLI.Dialogs;

public class ChooseDialog : DialogBase
{
    public ChoiceResponse Result { get; private set; }

    private readonly ChooseRequest _request;
    private readonly HashSet<int> _selected = new();
    private readonly List<Border> _cards = new();
    private int _focusedIndex;

    public ChooseDialog(ChooseRequest request, string clientName)
    {
        _request = request;
        Result = new ChoiceResponse { Dismissed = true };
        MaxHeight = SystemParameters.PrimaryScreenHeight * DialogTheme.MaxHeightRatio;

        if (request.DefaultSelection is not null)
        {
            var idx = Array.IndexOf(request.Choices, request.DefaultSelection);
            if (idx >= 0) _selected.Add(idx);
        }

        BuildUI(clientName);
    }

    private void BuildUI(string clientName)
    {
        var outer = CreateOuterBorder();
        var stack = new StackPanel();

        stack.Children.Add(DialogHeader.Create(_request.Body, ""));

        var scrollViewer = new ScrollViewer
        {
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            MaxHeight = 400,
            Margin = new Thickness(DialogTheme.Padding, 0, DialogTheme.Padding, 0),
        };

        var choicesPanel = new StackPanel();
        for (int i = 0; i < _request.Choices.Length; i++)
        {
            var card = CreateChoiceCard(i);
            _cards.Add(card);
            choicesPanel.Children.Add(card);
        }
        scrollViewer.Content = choicesPanel;
        stack.Children.Add(scrollViewer);

        var hint = _request.AllowMultiple
            ? "\u2191\u2193 navigate \u2022 Space select \u2022 Enter done"
            : "\u2191\u2193 navigate \u2022 Enter confirm";
        stack.Children.Add(DialogFooter.Create(hint,
            new FooterButton("Cancel", false, () =>
            {
                Result = new ChoiceResponse { Cancelled = true };
                Close();
            }),
            new FooterButton("Done", true, Complete)
        ));

        outer.Child = stack;
        Content = outer;
        UpdateVisuals();
    }

    private Border CreateChoiceCard(int index)
    {
        var label = _request.Choices[index];
        var desc = _request.Descriptions is not null && index < _request.Descriptions.Length
            ? _request.Descriptions[index]
            : null;

        var textStack = new StackPanel { Margin = new Thickness(12, 10, 12, 10) };
        textStack.Children.Add(new TextBlock
        {
            Text = label,
            FontSize = DialogTheme.BodyFontSize,
            Foreground = DialogTheme.TextBrush,
            TextWrapping = TextWrapping.Wrap,
        });

        if (!string.IsNullOrEmpty(desc))
        {
            textStack.Children.Add(new TextBlock
            {
                Text = desc,
                FontSize = DialogTheme.SmallFontSize,
                Foreground = DialogTheme.SecondaryTextBrush,
                TextWrapping = TextWrapping.Wrap,
                Margin = new Thickness(0, 4, 0, 0),
            });
        }

        var border = new Border
        {
            Child = textStack,
            Background = DialogTheme.CardBrush,
            CornerRadius = new CornerRadius(DialogTheme.CardCornerRadius),
            BorderThickness = new Thickness(2),
            BorderBrush = DialogTheme.TransparentBrush,
            Margin = new Thickness(0, 0, 0, 6),
            Cursor = Cursors.Hand,
        };

        border.MouseLeftButtonDown += (_, _) => ToggleSelection(index);
        border.MouseEnter += (_, _) =>
        {
            if (!_selected.Contains(index))
                border.Background = DialogTheme.CardHoverBrush;
        };
        border.MouseLeave += (_, _) =>
        {
            if (!_selected.Contains(index))
                border.Background = DialogTheme.CardBrush;
        };

        return border;
    }

    private void ToggleSelection(int index)
    {
        if (_request.AllowMultiple)
        {
            if (!_selected.Remove(index))
                _selected.Add(index);
        }
        else
        {
            _selected.Clear();
            _selected.Add(index);
        }
        _focusedIndex = index;
        UpdateVisuals();
    }

    private void UpdateVisuals()
    {
        for (int i = 0; i < _cards.Count; i++)
        {
            var isSelected = _selected.Contains(i);
            var isFocused = i == _focusedIndex;

            if (isSelected)
            {
                _cards[i].BorderBrush = DialogTheme.AccentBrush;
                _cards[i].Background = new SolidColorBrush(Color.FromArgb(30, 59, 130, 246));
            }
            else if (isFocused)
            {
                _cards[i].BorderBrush = DialogTheme.FocusRingBrush;
                _cards[i].Background = DialogTheme.CardBrush;
            }
            else
            {
                _cards[i].BorderBrush = DialogTheme.TransparentBrush;
                _cards[i].Background = DialogTheme.CardBrush;
            }
        }
    }

    protected override void OnWindowPreviewKeyDown(object sender, KeyEventArgs e)
    {
        if (Cooldown.IsCoolingDown) { e.Handled = true; return; }
        switch (e.Key)
        {
            case Key.Enter when _selected.Count > 0:
                Complete();
                e.Handled = true;
                return;
            case Key.Up:
                MoveFocus(-1);
                e.Handled = true;
                return;
            case Key.Down:
                MoveFocus(1);
                e.Handled = true;
                return;
            case Key.Space:
                ToggleSelection(_focusedIndex);
                e.Handled = true;
                return;
        }
        base.OnWindowPreviewKeyDown(sender, e);
    }

    private void MoveFocus(int delta)
    {
        _focusedIndex = Math.Clamp(_focusedIndex + delta, 0, _request.Choices.Length - 1);
        if (!_request.AllowMultiple)
        {
            _selected.Clear();
            _selected.Add(_focusedIndex);
        }
        UpdateVisuals();
    }

    protected override void OnCancelled()
    {
        Result = new ChoiceResponse { Cancelled = true, Dismissed = true };
        Close();
    }

    private void Complete()
    {
        if (_selected.Count == 0) return;

        var indices = _selected.OrderBy(i => i).ToArray();
        var choices = indices.Select(i => _request.Choices[i]).ToArray();
        var descs = _request.Descriptions is not null
            ? indices.Select(i => i < _request.Descriptions.Length ? _request.Descriptions[i] : null).ToArray()
            : null;

        Result = new ChoiceResponse
        {
            Answer = _request.AllowMultiple
                ? new StringOrStrings(choices)
                : new StringOrStrings(choices[0]),
            Description = !_request.AllowMultiple ? descs?.FirstOrDefault() : null,
            Descriptions = _request.AllowMultiple ? descs : null,
        };
        Close();
    }
}
