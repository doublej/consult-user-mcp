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
    private readonly Dictionary<string, HashSet<int>> _answers = new();
    private string? _expandedId;
    private int _focusedOptionIndex;
    private readonly List<Border> _optionCards = new();
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

    private void RenderSections()
    {
        int answered = _answers.Values.Count(s => s.Count > 0);
        _counterText.Text = $"{answered}/{_request.Questions.Length} answered";

        _sectionsPanel.Children.Clear();
        _optionCards.Clear();

        foreach (var q in _request.Questions)
        {
            var isExpanded = _expandedId == q.Id;
            var isAnswered = _answers.ContainsKey(q.Id) && _answers[q.Id].Count > 0;

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

            headerRow.Children.Add(new TextBlock
            {
                Text = q.Question,
                FontSize = DialogTheme.BodyFontSize,
                Foreground = DialogTheme.TextBrush,
                TextTrimming = TextTrimming.CharacterEllipsis,
                VerticalAlignment = VerticalAlignment.Center,
            });

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

                var optionsPanel = new StackPanel();
                var selected = _answers.GetValueOrDefault(q.Id, new HashSet<int>());

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
                        textStack.Children.Add(new TextBlock
                        {
                            Text = opt.Description,
                            FontSize = DialogTheme.SmallFontSize,
                            Foreground = DialogTheme.SecondaryTextBrush,
                            Margin = new Thickness(0, 3, 0, 0),
                        });
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

                contentBorder.Child = optionsPanel;
                section.Children.Add(contentBorder);
            }

            _sectionsPanel.Children.Add(section);
        }
    }

    private void ToggleOption(string questionId, int index, bool multiSelect)
    {
        if (!_answers.ContainsKey(questionId))
            _answers[questionId] = new HashSet<int>();

        var set = _answers[questionId];
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
        if (e.Key == Key.Enter)
        {
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
            switch (e.Key)
            {
                case Key.Up:
                    _focusedOptionIndex = Math.Max(0, _focusedOptionIndex - 1);
                    RenderSections();
                    e.Handled = true;
                    return;
                case Key.Down:
                    _focusedOptionIndex = Math.Min(q.Options.Length - 1, _focusedOptionIndex + 1);
                    RenderSections();
                    e.Handled = true;
                    return;
                case Key.Space:
                    ToggleOption(q.Id, _focusedOptionIndex, q.MultiSelect);
                    if (!q.MultiSelect) AdvanceToNext(q.Id);
                    else RenderSections();
                    e.Handled = true;
                    return;
            }
        }
        base.OnWindowPreviewKeyDown(sender, e);
    }

    protected override void OnCancelled()
    {
        Result = new QuestionsResponse { Cancelled = true };
        Close();
    }

    private void Complete()
    {
        var response = new QuestionsResponse();
        int completed = 0;

        foreach (var q in _request.Questions)
        {
            if (_answers.TryGetValue(q.Id, out var indices) && indices.Count > 0)
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
}
