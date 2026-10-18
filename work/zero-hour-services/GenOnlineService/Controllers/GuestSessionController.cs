// Self-hosted Zero Hour: invited guests need no external account or browser login.
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;

namespace GenOnlineService.Controllers;

public record GuestSessionRequest(string display_name, string invitation);

[ApiController]
[AllowAnonymous]
[Route("env/{environment}/contract/{contract_version}/GuestSession")]
public class GuestSessionController(IDbContextFactory<AppDbContext> dbFactory, IConfiguration config) : ControllerBase
{
    private static readonly SemaphoreSlim Gate = new(1, 1);

    [HttpPost]
    [RequestSizeLimit(2048)]
    public async Task<IActionResult> Post(GuestSessionRequest request, string environment,
        [FromRoute(Name = "contract_version")] string contractVersion)
    {
        if (!config.GetValue<bool>("PrivateService:Enabled")) return NotFound();
        var expected = config["PrivateService:InvitationSHA256"] ?? "";
        if (expected.Length != 64 || request.invitation is null || request.invitation.Length > 256)
            return Unauthorized();
        var actual = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(request.invitation)));
        if (!SecretComparer.FixedTimeEquals(actual.ToLowerInvariant(), expected.ToLowerInvariant()))
            return Unauthorized();
        var name = request.display_name?.Trim() ?? "";
        if (!Regex.IsMatch(name, @"\A[\p{L}\p{N} _.-]{2,24}\z"))
            return BadRequest(new { error = "Choose a name with 2–24 letters, digits, spaces, dots, underscores or hyphens." });
        if (Program.g_tokenGenerator is null) return StatusCode(503);

        await Gate.WaitAsync(HttpContext.RequestAborted);
        try
        {
            await using var db = await dbFactory.CreateDbContextAsync(HttpContext.RequestAborted);
            // Bound guest creation even when a private invitation is shared widely.
            if (await db.Users.CountAsync(u => u.AccountType == EAccountType.PrivateGuest) >= 1000)
                return StatusCode(503, new { error = "Guest capacity reached." });
            var ip = IPHelpers.NormalizeIP(HttpContext.Connection.RemoteIpAddress?.ToString());
            var client = KnownClients.EKnownClients.gen_online_60hz;
            var type = EUserSessionType.GameClient;
            var user = new User { AccountType = EAccountType.PrivateGuest, DisplayName = name,
                ClientID = client, LastLogin = DateTime.UtcNow, LastIPAddress = ip };
            db.Users.Add(user);
            await db.SaveChangesAsync(HttpContext.RequestAborted);
            var tokens = Program.g_tokenGenerator;
            var session = tokens.GenerateToken(name, user.ID, ip, Program.JwtTokenGenerator.ETokenType.Session, client, type, false);
            var refresh = tokens.GenerateToken(name, user.ID, ip, Program.JwtTokenGenerator.ETokenType.Refresh, client, type, false, out string jti);
            await TokenRevocationManager.OnTokensIssued(user.ID, type, jti);
            await SessionHelpers.SetUsedLoggedIn(user.ID, client, type);
            return Ok(new { result = 1, session_token = session, refresh_token = refresh,
                user_id = user.ID, display_name = name,
                ws_uri = config["PrivateService:WebSocketUrl"] ?? Program.BuildWebSocketUrl(Request, environment, contractVersion) });
        }
        finally { Gate.Release(); }
    }
}
