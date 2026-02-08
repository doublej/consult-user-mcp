using System.Text.Json;
using System.Text.Json.Serialization;

namespace DialogCLI.Models;

/// <summary>
/// JSON converter that serializes as a single string or string array.
/// </summary>
public class StringOrStringsConverter : JsonConverter<StringOrStrings>
{
    public override StringOrStrings Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        if (reader.TokenType == JsonTokenType.String)
            return new StringOrStrings(reader.GetString()!);
        if (reader.TokenType == JsonTokenType.StartArray)
        {
            var list = new List<string>();
            while (reader.Read() && reader.TokenType != JsonTokenType.EndArray)
                list.Add(reader.GetString()!);
            return new StringOrStrings(list.ToArray());
        }
        throw new JsonException("Expected string or string array");
    }

    public override void Write(Utf8JsonWriter writer, StringOrStrings value, JsonSerializerOptions options)
    {
        if (value.IsSingle)
            writer.WriteStringValue(value.Single);
        else
        {
            writer.WriteStartArray();
            foreach (var s in value.Multiple)
                writer.WriteStringValue(s);
            writer.WriteEndArray();
        }
    }
}

[JsonConverter(typeof(StringOrStringsConverter))]
public class StringOrStrings
{
    public bool IsSingle { get; }
    public string Single { get; }
    public string[] Multiple { get; }

    public StringOrStrings(string value)
    {
        IsSingle = true;
        Single = value;
        Multiple = [value];
    }

    public StringOrStrings(string[] values)
    {
        IsSingle = false;
        Single = values.Length > 0 ? values[0] : "";
        Multiple = values;
    }
}

public class ConfirmResponse
{
    public string DialogType { get; set; } = "confirm";
    public bool Confirmed { get; set; }
    public bool Cancelled { get; set; }
    public bool Dismissed { get; set; }
    public string? Answer { get; set; }
    public string? Comment { get; set; }
    public bool? Snoozed { get; set; }
    public int? SnoozeMinutes { get; set; }
    public int? RemainingSeconds { get; set; }
    public string? FeedbackText { get; set; }
    public string? Instruction { get; set; }
}

public class ChoiceResponse
{
    public string DialogType { get; set; } = "choose";
    public StringOrStrings? Answer { get; set; }
    public bool Cancelled { get; set; }
    public bool Dismissed { get; set; }
    public string? Description { get; set; }
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string?[]? Descriptions { get; set; }
    public string? Comment { get; set; }
    public bool? Snoozed { get; set; }
    public int? SnoozeMinutes { get; set; }
    public int? RemainingSeconds { get; set; }
    public string? FeedbackText { get; set; }
    public string? Instruction { get; set; }
}

public class TextInputResponse
{
    public string DialogType { get; set; } = "textInput";
    public string? Answer { get; set; }
    public bool Cancelled { get; set; }
    public bool Dismissed { get; set; }
    public string? Comment { get; set; }
    public bool? Snoozed { get; set; }
    public int? SnoozeMinutes { get; set; }
    public int? RemainingSeconds { get; set; }
    public string? FeedbackText { get; set; }
    public string? Instruction { get; set; }
}

public class NotifyResponse
{
    public string DialogType { get; set; } = "notify";
    public bool Success { get; set; }
}

