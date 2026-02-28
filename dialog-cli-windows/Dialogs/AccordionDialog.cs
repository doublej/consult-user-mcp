using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using DialogCLI.Components;
using DialogCLI.Models;
using DialogCLI.Theme;

namespace DialogCLI.Dialogs;

public class AccordionDialog : DialogBase
{
    public QuestionsResponse Result { get; private set; }

    private readonly QuestionsRequest _request;
    private readonly Dictionary<string, HashSet<int>> _choiceAnswers = new();
    private readonly Dictionary<string, string> _textAnswers = new();
    private readonly Dictionary<string, bool> _otherSelections = new();
    private readonly Dictionary<string, string> _otherTexts = new();
    private string? _expandedId;
    private int _focusedOptionIndex;
    private readonly List<Border> _optionCards = new();
    private TextBox? _textInput;
    private readonly StackPanel _sectionsPanel = new();
    private readonly TextBlock _counterText = new();

    public AccordionDialog(QuestionsRequest request, string clientName)
    {
        _request = request;
        Result = new QuestionsResponse { Dismissed = true };
        MaxHeight = SystemParameters.PrimaryScreenHeight * DialogTheme.MaxHeightRatio;
        _expandedId = request.Questions.Length > 0 ? request.Questions[0].Id : null;
        BuildUI(clientName);
    }

    private void BuildUI(string clientName)
    {
        var outer = CreateOuterBorder();
        var rootStack = new StackPanel();

        var headerRow = new DockPanel { Margin = new Thickness(DialogTheme.Padding, DialogTheme.Padding, DialogTheme.Padding, 12) };
        headerRow.Children.Add(new TextBlock
        {
            Text = "Questions",
            FontSize = DialogTheme.TitleFontSize,
            FontWeight = FontWeights.SemiBold,
            Foreground = DialogTheme.TextBrush,
        });
        _counterText.FontSize = DialogTheme.SmallFontSize;
        _counterText.Foreground = DialogTheme.SecondaryTextBrush;
        _counterText.HorizontalAlignment = HorizontalAlignment.Right;
        DockPanel.SetDock(_counterText, Dock.Right);
        headerRow.Children.Add(_counterText);
        rootStack.Children.Add(headerRow);

        var scroll = new ScrollViewer
        {
            Content = _sectionsPanel,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            MaxHeight = 450,
            Margin = new Thickness(DialogTheme.Padding, 0, DialogTheme.Padding, 0),
        };
        rootStack.Children.Add(scroll);

        rootStack.Children.Add(DialogFooter.Create(
            "Tab sections \u2022 \u2191\u2193 navigate \u2022 Space select \u2022 Enter done",
            new FooterButton("Cancel", false, () =>
            {
                Result = new QuestionsResponse { Cancelled = true };
                Close();
            }),
            new FooterButton("Done", true, Complete)
        ));

        outer.Child = rootStack;
        Content = outer;

        RenderSections();
    }

    private void SaveTextAnswer()
    {
        if (_textInput is not null && _expandedId is not null)
            _textAnswers[_expandedId] = _textInput.Text;
    }

    private void RenderSections()
    {
        // Save any in-progress text input before re-rendering
        SaveTextAnswer();
        _textInput = null;

        int answered = 0;
        foreach (var q2 in _request.Questions)
        {
            if (q2.Type == QuestionType.Text)
            {
                if (_textAnswers.TryGetValue(q2.Id, out var t2) && !string.IsNullOrEmpty(t2))
                    answered++;
            }
            else
            {
                var hasChoice = _choiceAnswers.ContainsKey(q2.Id) && _choiceAnswers[q2.Id].Count > 0;
                var hasOther2 = _otherSelections.GetValueOrDefault(q2.Id, false)
                    && !string.IsNullOrEmpty(_otherTexts.GetValueOrDefault(q2.Id, ""));
                if (hasChoice || hasOther2)
                    answered++;
            }
        }
        _counterText.Text = $"{answered}/{_request.Questions.Length} answered";

        _sectionsPanel.Children.Clear();
        _optionCards.Clear();

        foreach (var q in _request.Questions)
        {
            var isExpanded = _expandedId == q.Id;
            var isAnswered = q.Type == QuestionType.Text
                ? _textAnswers.TryGetValue(q.Id, out var t) && !string.IsNullOrEmpty(t)
                : (_choiceAnswers.ContainsKey(q.Id) && _choiceAnswers[q.Id].Count > 0)
                  || (_otherSelections.GetValueOrDefault(q.Id, false)
                      && !string.IsNullOrEmpty(_otherTexts.GetValueOrDefault(q.Id, "")));

            var section = new StackPanel { Margin = new Thickness(0, 0, 0, 6) };

            // Section header (clickable)
            var headerBorder = new Border
            {
                Background = DialogTheme.CardBrush,
                CornerRadius = isExpanded
                    ? new CornerRadius(DialogTheme.CardCornerRadius, DialogTheme.CardCornerRadius, 0, 0)
                    : new CornerRadius(DialogTheme.CardCornerRadius),
                Cursor = Cursors.Hand,
                Padding = new Thickness(14, 10, 14, 10),
            };

            var headerRow = new DockPanel();

            var statusCircle = new Border
            {
                Width = 22,
                Height = 22,
                CornerRadius = new CornerRadius(11),
                Background = isAnswered ? DialogTheme.AccentBrush : DialogTheme.CardHoverBrush,
                Margin = new Thickness(0, 0, 10, 0),
                VerticalAlignment = VerticalAlignment.Center,
            };
            if (isAnswered)
            {
                statusCircle.Child = new TextBlock
                {
                    Text = "\u2713",
                    Foreground = Brushes.White,
                    FontSize = 12,
                    HorizontalAlignment = HorizontalAlignment.Center,
                    VerticalAlignment = VerticalAlignment.Center,
                };
            }
            DockPanel.SetDock(statusCircle, Dock.Left);
            headerRow.Children.Add(statusCircle);

            var chevron = new TextBlock
            {
                Text = isExpanded ? "\u25B2" : "\u25BC",
                FontSize = 10,
                Foreground = DialogTheme.SecondaryTextBrush,
                VerticalAlignment = VerticalAlignment.Center,
                Margin = new Thickness(10, 0, 0, 0),
            };
            DockPanel.SetDock(chevron, Dock.Right);
            headerRow.Children.Add(chevron);

            var questionText = SelectableTextBlock.Create(
                q.Question,
                DialogTheme.BodyFontSize,
                DialogTheme.TextBrush
            );
            questionText.TextTrimming = TextTrimming.CharacterEllipsis;
            questionText.VerticalAlignment = VerticalAlignment.Center;
            headerRow.Children.Add(questionText);

            headerBorder.Child = headerRow;
            var qId = q.Id;
            headerBorder.MouseLeftButtonDown += (_, _) =>
            {
                _expandedId = _expandedId == qId ? null : qId;
                _focusedOptionIndex = 0;
                RenderSections();
            };
            section.Children.Add(headerBorder);

            // Expanded content
            if (isExpanded)
            {
                var contentBorder = new Border
                {
                    Background = new SolidColorBrush(Color.FromRgb(38, 38, 38)),
                    CornerRadius = new CornerRadius(0, 0, DialogTheme.CardCornerRadius, DialogTheme.CardCornerRadius),
                    Padding = new Thickness(10, 10, 10, 10),
                };

                if (q.Type == QuestionType.Text)
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
                    {
                        var ph = q.Placeholder;
                        var tb = _textInput;
                        var placeholderBlock = new TextBlock
                        {
                            Text = ph,
                            Foreground = DialogTheme.SecondaryTextBrush,
                            FontSize = DialogTheme.BodyFontSize,
                            IsHitTestVisible = false,
                            Margin = new Thickness(12, 9, 0, 0),
                        };
                        var grid = new Grid();
                        grid.Children.Add(tb);
                        grid.Children.Add(placeholderBlock);
                        tb.Loaded += (_, _) => placeholderBlock.Visibility = string.IsNullOrEmpty(tb.Text) ? Visibility.Visible : Visibility.Collapsed;
                        tb.TextChanged += (_, _) => placeholderBlock.Visibility = string.IsNullOrEmpty(tb.Text) ? Visibility.Visible : Visibility.Collapsed;
                        contentBorder.Child = grid;
                    }
                    else
                    {
                        contentBorder.Child = _textInput;
                    }
                    _textInput.Loaded += (_, _) => { _textInput.Focus(); _textInput.SelectAll(); };
                }
                else
                {
                    var optionsPanel = new StackPanel();
                    var selected = _choiceAnswers.GetValueOrDefault(q.Id, new HashSet<int>());

                    for (int i = 0; i < q.Options.Length; i++)
                    {
                        var optIdx = i;
                        var opt = q.Options[i];
                        var isSel = selected.Contains(i);
                        var isFocused = i == _focusedOptionIndex;

                        var textStack = new StackPanel { Margin = new Thickness(10, 6, 10, 6) };
                        textStack.Children.Add(new TextBlock
                        {
                            Text = opt.Label,
                            FontSize = DialogTheme.BodyFontSize,
                            Foreground = DialogTheme.TextBrush,
                            TextWrapping = TextWrapping.Wrap,
                        });
                        if (!string.IsNullOrEmpty(opt.Description))
                        {
                            textStack.Children.Add(SelectableTextBlock.Create(
                                opt.Description,
                                DialogTheme.SmallFontSize,
                                DialogTheme.SecondaryTextBrush,
                                new Thickness(0, 3, 0, 0)
                            ));
                        }

                        var optCard = new Border
                        {
                            Child = textStack,
                            CornerRadius = new CornerRadius(6),
                            BorderThickness = new Thickness(2),
                            Margin = new Thickness(0, 0, 0, 4),
                            Cursor = Cursors.Hand,
                        };

                        if (isSel)
                        {
                            optCard.Background = new SolidColorBrush(Color.FromArgb(30, 59, 130, 246));
                            optCard.BorderBrush = DialogTheme.AccentBrush;
                        }
                        else if (isFocused)
                        {
                            optCard.Background = DialogTheme.TransparentBrush;
                            optCard.BorderBrush = DialogTheme.FocusRingBrush;
                        }
                        else
                        {
                            optCard.Background = DialogTheme.TransparentBrush;
                            optCard.BorderBrush = DialogTheme.TransparentBrush;
                        }

                        optCard.MouseLeftButtonDown += (_, _) =>
                        {
                            _focusedOptionIndex = optIdx;
                            ToggleOption(q.Id, optIdx, q.MultiSelect);
                            if (!q.MultiSelect) AdvanceToNext(qId);
                            else RenderSections();
                        };
                        _optionCards.Add(optCard);
                        optionsPanel.Children.Add(optCard);
                    }

                    if (q.AllowOther)
                    {
                        var otherCard = CreateOtherOptionCard(q, optionsPanel);
                        optionsPanel.Children.Add(otherCard);
                    }

                    contentBorder.Child = optionsPanel;
                }
                section.Children.Add(contentBorder);
            }

            _sectionsPanel.Children.Add(section);
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
            _otherSelections[questionId] = false;
        }
    }

    private Border CreateOtherOptionCard(QuestionItem q, StackPanel parentPanel)
    {
        var isOtherSel = _otherSelections.GetValueOrDefault(q.Id, false);
        var isOtherFocused = _focusedOptionIndex == q.Options.Length;

        var stack = new StackPanel { Margin = new Thickness(10, 6, 10, 6) };
        stack.Children.Add(new TextBlock
        {
            Text = "Other",
            FontSize = DialogTheme.BodyFontSize,
            Foreground = DialogTheme.TextBrush,
            FontWeight = FontWeights.SemiBold,
        });

        var otherTextBox = new TextBox
        {
            Text = _otherTexts.GetValueOrDefault(q.Id, ""),
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
            Visibility = string.IsNullOrEmpty(otherTextBox.Text) ? Visibility.Visible : Visibility.Collapsed,
        };

        var grid = new Grid();
        grid.Children.Add(otherTextBox);
        grid.Children.Add(placeholder);

        otherTextBox.TextChanged += (_, _) =>
        {
            _otherTexts[q.Id] = otherTextBox.Text;
            placeholder.Visibility = string.IsNullOrEmpty(otherTextBox.Text)
                ? Visibility.Visible : Visibility.Collapsed;
        };

        otherTextBox.GotFocus += (_, _) =>
        {
            if (!_otherSelections.GetValueOrDefault(q.Id, false))
                ToggleOtherOption(q);
        };

        stack.Children.Add(grid);

        var card = new Border
        {
            Child = stack,
            CornerRadius = new CornerRadius(6),
            BorderThickness = new Thickness(2),
            Margin = new Thickness(0, 0, 0, 4),
            Cursor = Cursors.Hand,
        };

        if (isOtherSel)
        {
            card.Background = new SolidColorBrush(Color.FromArgb(30, 59, 130, 246));
            card.BorderBrush = DialogTheme.AccentBrush;
        }
        else if (isOtherFocused)
        {
            card.Background = DialogTheme.TransparentBrush;
            card.BorderBrush = DialogTheme.FocusRingBrush;
        }
        else
        {
            card.Background = DialogTheme.TransparentBrush;
            card.BorderBrush = DialogTheme.TransparentBrush;
        }

        card.MouseLeftButtonDown += (_, _) => ToggleOtherOption(q);

        return card;
    }

    private void ToggleOtherOption(QuestionItem q)
    {
        var currentlySelected = _otherSelections.GetValueOrDefault(q.Id, false);
        if (q.MultiSelect)
        {
            _otherSelections[q.Id] = !currentlySelected;
        }
        else
        {
            if (_choiceAnswers.ContainsKey(q.Id))
                _choiceAnswers[q.Id].Clear();
            _otherSelections[q.Id] = true;
        }
        _focusedOptionIndex = q.Options.Length;
        RenderSections();
    }

    private void AdvanceToNext(string currentId)
    {
        var idx = Array.FindIndex(_request.Questions, q => q.Id == currentId);
        if (idx < _request.Questions.Length - 1)
            _expandedId = _request.Questions[idx + 1].Id;
        _focusedOptionIndex = 0;
        RenderSections();
    }

    protected override void OnWindowPreviewKeyDown(object sender, KeyEventArgs e)
    {
        if (Cooldown.IsCoolingDown) { e.Handled = true; return; }
        if (e.Key == Key.Enter)
        {
            bool hasAnswer = _choiceAnswers.Values.Any(s => s.Count > 0)
                          || _textAnswers.Values.Any(s => !string.IsNullOrEmpty(s))
                          || _otherSelections.Any(kv => kv.Value && !string.IsNullOrEmpty(_otherTexts.GetValueOrDefault(kv.Key, "")));
            if (!hasAnswer) { e.Handled = true; return; }
            Complete();
            e.Handled = true;
            return;
        }
        if (e.Key == Key.Tab)
        {
            var currentIdx = _expandedId is null ? -1 : Array.FindIndex(_request.Questions, q => q.Id == _expandedId);
            if (Keyboard.Modifiers.HasFlag(ModifierKeys.Shift))
            {
                if (currentIdx > 0) _expandedId = _request.Questions[currentIdx - 1].Id;
            }
            else
            {
                if (currentIdx < _request.Questions.Length - 1) _expandedId = _request.Questions[currentIdx + 1].Id;
            }
            _focusedOptionIndex = 0;
            RenderSections();
            e.Handled = true;
            return;
        }
        if (_expandedId is not null)
        {
            var q = _request.Questions.First(q => q.Id == _expandedId);
            // Let text input handle its own keys (except Tab handled above)
            if (q.Type == QuestionType.Text)
            {
                base.OnWindowPreviewKeyDown(sender, e);
                return;
            }
            switch (e.Key)
            {
                case Key.Up:
                    _focusedOptionIndex = Math.Max(0, _focusedOptionIndex - 1);
                    RenderSections();
                    e.Handled = true;
                    return;
                case Key.Down:
                    var maxIdx = q.AllowOther ? q.Options.Length : q.Options.Length - 1;
                    _focusedOptionIndex = Math.Min(maxIdx, _focusedOptionIndex + 1);
                    RenderSections();
                    e.Handled = true;
                    return;
                case Key.Space:
                    if (_focusedOptionIndex == q.Options.Length && q.AllowOther)
                        ToggleOtherOption(q);
                    else
                    {
                        ToggleOption(q.Id, _focusedOptionIndex, q.MultiSelect);
                        if (!q.MultiSelect) AdvanceToNext(q.Id);
                        else RenderSections();
                    }
                    e.Handled = true;
                    return;
            }
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
        SaveTextAnswer();

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
            else
            {
                var hasChoices = _choiceAnswers.TryGetValue(q.Id, out var indices) && indices.Count > 0;
                var hasOther = _otherSelections.GetValueOrDefault(q.Id, false)
                    && !string.IsNullOrEmpty(_otherTexts.GetValueOrDefault(q.Id, ""));

                if (hasChoices || hasOther)
                {
                    completed++;
                    var labels = hasChoices
                        ? indices!.OrderBy(i => i).Select(i => q.Options[i].Label).ToList()
                        : new List<string>();

                    if (hasOther)
                        labels.Add(_otherTexts[q.Id]);

                    if (q.MultiSelect)
                    {
                        response.Answers[q.Id] = new StringOrStrings(labels.ToArray());
                    }
                    else if (hasOther && _otherSelections[q.Id])
                    {
                        response.Answers[q.Id] = new StringOrStrings(_otherTexts[q.Id]);
                    }
                    else
                    {
                        response.Answers[q.Id] = new StringOrStrings(labels[0]);
                    }
                }
            }
        }

        response.CompletedCount = completed;
        Result = response;
        Close();
    }
}
