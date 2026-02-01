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
    private readonly Dictionary<string, HashSet<int>> _answers = new();
    private int _currentIndex;
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

        // Progress bar
        _progressBar.Orientation = Orientation.Horizontal;
        _progressBar.Margin = new Thickness(DialogTheme.Padding, DialogTheme.Padding, DialogTheme.Padding, 8);
        rootStack.Children.Add(_progressBar);

        // Progress text
        _progressText.FontSize = DialogTheme.SmallFontSize;
        _progressText.Foreground = DialogTheme.SecondaryTextBrush;
        _progressText.HorizontalAlignment = HorizontalAlignment.Center;
        _progressText.Margin = new Thickness(0, 0, 0, 12);
        rootStack.Children.Add(_progressText);

        // Content area (swapped per step)
        _contentPanel.Margin = new Thickness(DialogTheme.Padding, 0, DialogTheme.Padding, 0);
        var scroll = new ScrollViewer
        {
            Content = _contentPanel,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            MaxHeight = 400,
        };
        rootStack.Children.Add(scroll);

        // Footer with nav buttons (built dynamically)
        var footerPanel = new StackPanel { Margin = new Thickness(DialogTheme.Padding, 12, DialogTheme.Padding, DialogTheme.Padding) };
        rootStack.Children.Add(footerPanel);

        outer.Child = rootStack;
        Content = outer;

        RenderStep();
    }

    private void RenderStep()
    {
        var q = _request.Questions[_currentIndex];

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

        // Render question options
        _contentPanel.Children.Clear();

        var questionText = new TextBlock
        {
            Text = q.Question,
            FontSize = DialogTheme.TitleFontSize,
            FontWeight = FontWeights.SemiBold,
            Foreground = DialogTheme.TextBrush,
            TextWrapping = TextWrapping.Wrap,
            Margin = new Thickness(0, 0, 0, 12),
        };
        _contentPanel.Children.Add(questionText);

        var selected = _answers.GetValueOrDefault(q.Id, new HashSet<int>());
        for (int i = 0; i < q.Options.Length; i++)
        {
            var optIdx = i;
            var opt = q.Options[i];
            var isSelected = selected.Contains(i);

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
                Background = isSelected ? new SolidColorBrush(Color.FromArgb(30, 59, 130, 246)) : DialogTheme.CardBrush,
                CornerRadius = new CornerRadius(DialogTheme.CardCornerRadius),
                BorderThickness = new Thickness(2),
                BorderBrush = isSelected ? DialogTheme.AccentBrush : DialogTheme.TransparentBrush,
                Margin = new Thickness(0, 0, 0, 6),
                Cursor = Cursors.Hand,
            };
            card.MouseLeftButtonDown += (_, _) =>
            {
                ToggleOption(q.Id, optIdx, q.MultiSelect);
                RenderStep();
            };
            _contentPanel.Children.Add(card);
        }

        // Navigation buttons
        var buttonRow = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            HorizontalAlignment = HorizontalAlignment.Right,
            Margin = new Thickness(0, 12, 0, 0),
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
        var hasAnswer = selected.Count > 0;
        AddButton(buttonRow, isLast ? "Done" : "Next", true, () =>
        {
            if (!hasAnswer) return;
            if (isLast) Complete();
            else { _currentIndex++; RenderStep(); }
        });

        _contentPanel.Children.Add(buttonRow);
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

    protected override void OnWindowKeyDown(object sender, KeyEventArgs e)
    {
        var q = _request.Questions[_currentIndex];
        var hasAnswer = _answers.ContainsKey(q.Id) && _answers[q.Id].Count > 0;

        switch (e.Key)
        {
            case Key.Enter when hasAnswer:
                if (_currentIndex == _request.Questions.Length - 1) Complete();
                else { _currentIndex++; RenderStep(); }
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
        base.OnWindowKeyDown(sender, e);
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
        };
        btn.Click += (_, _) => onClick();
        panel.Children.Add(btn);
    }
}
