"""Package the native x86 Windows client without proprietary game data."""
import argparse, hashlib, json, shutil, struct, subprocess, zipfile, zlib
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--version',required=True);p.add_argument('--build',type=Path);args=p.parse_args()
root=Path(__file__).resolve().parents[2];source=root/'work/zero-hour-macos'
build=args.build or source/'build/windows-x86'
engine=build/'GeneralsMD/Release/GeneralsOnlineZH.exe'
if not engine.is_file(): raise SystemExit(f'Missing engine: {engine}')
out=root/'outputs'/args.version;stage=root/'work/distribution-windows'/args.version
if stage.exists(): raise SystemExit('Use a fresh staging directory')
bin=stage/'Zero Hour/bin';bin.mkdir(parents=True);out.mkdir(parents=True,exist_ok=True)
shutil.copy2(engine,bin/engine.name)
vendor=source/'GeneralsMD/Code/GameEngine/Source/GameNetwork/GeneralsOnline/Vendor'
# OpenSSL 3.5.1 from GNS supplies the shared OpenSSL 3 ABI for both libraries.
files=['ValveNetworkingSockets/GameNetworkingSockets.dll','ValveNetworkingSockets/abseil_dll.dll','ValveNetworkingSockets/libprotobuf.dll','ValveNetworkingSockets/libssl-3.dll','ValveNetworkingSockets/libcrypto-3.dll','libcurl/libcurl.dll','libcurl/zlib1.dll','DiscordRPC/discord-rpc.dll']
for name in files: shutil.copy2(vendor/name,bin/Path(name).name)
# App-local Microsoft C++ runtime, obtained from the installed build tools.
vswhere=Path('C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe')
vs=Path(subprocess.check_output([str(vswhere),'-latest','-products','*','-requires','Microsoft.VisualStudio.Component.VC.Tools.x86.x64','-property','installationPath'],text=True).strip())
crts=sorted((vs/'VC/Redist/MSVC').glob('*/x86/Microsoft.VC143.CRT'))
if not crts:raise SystemExit('Missing redistributable C++ runtime')
for dll in crts[-1].glob('*.dll'):shutil.copy2(dll,bin/dll.name)
for dll in bin.iterdir():
 b=dll.read_bytes();pe=struct.unpack_from('<I',b,60)[0]
 if b[pe:pe+4]!=b'PE\0\0' or struct.unpack_from('<H',b,pe+4)[0]!=0x14c:raise SystemExit(f'Not x86 PE: {dll.name}')
for name in ['Start-ZeroHour.cmd','Launcher.ps1']:shutil.copy2(root/'work/windows'/name,stage/'Zero Hour'/name)
shutil.copy2(root/'docs/WINDOWS.md',stage/'Zero Hour/READ ME.txt')
licenses=stage/'Zero Hour/Licenses';licenses.mkdir()
shutil.copy2(source/'LICENSE.md',licenses/'GameClient-GPL-3.md')
shutil.copy2(vendor/'DiscordRPC/LICENSE.txt',licenses/'DiscordRPC.txt')
for dep in (build/'_deps').glob('*-src'):
 for pattern in ['LICENSE*','COPYING*','NOTICE*']:
  for f in dep.glob(pattern):
   if f.is_file():shutil.copy2(f,licenses/(dep.name+'-'+f.name))
manifest={'version':args.version,'platform':'windows-x86','engineCRC32':zlib.crc32(engine.read_bytes()),'engineSHA256':hashlib.sha256(engine.read_bytes()).hexdigest(),'files':{str(f.relative_to(stage/'Zero Hour')):hashlib.sha256(f.read_bytes()).hexdigest() for f in sorted(stage.rglob('*')) if f.is_file()}}
(stage/'Zero Hour/Version.json').write_text(json.dumps(manifest,indent=2)+'\n')
assert not list(stage.rglob('*.big'))
archive=out/f'Zero-Hour-{args.version}-windows-x86.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for f in sorted(stage.rglob('*')):
  if f.is_file():z.write(f,f.relative_to(stage))
(out/'Windows-Version.json').write_text(json.dumps(manifest,indent=2)+'\n')
(out/'Windows-SHA256SUMS.txt').write_text(f'{hashlib.sha256(archive.read_bytes()).hexdigest()}  {archive.name}\n')
print(archive)

delivery=root/'outputs/windows-delivery'
delivery.mkdir(parents=True,exist_ok=True)
for f in [archive,out/'Windows-Version.json',out/'Windows-SHA256SUMS.txt']:
    shutil.copy2(f,delivery/f.name)
