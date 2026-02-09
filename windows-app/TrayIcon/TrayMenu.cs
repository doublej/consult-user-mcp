using System.Windows.Controls;

namespace ConsultUserMCP.TrayIcon;

public static class TrayMenu
{
    public static ContextMenu Build(Action onSettings, Action onCheckUpdates, Action onQuit)
    {
        var menu = new ContextMenu();

        var settingsItem = new MenuItem { Header = "Settings..." };
        settingsItem.Click += (_, _) => onSettings();
        menu.Items.Add(settingsItem);

        var updateItem = new MenuItem { Header = "Check for Updates..." };
        updateItem.Click += (_, _) => onCheckUpdates();
        menu.Items.Add(updateItem);

        menu.Items.Add(BuildDebugMenu());

        menu.Items.Add(new Separator());

        var quitItem = new MenuItem { Header = "Quit" };
        quitItem.Click += (_, _) => onQuit();
        menu.Items.Add(quitItem);

        return menu;
    }

    private static MenuItem BuildDebugMenu()
    {
        var debug = new MenuItem { Header = "Debug" };

        AddItem(debug, "Test Confirm", "confirm",
            """{"body":"This is a test confirmation dialog.\n\nDo you want to proceed?","title":"Confirmation Test","confirmLabel":"Yes, proceed","cancelLabel":"Cancel","position":"left"}""");

        AddItem(debug, "Test Choose (Single)", "choose",
            """{"body":"Select your preferred option:","choices":["Option Alpha","Option Beta","Option Gamma","Option Delta"],"descriptions":["First choice","Second choice - recommended","Third alternative","Fourth fallback"],"allowMultiple":false,"position":"left"}""");

        AddItem(debug, "Test Choose (Multi)", "choose",
            """{"body":"Select features to enable:","choices":["Authentication","Database","API Endpoints","Logging"],"descriptions":["OAuth2 + JWT","PostgreSQL","REST + GraphQL","Structured JSON"],"allowMultiple":true,"position":"left"}""");

        AddItem(debug, "Test Text Input", "textInput",
            """{"body":"Enter your feedback:","title":"Text Input Test","defaultValue":"Sample text...","hidden":false,"position":"left"}""");

        AddItem(debug, "Test Password", "textInput",
            """{"body":"Enter your API key:","title":"API Configuration","defaultValue":"","hidden":true,"position":"left"}""");

        AddItem(debug, "Test Wizard", "questions",
            """{"questions":[{"id":"language","question":"What programming language?","options":[{"label":"TypeScript","description":"Strongly typed JavaScript"},{"label":"Python","description":"Dynamic scripting language"},{"label":"Go","description":"Fast compiled language"}],"type":"choice","multiSelect":false},{"id":"framework","question":"Which framework?","options":[{"label":"Express","description":"Minimal Node.js"},{"label":"FastAPI","description":"Modern Python API"},{"label":"Gin","description":"High-performance Go"}],"type":"choice","multiSelect":false}],"mode":"wizard","position":"left"}""");

        AddItem(debug, "Test Accordion", "questions",
            """{"questions":[{"id":"database","question":"Select database:","options":[{"label":"PostgreSQL","description":"Relational database"},{"label":"MongoDB","description":"Document NoSQL"},{"label":"Redis","description":"Key-value store"}],"type":"choice","multiSelect":false},{"id":"auth","question":"Authentication:","options":[{"label":"OAuth 2.0","description":"Third-party"},{"label":"JWT","description":"Stateless tokens"},{"label":"Session","description":"Server-side"}],"type":"choice","multiSelect":true}],"mode":"accordion","position":"left"}""");

        AddItem(debug, "Test Notify", "notify",
            """{"body":"This is a test notification from the debug menu.","title":"Test","sound":true}""");

        return debug;
    }

    private static void AddItem(MenuItem parent, string label, string command, string json)
    {
        var item = new MenuItem { Header = label };
        item.Click += (_, _) => DebugDialogRunner.Run(command, json);
        parent.Items.Add(item);
    }
}
