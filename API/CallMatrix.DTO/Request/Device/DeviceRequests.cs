namespace CallMatrix.DTO.Request.Device
{
    public class RegisterDeviceRequest
    {
        public int CompanyId { get; set; }
        public string DeviceId { get; set; } = string.Empty;
        public string? IMEI { get; set; }
        public string? Manufacturer { get; set; }
        public string? Model { get; set; }
        public string? OSVersion { get; set; }
        public string? AppVersion { get; set; }
    }

    public class UpdateDevicePingRequest
    {
        public string DeviceId { get; set; } = string.Empty;
        public int? BatteryLevel { get; set; }
        public string? IPAddress { get; set; }
        public decimal? Latitude { get; set; }
        public decimal? Longitude { get; set; }
        public bool IsOnline { get; set; } = true;
    }

    public class ApproveDeviceRequest
    {
        public int UserDeviceId { get; set; }
        public bool IsApproved { get; set; }
    }

    public class BlockDeviceRequest
    {
        public int UserDeviceId { get; set; }
        public bool IsBlocked { get; set; }
    }
}
