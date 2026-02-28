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
    private bool _otherSelected;
    private string _otherText = "";
    private Border? _otherCard;
    private TextBox? _otherTextBox;

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
        if (_request.AllowOther)
        {
            _otherCard = CreateOtherCard();
            choicesPanel.Children.Add(_otherCard);
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
            textStack.Children.Add(SelectableTextBlock.Create(
                desc,
                DialogTheme.SmallFontSize,
                DialogTheme.SecondaryTextBrush,
                new Thickness(0, 4, 0, 0)
            ));
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

    private Border CreateOtherCard()
    {
        var stack = new StackPanel { Margin = new Thickness(12, 10, 12, 10) };
        stack.Children.Add(new TextBlock
        {
            Text = "Other",
            FontSize = DialogTheme.BodyFontSize,
            Foreground = DialogTheme.TextBrush,
            FontWeight = FontWeights.SemiBold,
        });

        _otherTextBox = new TextBox
        {
            Text = _otherText,
            FontSize = DialogTheme.BodyFontSize,
            Foreground = DialogTheme.TextBrush,
            Background = DialogTheme.CardBrush,
            BorderBrush = DialogTheme.BorderBrush,
            BorderThickness = new Thickness(1),
            Padding = new Thickness(8, 6, 8, 6),
            CaretBrush = DialogTheme.TextBrush,
            Margin = new Thickness(0, 6, 0, 0),
        };

        var placeholder = new TextBlock
        {
            Text = "Type your answer...",
            Foreground = DialogTheme.SecondaryTextBrush,
            FontSize = DialogTheme.BodyFontSize,
            IsHitTestVisible = false,
            Margin = new Thickness(10, 7, 0, 0),
        };

        var grid = new Grid();
        grid.Children.Add(_otherTextBox);
        grid.Children.Add(placeholder);

        _otherTextBox.TextChanged += (_, _) =>
        {
            _otherText = _otherTextBox.Text;
            placeholder.Visibility = string.IsNullOrEmpty(_otherTextBox.Text)
                ? Visibility.Visible : Visibility.Collapsed;
        };

        _otherTextBox.GotFocus += (_, _) =>
        {
            if (!_otherSelected) ToggleOther();
        };

        stack.Children.Add(grid);

        var border = new Border
        {
            Child = stack,
            Background = DialogTheme.CardBrush,
            CornerRadius = new CornerRadius(DialogTheme.CardCornerRadius),
            BorderThickness = new Thickness(2),
            BorderBrush = DialogTheme.TransparentBrush,
            Margin = new Thickness(0, 0, 0, 6),
            Cursor = Cursors.Hand,
        };

        border.MouseLeftButtonDown += (_, _) => ToggleOther();
        border.MouseEnter += (_, _) =>
        {
            if (!_otherSelected)
                border.Background = DialogTheme.CardHoverBrush;
        };
        border.MouseLeave += (_, _) =>
        {
            if (!_otherSelected)
                border.Background = DialogTheme.CardBrush;
        };

        return border;
    }

    private void ToggleOther()
    {
        if (_request.AllowMultiple)
        {
            _otherSelected = !_otherSelected;
        }
        else
        {
            _selected.Clear();
            _otherSelected = true;
        }
        _focusedIndex = _request.Choices.Length;
        UpdateVisuals();
        if (_otherSelected && _otherTextBox != null)
            _otherTextBox.Focus();
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
            _otherSelected = false;
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

        if (_otherCard != null)
        {
            if (_otherSelected)
            {
                _otherCard.BorderBrush = DialogTheme.AccentBrush;
                _otherCard.Background = new SolidColorBrush(Color.FromArgb(30, 59, 130, 246));
            }
            else if (_focusedIndex == _request.Choices.Length)
            {
                _otherCard.BorderBrush = DialogTheme.FocusRingBrush;
                _otherCard.Background = DialogTheme.CardBrush;
            }
            else
            {
                _otherCard.BorderBrush = DialogTheme.TransparentBrush;
                _otherCard.Background = DialogTheme.CardBrush;
            }
        }
    }

    protected override void OnWindowPreviewKeyDown(object sender, KeyEventArgs e)
    {
        if (Cooldown.IsCoolingDown) { e.Handled = true; return; }

        // When the Other text box is focused, let most keys pass through
        if (_otherTextBox != null && _otherTextBox.IsFocused && e.Key != Key.Enter
            && e.Key != Key.Up && e.Key != Key.Down && e.Key != Key.Escape)
        {
            base.OnWindowPreviewKeyDown(sender, e);
            return;
        }

        switch (e.Key)
        {
            case Key.Enter when _selected.Count > 0 || (_otherSelected && !string.IsNullOrEmpty(_otherText)):
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
                if (_focusedIndex == _request.Choices.Length && _request.AllowOther)
                    ToggleOther();
                else
                    ToggleSelection(_focusedIndex);
                e.Handled = true;
                return;
        }
        base.OnWindowPreviewKeyDown(sender, e);
    }

    private void MoveFocus(int delta)
    {
        var maxIndex = _request.AllowOther ? _request.Choices.Length : _request.Choices.Length - 1;
        _focusedIndex = Math.Clamp(_focusedIndex + delta, 0, maxIndex);
        if (!_request.AllowMultiple)
        {
            if (_focusedIndex == _request.Choices.Length && _request.AllowOther)
            {
                _selected.Clear();
                _otherSelected = true;
                if (_otherTextBox != null) _otherTextBox.Focus();
            }
            else
            {
                _otherSelected = false;
                _selected.Clear();
                _selected.Add(_focusedIndex);
            }
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
        bool hasOtherAnswer = _otherSelected && !string.IsNullOrEmpty(_otherText);
        if (_selected.Count == 0 && !hasOtherAnswer) return;

        var indices = _selected.OrderBy(i => i).ToArray();
        var choices = indices.Select(i => _request.Choices[i]).ToList();
        var descs = _request.Descriptions is not null
            ? indices.Select(i => i < _request.Descriptions.Length ? _request.Descriptions[i] : null).ToList()
            : null;

        if (hasOtherAnswer)
        {
            choices.Add(_otherText);
            descs?.Add(null);
        }

        if (_request.AllowMultiple)
        {
            Result = new ChoiceResponse
            {
                Answer = new StringOrStrings(choices.ToArray()),
                Descriptions = descs?.ToArray(),
            };
        }
        else if (hasOtherAnswer && _otherSelected)
        {
            Result = new ChoiceResponse
            {
                Answer = new StringOrStrings(_otherText),
            };
        }
        else
        {
            Result = new ChoiceResponse
            {
                Answer = new StringOrStrings(choices[0]),
                Description = descs?.FirstOrDefault(),
            };
        }
        Close();
    }
}
