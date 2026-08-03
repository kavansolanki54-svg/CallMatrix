namespace CallMatrix.DTO.Response.Device
{
    public class DeviceResponse
    {
        public int UserDeviceId { get; set; }
        public int CompanyId { get; set; }
        public int EmployeeId { get; set; }
        public string? EmployeeName { get; set; }
        public string DeviceId { get; set; } = string.Empty;
        public string? IMEI { get; set; }
        public string? Manufacturer { get; set; }
        public string? Model { get; set; }
        public string? OSVersion { get; set; }
        public string? AppVersion { get; set; }
        public int? BatteryLevel { get; set; }
        public string? IPAddress { get; set; }
        public DateTime? LastSyncAt { get; set; }
        public decimal? Latitude { get; set; }
        public decimal? Longitude { get; set; }
        public bool IsOnline { get; set; }
        public bool IsApproved { get; set; }
        public bool IsBlocked { get; set; }
        public string? Status { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
