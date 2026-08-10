using Callalyze.Extensions;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// 1. Serilog Setup
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.File("Logs/Callalyze-.log", rollingInterval: RollingInterval.Day)
    .CreateLogger();

builder.Host.UseSerilog();

// 2. Application Service Registration via Extension
builder.Services.AddApplicationServices(builder.Configuration);

// 3. Controllers
builder.Services.AddControllers(options =>
{
    options.Filters.Add<ActivityLogFilter>();
});
builder.Services.AddEndpointsApiExplorer();

var app = builder.Build();

// 4. Middleware Pipeline
app.UseCustomExceptionMiddleware();

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Callalyze API v1");
    c.RoutePrefix = string.Empty; // serves Swagger UI at the application's root
});

app.UseSerilogRequestLogging();
app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

var provider = new Microsoft.AspNetCore.StaticFiles.FileExtensionContentTypeProvider();
provider.Mappings[".3gp"] = "audio/3gpp";
provider.Mappings[".3gpp"] = "audio/3gpp";
provider.Mappings[".amr"] = "audio/amr";
provider.Mappings[".m4a"] = "audio/mp4";
provider.Mappings[".mp3"] = "audio/mpeg";
provider.Mappings[".wav"] = "audio/wav";
provider.Mappings[".ogg"] = "audio/ogg";

app.UseStaticFiles(new StaticFileOptions
{
    ContentTypeProvider = provider,
    OnPrepareResponse = ctx =>
    {
        ctx.Context.Response.Headers.Append("Access-Control-Allow-Origin", "*");
        ctx.Context.Response.Headers.Append("Access-Control-Allow-Headers", "*");
        ctx.Context.Response.Headers.Append("Access-Control-Allow-Methods", "*");
    }
});
var recordingsPath = System.IO.Path.Combine(app.Environment.ContentRootPath, "recordings");
if (!System.IO.Directory.Exists(recordingsPath))
{
    System.IO.Directory.CreateDirectory(recordingsPath);
}

app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(recordingsPath),
    RequestPath = "/recordings",
    ContentTypeProvider = provider,
    OnPrepareResponse = ctx =>
    {
        ctx.Context.Response.Headers.Append("Access-Control-Allow-Origin", "*");
        ctx.Context.Response.Headers.Append("Access-Control-Allow-Headers", "*");
        ctx.Context.Response.Headers.Append("Access-Control-Allow-Methods", "*");
    }
});

// FFmpeg Initialization for audio compression
var ffmpegPath = System.IO.Path.Combine(app.Environment.ContentRootPath, "ffmpeg");
if (!System.IO.Directory.Exists(ffmpegPath))
{
    System.IO.Directory.CreateDirectory(ffmpegPath);
}
Xabe.FFmpeg.FFmpeg.SetExecutablesPath(ffmpegPath);

_ = System.Threading.Tasks.Task.Run(async () =>
{
    try
    {
        bool isWindows = System.Runtime.InteropServices.RuntimeInformation.IsOSPlatform(System.Runtime.InteropServices.OSPlatform.Windows);
        string executableName = isWindows ? "ffmpeg.exe" : "ffmpeg";
        string binaryPath = System.IO.Path.Combine(ffmpegPath, executableName);

        if (!System.IO.File.Exists(binaryPath))
        {
            System.Console.WriteLine($"[FFmpeg] Binary not found at '{binaryPath}'. Starting download in background...");
            await Xabe.FFmpeg.Downloader.FFmpegDownloader.GetLatestVersion(Xabe.FFmpeg.Downloader.FFmpegVersion.Official, ffmpegPath);
            System.Console.WriteLine("[FFmpeg] Download completed successfully.");
        }
        else
        {
            System.Console.WriteLine("[FFmpeg] Binary already exists. Skipping download.");
        }
    }
    catch (System.Exception ex)
    {
        System.Console.Error.WriteLine($"[FFmpeg] Failed to download FFmpeg: {ex.Message}");
    }
});

app.MapControllers();

app.Run();
