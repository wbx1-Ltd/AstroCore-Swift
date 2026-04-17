/// How to resolve a repeated local wall-clock time during a DST fall-back.
public enum RepeatedTimeResolution: String, Sendable, Hashable, Codable {
    /// Reject ambiguous wall-clock times and ask the caller to choose explicitly.
    case reject
    /// Use the first occurrence of the repeated local time.
    case firstOccurrence
    /// Use the last occurrence of the repeated local time.
    case lastOccurrence
}
