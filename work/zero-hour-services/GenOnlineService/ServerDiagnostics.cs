using System.Diagnostics;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Channels;

namespace GenOnlineService;

public enum DiagnosticKind
{
    ServiceStarted, ServiceStopping, Health, SlowRequest, RequestFailed,
    SocketConnected, SocketDisconnected, MatchAssigned, LobbyState,
    PlayerDisconnected, PlayerReconnected, PlayerOutcome, ConnectionOutcome
}

// Deliberately no request payloads, names, addresses, tokens or exception messages.
public sealed record DiagnosticEvent(DiagnosticKind Kind)
{
    public DateTimeOffset Utc { get; init; } = DateTimeOffset.UtcNow;
    public string? Boot { get; init; }
    public long? Lobby { get; init; }
    public ulong? Match { get; init; }
    public long? Player { get; init; }
    public long? Peer { get; init; }
    public int? State { get; init; }
    public bool? Direct { get; init; }
    public bool? IPv4 { get; init; }
    public bool? Reconnect { get; init; }
    public bool? Won { get; init; }
    public string? Controller { get; init; }
    public int? Status { get; init; }
    public double? DurationMs { get; init; }
    public double? SchedulerDelayMs { get; init; }
    public double? CpuPercent { get; init; }
    public long? WorkingSetBytes { get; init; }
    public int? Players { get; init; }
    public int? Lobbies { get; init; }
    public long? DroppedEvents { get; init; }
}

public sealed class DiagnosticFileWriter
{
    public static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
        Converters = { new JsonStringEnumConverter(JsonNamingPolicy.SnakeCaseLower) }
    };
    private readonly string directory;
    private readonly long maxBytes;
    private readonly int maxFiles;
    private readonly int retentionDays;
    private string? currentFile;
    private long currentBytes;
    private DateOnly currentDay;

    public DiagnosticFileWriter(string directory, long maxBytes, int maxFiles, int retentionDays)
    {
        this.directory = Path.GetFullPath(directory);
        this.maxBytes = Math.Clamp(maxBytes, 1024, 64 * 1024 * 1024);
        this.maxFiles = Math.Clamp(maxFiles, 1, 32);
        this.retentionDays = Math.Clamp(retentionDays, 1, 30);
        Directory.CreateDirectory(this.directory);
    }

    public async Task WriteAsync(DiagnosticEvent item)
    {
        string line = JsonSerializer.Serialize(item, JsonOptions) + "\n";
        long bytes = Encoding.UTF8.GetByteCount(line);
        var now = DateTimeOffset.UtcNow;
        var day = DateOnly.FromDateTime(now.UtcDateTime);
        if (currentFile == null || currentBytes + bytes > maxBytes || day != currentDay)
        {
            currentFile = Path.Combine(directory, $"diagnostics-{now:yyyyMMdd-HHmmssfff}-{Guid.NewGuid():N}.jsonl");
            currentBytes = 0;
            currentDay = day;
            // Reserve space for the new file; never touch files outside our namespace.
            var previous = Directory.GetFiles(directory, "diagnostics-*.jsonl")
                .OrderByDescending(File.GetLastWriteTimeUtc).ToArray();
            for (int i = 0; i < previous.Length; ++i)
                if (i >= maxFiles - 1 || File.GetLastWriteTimeUtc(previous[i]) < now.UtcDateTime.AddDays(-retentionDays))
                    File.Delete(previous[i]);
        }
        await File.AppendAllTextAsync(currentFile, line, new UTF8Encoding(false));
        currentBytes += bytes;
    }
}

public sealed class ServerDiagnostics : BackgroundService
{
    private static ServerDiagnostics? current;
    private readonly IConfiguration configuration;
    private readonly IServiceProvider services;
    private readonly Channel<DiagnosticEvent> queue = Channel.CreateBounded<DiagnosticEvent>(
        new BoundedChannelOptions(2048) { SingleReader = true, FullMode = BoundedChannelFullMode.Wait });
    private readonly string boot = Guid.NewGuid().ToString("N");
    private long dropped;
    private bool warnedStorage;

    public ServerDiagnostics(IConfiguration configuration, IServiceProvider services)
    { this.configuration = configuration; this.services = services; }

    public static void Record(DiagnosticEvent item)
    {
        var sink = Volatile.Read(ref current);
        if (sink != null && !sink.queue.Writer.TryWrite(item with { Boot = sink.boot }))
            Interlocked.Increment(ref sink.dropped);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!configuration.GetValue<bool>("Diagnostics:Enabled")) return;
        DiagnosticFileWriter writer;
        try
        {
            writer = new DiagnosticFileWriter(configuration["Diagnostics:Directory"] ?? "Diagnostics",
                configuration.GetValue<long?>("Diagnostics:MaxFileBytes") ?? 4 * 1024 * 1024,
                configuration.GetValue<int?>("Diagnostics:MaxFiles") ?? 8,
                configuration.GetValue<int?>("Diagnostics:RetentionDays") ?? 7);
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or ArgumentException)
        {
            Console.Error.WriteLine("[Diagnostics] Unable to initialize diagnostic storage.");
            return;
        }
        Volatile.Write(ref current, this);
        Record(new(DiagnosticKind.ServiceStarted));
        Task heartbeat = SampleHealthAsync(stoppingToken);
        try
        {
            await foreach (var item in queue.Reader.ReadAllAsync())
            {
                try { await writer.WriteAsync(item); }
                catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
                {
                    // Disk failures must not affect gameplay or create an unbounded queue.
                    Interlocked.Increment(ref dropped);
                    if (!warnedStorage)
                    {
                        Console.Error.WriteLine("[Diagnostics] Storage write failed; diagnostic events are being dropped.");
                        warnedStorage = true;
                    }
                }
            }
        }
        finally
        {
            Volatile.Write(ref current, null);
            try { await heartbeat; } catch (OperationCanceledException) { }
        }
    }

    private async Task SampleHealthAsync(CancellationToken cancellation)
    {
        using var process = Process.GetCurrentProcess();
        using var timer = new PeriodicTimer(TimeSpan.FromSeconds(30));
        long last = Stopwatch.GetTimestamp();
        TimeSpan lastCpu = process.TotalProcessorTime;
        while (await timer.WaitForNextTickAsync(cancellation))
        {
            double elapsed = Stopwatch.GetElapsedTime(last).TotalMilliseconds;
            last = Stopwatch.GetTimestamp();
            process.Refresh();
            TimeSpan cpu = process.TotalProcessorTime;
            Record(new(DiagnosticKind.Health)
            {
                DurationMs = Math.Round(elapsed, 1), SchedulerDelayMs = Math.Round(Math.Max(0, elapsed - 30000), 1),
                CpuPercent = Math.Round((cpu - lastCpu).TotalMilliseconds / Math.Max(1, elapsed) * 100, 2),
                WorkingSetBytes = process.WorkingSet64,
                Players = WebSocketManager.GetNumberOfUsersOnline(),
                Lobbies = services.GetRequiredService<LobbyManager>().GetNumLobbies(),
                DroppedEvents = Interlocked.Read(ref dropped)
            });
            lastCpu = cpu;
        }
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        Record(new(DiagnosticKind.ServiceStopping));
        queue.Writer.TryComplete();
        await base.StopAsync(cancellationToken);
    }
}
