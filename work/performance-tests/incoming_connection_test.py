"""Exercise production incoming acceptance against deterministic transport stubs."""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[2]
source = (root / 'work/zero-hour-macos/GeneralsMD/Code/GameEngine/Source/GameNetwork/GeneralsOnline/NetworkMesh.cpp').read_text()
production = source[source.index('void NetworkMesh::AcceptIncomingConnection('):source.index('void NetworkMesh::StartConnectionSignalling(')]
preamble = r'''
#include <cassert>
#include <cstdint>
#include <cstdio>
#include <map>
#include <mutex>
#include <string>
#include <vector>
using HSteamNetConnection = unsigned;
constexpr unsigned k_HSteamNetConnection_Invalid = 0;
enum EResult { k_EResultOK, k_EResultFail };
enum class EConnectionState { CONNECTING_DIRECT };
#define NetworkLog(...) ((void)0)
struct SteamNetworkingIdentity {
    const char* value;
    const char* GetGenericString() const { return value; }
};
struct Member { int64_t user_id; };
struct Lobby { std::vector<Member> members; };
struct NGMP_OnlineServices_LobbyInterface {
    Lobby current{{{10}, {20}}};
    Lobby GetCurrentLobby() { return current; }
} lobby;
struct NGMP_OnlineServices_AuthInterface { int64_t GetUserID() { return 10; } } auth;
bool haveLobby = true, haveAuth = true;
struct NGMP_OnlineServicesManager { template<class T> static T* GetInterface(); };
template<> NGMP_OnlineServices_LobbyInterface* NGMP_OnlineServicesManager::GetInterface() { return haveLobby ? &lobby : nullptr; }
template<> NGMP_OnlineServices_AuthInterface* NGMP_OnlineServicesManager::GetInterface() { return haveAuth ? &auth : nullptr; }
struct Transport {
    EResult result = k_EResultOK;
    std::vector<unsigned> accepted, closed;
    EResult AcceptConnection(unsigned handle) { accepted.push_back(handle); return result; }
    void CloseConnection(unsigned handle, int, const char*, bool) { closed.push_back(handle); }
} transport;
Transport* SteamNetworkingSockets() { return &transport; }
class NetworkMesh;
struct PlayerConnection {
    int64_t m_userID;
    unsigned m_hSteamConnection;
    bool connecting = false;
    PlayerConnection(int64_t id, unsigned handle) : m_userID(id), m_hSteamConnection(handle) {}
    void UpdateState(EConnectionState, NetworkMesh*) { connecting = true; }
};
class NetworkMesh {
public:
    std::map<int64_t, PlayerConnection> m_mapConnections;
    std::recursive_mutex m_mapConnectionsMutex;
    void AcceptIncomingConnection(HSteamNetConnection, const SteamNetworkingIdentity&);
};
'''
tests = r'''
int main() {
    NetworkMesh mesh;
    // The original failure: no outgoing entry exists when an authorized peer arrives.
    mesh.AcceptIncomingConnection(101, {"20"});
    assert(mesh.m_mapConnections.size() == 1);
    assert(mesh.m_mapConnections.at(20).m_hSteamConnection == 101);
    assert(mesh.m_mapConnections.at(20).connecting);
    assert(transport.accepted == std::vector<unsigned>{101});
    // Never replace another handle, accept ourselves, or trust malformed/non-member IDs.
    mesh.AcceptIncomingConnection(102, {"20"});
    for (const char* identity : {"10", "30", "020", "20x", "", static_cast<const char*>(nullptr)})
        mesh.AcceptIncomingConnection(103, {identity});
    haveLobby = false; mesh.AcceptIncomingConnection(104, {"20"}); haveLobby = true;
    haveAuth = false; mesh.AcceptIncomingConnection(105, {"20"}); haveAuth = true;
    assert(transport.accepted.size() == 1 && transport.closed.size() == 9);
    assert(mesh.m_mapConnections.at(20).m_hSteamConnection == 101);
    // A transport failure must not publish a usable connection.
    NetworkMesh failed;
    transport.result = k_EResultFail;
    failed.AcceptIncomingConnection(106, {"20"});
    assert(failed.m_mapConnections.empty() && transport.closed.back() == 106);
    transport.result = k_EResultOK;
    NetworkMesh pending;
    pending.m_mapConnections.emplace(20, PlayerConnection(20, 0));
    pending.AcceptIncomingConnection(107, {"20"});
    assert(pending.m_mapConnections.at(20).m_hSteamConnection == 107);
    puts("Incoming connections: first peer, roster validation, duplicate protection and accept failure passed.");
}
'''
Path(sys.argv[1]).write_text(preamble + production + tests)
