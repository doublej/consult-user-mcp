using System.IO;
using System.Text.Json;

namespace ConsultUserMCP.Services;

public class Project
{
    public string Path { get; set; } = "";
    public string DisplayName { get; set; } = "";
    public DateTime LastSeen { get; set; }

    public string FolderName => System.IO.Path.GetFileName(Path);
}

public class ProjectManager
{
    public static ProjectManager Shared { get; } = new();

    private readonly string _configPath;
    private readonly object _lock = new();

    public List<Project> Projects { get; private set; } = new();
    public event Action? ProjectsChanged;

    private ProjectManager()
    {
        var configDir = System.IO.Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
            ".config", "consult-user-mcp"
        );
        Directory.CreateDirectory(configDir);
        _configPath = System.IO.Path.Combine(configDir, "projects.json");
        Load();
    }

    public void AddOrUpdate(string path)
    {
        lock (_lock)
        {
            var normalized = System.IO.Path.GetFullPath(path);
            var existing = Projects.Find(p => p.Path == normalized);
            if (existing != null)
            {
                existing.LastSeen = DateTime.Now;
            }
            else
            {
                Projects.Add(new Project
                {
                    Path = normalized,
                    DisplayName = System.IO.Path.GetFileName(normalized),
                    LastSeen = DateTime.Now
                });
            }
            Sort();
            Save();
        }
        ProjectsChanged?.Invoke();
    }

    public void Rename(string path, string newName)
    {
        lock (_lock)
        {
            var project = Projects.Find(p => p.Path == path);
            if (project == null) return;
            project.DisplayName = string.IsNullOrWhiteSpace(newName) ? project.FolderName : newName;
            Save();
        }
        ProjectsChanged?.Invoke();
    }

    public void Remove(string path)
    {
        lock (_lock)
        {
            Projects.RemoveAll(p => p.Path == path);
            Save();
        }
        ProjectsChanged?.Invoke();
    }

    public void RemoveAll()
    {
        lock (_lock)
        {
            Projects.Clear();
            Save();
        }
        ProjectsChanged?.Invoke();
    }

    private void Load()
    {
        try
        {
            if (!File.Exists(_configPath)) return;
            var json = File.ReadAllText(_configPath);
            var file = JsonSerializer.Deserialize<ProjectsFile>(json, JsonOptions);
            if (file?.Projects != null)
            {
                Projects = file.Projects;
                Sort();
            }
        }
        catch { }
    }

    private void Save()
    {
        try
        {
            var file = new ProjectsFile { Projects = Projects };
            var json = JsonSerializer.Serialize(file, JsonOptions);
            File.WriteAllText(_configPath, json);
        }
        catch { }
    }

    private void Sort() => Projects.Sort((a, b) => b.LastSeen.CompareTo(a.LastSeen));

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        WriteIndented = true
    };

    private class ProjectsFile
    {
        public List<Project> Projects { get; set; } = new();
    }
}
