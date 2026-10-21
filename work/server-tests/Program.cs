using GenOnlineService;
static void Check(bool condition) { if (!condition) throw new Exception("Compatibility policy regression"); }
var empty = new Dictionary<uint,uint>();
Check(!PrivateClientCompatibility.TryAccept(0, 0, empty, out _));
Check(!PrivateClientCompatibility.TryAccept(12, 0, empty, out _));
Check(PrivateClientCompatibility.TryAccept(12, 12, empty, out var legacy) && legacy == 0);
Check(!PrivateClientCompatibility.TryAccept(13, 12, empty, out _));
var paired = new Dictionary<uint,uint>{{12,100},{13,100},{14,200},{15,0}};
Check(PrivateClientCompatibility.TryAccept(12, 99, paired, out var mac) && mac == 100);
Check(PrivateClientCompatibility.TryAccept(13, 99, paired, out var win) && mac == win);
Check(PrivateClientCompatibility.TryAccept(14, 99, paired, out var other) && other != mac);
Check(!PrivateClientCompatibility.TryAccept(15, 99, paired, out _));
Check(!PrivateClientCompatibility.TryAccept(99, 99, paired, out _));
Console.WriteLine("PASS: fail-closed binary admission, legacy compatibility and simulation cohorts");
