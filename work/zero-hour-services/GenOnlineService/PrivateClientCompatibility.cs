namespace GenOnlineService;

// Binary admission and simulation compatibility are separate checks. Operators
// must only group builds after a deterministic cross-platform match test.
public static class PrivateClientCompatibility
{
    public static bool TryAccept(uint binaryCrc, uint legacyCrc,
        IReadOnlyDictionary<uint, uint> builds, out uint simulationCrc)
    {
        simulationCrc = 0;
        if (binaryCrc == 0) return false;
        if (builds.Count != 0)
            return builds.TryGetValue(binaryCrc, out simulationCrc) && simulationCrc != 0;
        return legacyCrc != 0 && binaryCrc == legacyCrc;
    }
}
