using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using DialogCLI.Components;
using DialogCLI.Models;
using DialogCLI.Theme;

namespace DialogCLI.Dialogs;

public class WizardDialog : DialogBase
{
    public QuestionsResponse Result { get; private set; }

    private readonly QuestionsRequest _request;
    private readonly Dictionary<string, HashSet<int>> _choiceAnswers = new();
    private readonly Dictionary<string, string> _textAnswers = new();
    private int _currentIndex;
    private int _focusedOptionIndex;
    private readonly List<Border> _optionCards = new();
    private TextBox? _textInput;
    private readonly StackPanel _contentPanel = new();
    private readonly TextBlock _progressText = new();
    private readonly StackPanel _progressBar = new();

    public WizardDialog(QuestionsRequest request, string clientName)
    {
        _request = request;
        Result = new QuestionsResponse { Dismissed = true };
        MaxHeight = SystemParameters.PrimaryScreenHeight * DialogTheme.MaxHeightRatio;
        BuildUI(clientName);
    }

    private void BuildUI(string clientName)
    {
        var outer = CreateOuterBorder();
        var rootStack = new StackPanel();

        _progressBar.Orientation = Orientation.Horizontal;
        _progressBar.Margin = new Thickness(DialogTheme.Padding, DialogTheme.Padding, DialogTheme.Padding, 8);
        rootStack.Children.Add(_progressBar);

        _progressText.FontSize = DialogTheme.SmallFontSize;
        _progressText.Foreground = DialogTheme.SecondaryTextBrush;
        _progressText.HorizontalAlignment = HorizontalAlignment.Center;
        _progressText.Margin = new Thickness(0, 0, 0, 12);
        rootStack.Children.Add(_progressText);

        _contentPanel.Margin = new Thickness(DialogTheme.Padding, 0, DialogTheme.Padding, 0);
        var scroll = new ScrollViewer
        {
            Content = _contentPanel,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            MaxHeight = 400,
        };
        rootStack.Children.Add(scroll);

        var footerPanel = new StackPanel { Margin = new Thickness(DialogTheme.Padding, 12, DialogTheme.Padding, DialogTheme.Padding) };
        rootStack.Children.Add(footerPanel);

        outer.Child = rootStack;
        Content = outer;

        RenderStep();
    }

    private void RenderStep()
    {
        var q = _request.Questions[_currentIndex];
        _focusedOptionIndex = 0;
        _optionCards.Clear();
        _textInput = null;

        // Update progress bar
        _progressBar.Children.Clear();
        for (int i = 0; i < _request.Questions.Length; i++)
        {
            var dot = new Border
            {
                Width = Math.Max(8, (DialogTheme.MinWidth - 2 * DialogTheme.Padding - (_request.Questions.Length - 1) * 4) / _request.Questions.Length),
                Height = 4,
                CornerRadius = new CornerRadius(2),
                Background = i <= _currentIndex ? DialogTheme.AccentBrush : DialogTheme.CardBrush,
                Margin = new Thickness(i > 0 ? 4 : 0, 0, 0, 0),
            };
            _progressBar.Children.Add(dot);
        }
        _progressText.Text = $"{_currentIndex + 1} of {_request.Questions.Length}";

        // Render question content
        _contentPanel.Children.Clear();

        _contentPanel.Children.Add(new TextBlock
        {
            Text = q.Question,
            FontSize = DialogTheme.TitleFontSize,
            FontWeight = FontWeights.SemiBold,
            Foreground = DialogTheme.TextBrush,
            TextWrapping = TextWrapping.Wrap,
            Margin = new Thickness(0, 0, 0, 12),
        });

        bool hasAnswer;
        if (q.Type == QuestionType.Text)
        {
            hasAnswer = RenderTextInput(q);
        }
        else
        {
            hasAnswer = RenderChoiceOptions(q);
        }

        // Navigation buttons
        var buttonRow = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            HorizontalAlignment = HorizontalAlignment.Right,
            Margin = new Thickness(0, 4, 0, 0),
        };

        if (_currentIndex == 0)
        {
            AddButton(buttonRow, "Cancel", false, () =>
            {
                Result = new QuestionsResponse { Cancelled = true };
                Close();
            });
        }
        else
        {
            AddButton(buttonRow, "Back", false, () => { _currentIndex--; RenderStep(); });
        }

        var isLast = _currentIndex == _request.Questions.Length - 1;
        var hasAnswerCopy = hasAnswer;
        AddButton(buttonRow, isLast ? "Done" : "Next", true, () =>
        {
            if (!hasAnswerCopy && q.Type != QuestionType.Text) return;
            if (q.Type == QuestionType.Text) SaveTextAnswer(q.Id);
            if (isLast) Complete();
            else { _currentIndex++; RenderStep(); }
        });

        _contentPanel.Children.Add(buttonRow);
        if (q.Type != QuestionType.Text) UpdateOptionVisuals();
    }

    private bool RenderTextInput(QuestionItem q)
    {
        _textInput = new TextBox
        {
            Text = _textAnswers.GetValueOrDefault(q.Id, ""),
            FontSize = DialogTheme.BodyFontSize,
            Foreground = DialogTheme.TextBrush,
            Background = DialogTheme.CardBrush,
            BorderBrush = DialogTheme.BorderBrush,
            BorderThickness = new Thickness(1),
            Padding = new Thickness(10, 8, 10, 8),
            CaretBrush = DialogTheme.TextBrush,
            AcceptsReturn = false,
        };
        if (!string.IsNullOrEmpty(q.Placeholder))
            SetPlaceholder(_textInput, q.Placeholder);

        _contentPanel.Children.Add(_textInput);

        // Hint text
        _contentPanel.Children.Add(new TextBlock
        {
            Text = "Enter answer \u2022 \u2190\u2192 steps \u2022 Enter next/done",
            FontSize = DialogTheme.HintFontSize,
            Foreground = DialogTheme.SecondaryTextBrush,
            HorizontalAlignment = HorizontalAlignment.Center,
            Margin = new Thickness(0, 8, 0, 4),
        });

        // Focus the text input after layout
        _textInput.Loaded += (_, _) => { _textInput.Focus(); _textInput.SelectAll(); };

        return !string.IsNullOrEmpty(_textInput.Text);
    }

    private bool RenderChoiceOptions(QuestionItem q)
    {
        var selected = _choiceAnswers.GetValueOrDefault(q.Id, new HashSet<int>());
        for (int i = 0; i < q.Options.Length; i++)
        {
            var optIdx = i;
            var opt = q.Options[i];

            var textStack = new StackPanel { Margin = new Thickness(12, 8, 12, 8) };
            textStack.Children.Add(new TextBlock
            {
                Text = opt.Label,
                FontSize = DialogTheme.BodyFontSize,
                Foreground = DialogTheme.TextBrush,
                TextWrapping = TextWrapping.Wrap,
            });
            if (!string.IsNullOrEmpty(opt.Description))
            {
                textStack.Children.Add(new TextBlock
                {
                    Text = opt.Description,
                    FontSize = DialogTheme.SmallFontSize,
                    Foreground = DialogTheme.SecondaryTextBrush,
                    TextWrapping = TextWrapping.Wrap,
                    Margin = new Thickness(0, 3, 0, 0),
                });
            }

            var card = new Border
            {
                Child = textStack,
                Background = DialogTheme.CardBrush,
                CornerRadius = new CornerRadius(DialogTheme.CardCornerRadius),
                BorderThickness = new Thickness(2),
                BorderBrush = DialogTheme.TransparentBrush,
                Margin = new Thickness(0, 0, 0, 6),
                Cursor = Cursors.Hand,
            };
            card.MouseLeftButtonDown += (_, _) =>
            {
                _focusedOptionIndex = optIdx;
                ToggleOption(q.Id, optIdx, q.MultiSelect);
                UpdateOptionVisuals();
            };
            _optionCards.Add(card);
            _contentPanel.Children.Add(card);
        }

        // Hint text
        _contentPanel.Children.Add(new TextBlock
        {
            Text = "\u2191\u2193 navigate \u2022 Space select \u2022 \u2190\u2192 steps \u2022 Enter next/done",
            FontSize = DialogTheme.HintFontSize,
            Foreground = DialogTheme.SecondaryTextBrush,
            HorizontalAlignment = HorizontalAlignment.Center,
            Margin = new Thickness(0, 8, 0, 4),
        });

        return selected.Count > 0;
    }

    private void SaveTextAnswer(string questionId)
    {
        if (_textInput is not null)
            _textAnswers[questionId] = _textInput.Text;
    }

    private static void SetPlaceholder(TextBox textBox, string placeholder)
    {
        var placeholderBlock = new TextBlock
        {
            Text = placeholder,
            Foreground = DialogTheme.SecondaryTextBrush,
            FontSize = DialogTheme.BodyFontSize,
            IsHitTestVisible = false,
            Margin = new Thickness(12, 9, 0, 0),
        };
        var grid = new Grid();
        // Replace the textbox in its parent with a grid containing both
        textBox.Loaded += (_, _) =>
        {
            placeholderBlock.Visibility = string.IsNullOrEmpty(textBox.Text) ? Visibility.Visible : Visibility.Collapsed;
        };
        textBox.TextChanged += (_, _) =>
        {
            placeholderBlock.Visibility = string.IsNullOrEmpty(textBox.Text) ? Visibility.Visible : Visibility.Collapsed;
        };

        var parent = textBox.Parent as StackPanel;
        if (parent is null) return;
        var idx = parent.Children.IndexOf(textBox);
        parent.Children.Remove(textBox);
        grid.Children.Add(textBox);
        grid.Children.Add(placeholderBlock);
        parent.Children.Insert(idx, grid);
    }

    private void UpdateOptionVisuals()
    {
        var q = _request.Questions[_currentIndex];
        var selected = _choiceAnswers.GetValueOrDefault(q.Id, new HashSet<int>());

        for (int i = 0; i < _optionCards.Count; i++)
        {
            var isSelected = selected.Contains(i);
            var isFocused = i == _focusedOptionIndex;

            if (isSelected)
            {
                _optionCards[i].BorderBrush = DialogTheme.AccentBrush;
                _optionCards[i].Background = new SolidColorBrush(Color.FromArgb(30, 59, 130, 246));
            }
            else if (isFocused)
            {
                _optionCards[i].BorderBrush = DialogTheme.FocusRingBrush;
                _optionCards[i].Background = DialogTheme.CardBrush;
            }
            else
            {
                _optionCards[i].BorderBrush = DialogTheme.TransparentBrush;
                _optionCards[i].Background = DialogTheme.CardBrush;
            }
        }
    }

    private void ToggleOption(string questionId, int index, bool multiSelect)
    {
        if (!_choiceAnswers.ContainsKey(questionId))
            _choiceAnswers[questionId] = new HashSet<int>();

        var set = _choiceAnswers[questionId];
        if (multiSelect)
        {
            if (!set.Remove(index)) set.Add(index);
        }
        else
        {
            set.Clear();
            set.Add(index);
        }
    }

    protected override void OnWindowPreviewKeyDown(object sender, KeyEventArgs e)
    {
        var q = _request.Questions[_currentIndex];

        if (q.Type == QuestionType.Text)
        {
            // For text questions, only intercept Enter (submit) and Left/Right with Ctrl for step nav
            if (e.Key == Key.Enter)
            {
                SaveTextAnswer(q.Id);
                if (_currentIndex == _request.Questions.Length - 1) Complete();
                else { _currentIndex++; RenderStep(); }
                e.Handled = true;
                return;
            }
            // Let all other keys pass through to the TextBox
            base.OnWindowPreviewKeyDown(sender, e);
            return;
        }

        var hasAnswer = _choiceAnswers.ContainsKey(q.Id) && _choiceAnswers[q.Id].Count > 0;

        switch (e.Key)
        {
            case Key.Enter when hasAnswer:
                if (_currentIndex == _request.Questions.Length - 1) Complete();
                else { _currentIndex++; RenderStep(); }
                e.Handled = true;
                return;
            case Key.Up:
                _focusedOptionIndex = Math.Max(0, _focusedOptionIndex - 1);
                UpdateOptionVisuals();
                e.Handled = true;
                return;
            case Key.Down:
                _focusedOptionIndex = Math.Min(q.Options.Length - 1, _focusedOptionIndex + 1);
                UpdateOptionVisuals();
                e.Handled = true;
                return;
            case Key.Space:
                ToggleOption(q.Id, _focusedOptionIndex, q.MultiSelect);
                UpdateOptionVisuals();
                e.Handled = true;
                return;
            case Key.Left when _currentIndex > 0:
                _currentIndex--;
                RenderStep();
                e.Handled = true;
                return;
            case Key.Right when hasAnswer && _currentIndex < _request.Questions.Length - 1:
                _currentIndex++;
                RenderStep();
                e.Handled = true;
                return;
        }
        base.OnWindowPreviewKeyDown(sender, e);
    }

    protected override void OnCancelled()
    {
        Result = new QuestionsResponse { Cancelled = true, Dismissed = true };
        Close();
    }

    private void Complete()
    {
        // Save current text input if on a text question
        var current = _request.Questions[_currentIndex];
        if (current.Type == QuestionType.Text) SaveTextAnswer(current.Id);

        var response = new QuestionsResponse();
        int completed = 0;

        foreach (var q in _request.Questions)
        {
            if (q.Type == QuestionType.Text)
            {
                if (_textAnswers.TryGetValue(q.Id, out var text) && !string.IsNullOrEmpty(text))
                {
                    completed++;
                    response.Answers[q.Id] = new StringOrStrings(text);
                }
            }
            else if (_choiceAnswers.TryGetValue(q.Id, out var indices) && indices.Count > 0)
            {
                completed++;
                var labels = indices.OrderBy(i => i).Select(i => q.Options[i].Label).ToArray();
                response.Answers[q.Id] = q.MultiSelect
                    ? new StringOrStrings(labels)
                    : new StringOrStrings(labels[0]);
            }
        }

        response.CompletedCount = completed;
        Result = response;
        Close();
    }

    private static void AddButton(StackPanel panel, string label, bool isPrimary, Action onClick)
    {
        var btn = new Button
        {
            Content = label,
            MinWidth = 80,
            Height = 36,
            Margin = new Thickness(6, 0, 0, 0),
            Padding = new Thickness(16, 0, 16, 0),
            FontSize = DialogTheme.BodyFontSize,
            Cursor = Cursors.Hand,
            Background = isPrimary ? DialogTheme.AccentBrush : DialogTheme.CardBrush,
            Foreground = isPrimary ? Brushes.White : DialogTheme.TextBrush,
            BorderBrush = isPrimary ? DialogTheme.AccentBrush : DialogTheme.BorderBrush,
            BorderThickness = new Thickness(1),
            IsTabStop = false,
        };
        btn.Click += (_, _) => onClick();
        panel.Children.Add(btn);
    }
}
