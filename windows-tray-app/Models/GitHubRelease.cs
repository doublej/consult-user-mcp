namespace ConsultUserMCP.Models;

public class GitHubRelease
{
    public string TagName { get; set; } = "";
    public string Name { get; set; } = "";
    public bool Prerelease { get; set; }
    public string HtmlUrl { get; set; } = "";
    public List<GitHubAsset> Assets { get; set; } = [];
}

public class GitHubAsset
{
    public string Name { get; set; } = "";
    public string BrowserDownloadUrl { get; set; } = "";
    public long Size { get; set; }
}
