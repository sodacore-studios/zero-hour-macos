using System.Text;
using System.Text.Json;
using GenOnlineService;
using GenOnlineService.Controllers;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;

static void Check(bool value, string name) { if (!value) throw new Exception(name); }
static void Configure(params (string, string)[] entries) {
    var values = new Dictionary<string,string?> { ["PrivateService:Enabled"]="true", ["PrivateService:NativeClientCRC32"]="12" };
    foreach (var (key,value) in entries) values["PrivateService:AcceptedClients:"+key]=value;
    GenOnlineService.Program.g_Config = new ConfigurationBuilder().AddInMemoryCollection(values).Build();
}
static async Task<POST_VersionCheck_Result> Call(string json) {
    var context=new DefaultHttpContext();context.Request.Body=new MemoryStream(Encoding.UTF8.GetBytes(json));
    var controller=new VersionCheckController { ControllerContext=new ControllerContext { HttpContext=context } };
    return (POST_VersionCheck_Result)await controller.Post();
}
static string Request(uint crc, int? net=null) => JsonSerializer.Serialize(new {
    execrc=crc, ver=Constants.GENERALS_ONLINE_VERSION,
    netver=net ?? Constants.GENERALS_ONLINE_NET_VERSION,
    servicesver=Constants.GENERALS_ONLINE_SERVICE_VERSION });
Configure();
Check((await Call(Request(12))).result==EVersionCheckResult.OK,"Legacy client rejected");
Check((await Call(Request(13))).result==EVersionCheckResult.Failed,"Unknown legacy client admitted");
Configure(("12","100"),("13","100"));
var mac=await Call(Request(12));var win=await Call(Request(13));
Check(mac.result==EVersionCheckResult.OK && win.result==EVersionCheckResult.OK && mac.simulation_crc==100 && win.simulation_crc==100,"Paired build response failed");
Check((await Call(Request(14))).result==EVersionCheckResult.Failed,"Unknown binary admitted");
var wrong=await Call(Request(12,-1));Check(wrong.result==EVersionCheckResult.Failed && wrong.simulation_crc==0,"Protocol mismatch admitted or leaked seed");
foreach(var malformed in new[]{"{}","null","{","{\"ver\":1,\"netver\":1,\"servicesver\":1}"})
    Check((await Call(malformed)).result==EVersionCheckResult.Failed,"Malformed request admitted");
Configure(("12","0"));Check((await Call(Request(12))).result==EVersionCheckResult.Failed,"Zero seed fell back to legacy");
Configure(("invalid","100"));Check((await Call(Request(12))).result==EVersionCheckResult.Failed,"Invalid key fell back to legacy");
Configure(("12","overflow"));Check((await Call(Request(12))).result==EVersionCheckResult.Failed,"Invalid seed admitted");
Console.WriteLine("PASS: actual VersionCheck controller parses requests, rejects malformed configuration and gates simulation seeds");
