using System.Text.Json;
using GenOnlineService;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

public static class DiagnosticsTests
{
    static void Check(bool value, string message) { if (!value) throw new Exception(message); }
    public static async Task Run()
    {
        string root = Path.Combine(Path.GetTempPath(), "zero-hour-diagnostics-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(root);
        try
        {
            string old = Path.Combine(root, "diagnostics-old.jsonl");
            await File.WriteAllTextAsync(old, "old");
            File.SetLastWriteTimeUtc(old, DateTime.UtcNow.AddDays(-10));
            string unrelated = Path.Combine(root, "operator-notes.txt");
            await File.WriteAllTextAsync(unrelated, "preserve");
            var writer = new DiagnosticFileWriter(root, 1024, 3, 7);
            for (int i = 0; i < 100; ++i)
                await writer.WriteAsync(new(DiagnosticKind.ConnectionOutcome)
                { Lobby = 42, Match = 99, Player = 1, Peer = 2, State = 3, Direct = false, IPv4 = true });
            var files = Directory.GetFiles(root, "diagnostics-*.jsonl");
            Check(files.Length <= 3, "Rotation did not bound file count");
            Check(!File.Exists(old) && File.Exists(unrelated), "Retention scope is incorrect");
            foreach (string file in files)
            {
                Check(new FileInfo(file).Length <= 1024, "File exceeds configured rotation bound");
                foreach (string line in await File.ReadAllLinesAsync(file))
                {
                    using var doc = JsonDocument.Parse(line);
                    var data = doc.RootElement;
                    Check(data.GetProperty("kind").GetString() == "connection_outcome", "Event schema mismatch");
                    Check(data.GetProperty("match").GetUInt64() == 99, "Match correlation lost");
                    Check(data.GetProperty("utc").GetDateTimeOffset().Offset == TimeSpan.Zero, "Timestamp is not UTC");
                    Check(!data.TryGetProperty("invitation", out _) && !data.TryGetProperty("ip", out _), "Sensitive fields present");
                }
            }

            string hostedPath = Path.Combine(root, "hosted");
            var configuration = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
            { ["Diagnostics:Enabled"] = "true", ["Diagnostics:Directory"] = hostedPath }).Build();
            using var services = new ServiceCollection().BuildServiceProvider();
            using var hosted = new ServerDiagnostics(configuration, services);
            await hosted.StartAsync(CancellationToken.None);
            using var deadline = new CancellationTokenSource(TimeSpan.FromSeconds(5));
            while (!Directory.Exists(hostedPath) || Directory.GetFiles(hostedPath).Length == 0)
                await Task.Delay(10, deadline.Token);
            ServerDiagnostics.Record(new(DiagnosticKind.PlayerDisconnected) { Lobby = 42, Match = 99, Player = 1 });
            await hosted.StopAsync(deadline.Token);
            string output = string.Join("\n", Directory.GetFiles(hostedPath).Select(File.ReadAllText));
            Check(output.Contains("service_started") && output.Contains("player_disconnected") && output.Contains("service_stopping"),
                "Hosted writer did not drain lifecycle events on shutdown");
            Check(output.Contains("\"boot\""), "Restart correlation missing");
            Console.WriteLine("PASS: diagnostic JSON schema, match correlation, UTC, rotation, retention and shutdown flush");
        }
        finally { Directory.Delete(root, true); }
    }
}
