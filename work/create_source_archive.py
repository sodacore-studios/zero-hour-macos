from pathlib import Path
import tarfile,subprocess,io,json,argparse
root=Path(__file__).resolve().parent.parent
repo=root/'work/zero-hour-macos'
parser=argparse.ArgumentParser();parser.add_argument('--version',default='0.2.0');parser.add_argument('--stage',default='work/distribution');args=parser.parse_args()
out=root/args.stage/f'Zero-Hour-Quelltext-{args.version}.tar.gz'
files=subprocess.check_output(['git','ls-files','-z','--cached','--others','--exclude-standard'],cwd=repo).decode().split('\0')
base=f'Zero-Hour-Quelltext-{args.version}'
with tarfile.open(out,'w:gz',compresslevel=6) as tar:
 for name in files:
  if not name:continue
  p=repo/name
  if p.is_file() or p.is_symlink():tar.add(p,arcname=f'{base}/work/zero-hour-macos/{name}',recursive=False)
 deps=repo/'build/macos/_deps'
 def filt(info):
  parts=Path(info.name).parts
  if any(p in {'.git','__pycache__','node_modules','CMakeFiles'} for p in parts):return None
  if info.name.endswith(('.o','.a','.dylib','.pyc')):return None
  return info
 for p in sorted(deps.glob('*-src')):
  tar.add(p,arcname=f'{base}/dependency-sources/{p.name}',filter=filt)
 for name in ['prepare_distribution.py','prepare_complete_distribution.py']:
  tar.add(root/'work'/name,arcname=f'{base}/work/{name}')
 for name in ['Configuration.swift','main.swift']:
  assert (repo/'Platform/MacOS/PrivateLauncher'/name).exists()
 tar.add(root/'work/launcher-tests/Tests.swift',arcname=f'{base}/tests/LauncherTests.swift')
 text='''Quellen zur Zero-Hour-Mac-Testversion 0.2.0\n\nEnthalten sind die verwendeten Engine-Quellen einschließlich lokaler Änderungen,\nder neue native Launcher und die Quellen der beim Build verwendeten Abhängigkeiten.\nDie Lizenztexte liegen in den jeweiligen Quellordnern. Keine kommerziellen Spielarchive.\n\nUpstream: https://github.com/OKJID/GameClient\nCommit: '''+subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip()+'''\n\nBuild ab dem Wurzelordner dieses Archivs (Apple Silicon):\nVoraussetzungen: Xcode Command Line Tools, CMake, Ninja und benötigte Build-Werkzeuge.\n\ncmake --preset macos -S work/zero-hour-macos\ncmake --build work/zero-hour-macos/build/macos --target z_generals --parallel 4\nxcrun swiftc -O -target arm64-apple-macos13.3 work/zero-hour-macos/Platform/MacOS/PrivateLauncher/Configuration.swift work/zero-hour-macos/Platform/MacOS/PrivateLauncher/main.swift -o work/ZeroHourLauncher\npython3 work/prepare_distribution.py\nhdiutil create -volname "Zero Hour" -srcfolder work/distribution -format UDZO Zero-Hour-Mac.dmg\n\nCMake kann die versionierten Abhängigkeiten erneut herunterladen. Die beim Release\nverwendeten Quellstände sind zusätzlich unter dependency-sources enthalten.\n\nLauncher-Tests:\nxcrun swiftc work/zero-hour-macos/Platform/MacOS/PrivateLauncher/Configuration.swift tests/LauncherTests.swift -o /tmp/ZeroHourLauncherTests\n/tmp/ZeroHourLauncherTests\n'''
 text=text.replace('Testversion 0.2.0','Testversion '+args.version)
 text+='\nKomplettpaket: Launcher zusätzlich als work/ZeroHourLauncherComplete bauen,\npython3 work/prepare_complete_distribution.py --game-data /Pfad/zur/eigenen/Installation\nDie kommerziellen Spielinhalte sind nicht Bestandteil dieses Quelltextarchivs.\n'
 data=text.encode();info=tarfile.TarInfo(f'{base}/BUILD.txt');info.size=len(data);tar.addfile(info,io.BytesIO(data))
print(f'Source archive: {out.stat().st_size/1024/1024:.1f} MiB; {len(files)-1} repository paths')
