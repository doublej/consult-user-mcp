namespace ConsultUserMCP.Models;

public class SnoozeState
{
    public DateTime? SnoozeUntil { get; set; }
    public List<SnoozedRequest> SnoozedRequests { get; set; } = [];
}

public class SnoozedRequest
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public string ClientName { get; set; } = "";
    public string DialogType { get; set; } = "";
    public string Summary { get; set; } = "";
}
