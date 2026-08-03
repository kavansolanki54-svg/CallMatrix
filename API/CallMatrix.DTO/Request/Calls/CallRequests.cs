namespace CallMatrix.DTO.Request.Calls
{
    public class CreateCallLogRequest
    {
        public int CompanyId { get; set; }
        public string PhoneNumber { get; set; } = string.Empty;
        public string? ContactName { get; set; }
        public int Duration { get; set; }
        public string CallType { get; set; } = "Incoming"; // Incoming, Outgoing, Missed
        public DateTime CallDateTime { get; set; }
        public int? DeviceId { get; set; }
        public int? CustomerId { get; set; }
    }

    public class UploadCallRecordingRequest
    {
        public int CompanyId { get; set; }
        public int CallId { get; set; }
        public string FileName { get; set; } = string.Empty;
        public string? FilePath { get; set; }
        public string? FileUrl { get; set; }
        public int Duration { get; set; }
        public long FileSize { get; set; }
        public DateTime? RecordingDate { get; set; }
    }

    public class SyncCallsRequest
    {
        public int CompanyId { get; set; }
        public int DeviceId { get; set; }
        public List<CreateCallLogRequest> Calls { get; set; } = new();
    }
}
