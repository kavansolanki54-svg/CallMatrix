namespace CallMatrix.DTO.Response.Calls
{
    public class CallLogResponse
    {
        public int CallId { get; set; }
        public int CompanyId { get; set; }
        public string PhoneNumber { get; set; } = string.Empty;
        public string? ContactName { get; set; }
        public int Duration { get; set; }
        public string CallType { get; set; } = string.Empty;
        public DateTime CallDateTime { get; set; }
        public int EmployeeId { get; set; }
        public string? EmployeeName { get; set; }
        public int? DeviceId { get; set; }
        public int? CustomerId { get; set; }
        public string? CustomerName { get; set; }
        public DateTime? SyncedAt { get; set; }
        public bool HasRecording { get; set; }
        public string? RecordingUrl { get; set; }
    }

    public class CallRecordingResponse
    {
        public int CallRecordingId { get; set; }
        public int CompanyId { get; set; }
        public int CallId { get; set; }
        public string FileName { get; set; } = string.Empty;
        public string? FilePath { get; set; }
        public string? FileUrl { get; set; }
        public int Duration { get; set; }
        public long FileSize { get; set; }
        public string UploadStatus { get; set; } = string.Empty;
        public DateTime? RecordingDate { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class CallAnalyticsSummaryResponse
    {
        public int TotalCalls { get; set; }
        public int TotalIncomingCalls { get; set; }
        public int TotalOutgoingCalls { get; set; }
        public int TotalMissedCalls { get; set; }
        public long TotalDurationSeconds { get; set; }
        public double AverageDurationSeconds { get; set; }
        public int TotalRecordings { get; set; }
    }
}
