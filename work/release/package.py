"""Build asset-free, signed ARM64 release archives. Original game content stays local."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import zlib

ROOT = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser()
p.add_argument('--version', required=True)
p.add_argument('--engine', type=Path, help='Reuse a previously verified Engine.app without modifying its signed executable')
p.add_argument('--key', type=Path, required=True)
args = p.parse_args()
assert len(args.version.split('.')) == 3 and all(x.isascii() and x.isdigit() for x in args.version.split('.'))
version = args.version
out = ROOT / 'outputs' / version
stage = ROOT / 'work' / 'distribution-release' / version
assert not stage.exists(), 'Use a fresh version/staging directory'
stage.mkdir(parents=True)
out.mkdir(parents=True, exist_ok=True)
app = stage / 'Zero Hour.app'
contents = app / 'Contents'
resources = contents / 'Resources'
macos = contents / 'MacOS'
macos.mkdir(parents=True); resources.mkdir()
repo = ROOT / 'work/zero-hour-macos'
launcher = repo / 'Platform/MacOS/PrivateLauncher'
cache = ROOT / 'work/swift-module-cache'

def run(*cmd):
    subprocess.run([str(x) for x in cmd], check=True)

def compile_swift(output, *files):
    run('xcrun', 'swiftc', '-O', '-target', 'arm64-apple-macos13.3', '-module-cache-path', cache, *files, '-o', output)

compile_swift(macos / 'ZeroHourLauncher', *[launcher / x for x in ['Configuration.swift', 'UpdateCore.swift', 'Updater.swift', 'main.swift']])
compile_swift(macos / 'ZeroHourUpdateHelper', launcher / 'UpdateCore.swift', launcher / 'UpdateHelper.swift')
engine = resources / 'Engine.app'
if args.engine:
    shutil.copytree(args.engine, engine, symlinks=True)
else:
    built = repo / 'build/macos/GeneralsMD/GeneralsOnlineZH.app'
    shutil.copytree(built, engine, symlinks=True)
    (engine / 'Contents/Frameworks').mkdir(exist_ok=True)
    shutil.copy2(repo / 'build/macos/bin/libGameNetworkingSockets.dylib', engine / 'Contents/Frameworks/libGameNetworkingSockets.dylib')
    shutil.copy2(launcher / 'sodacore_studios.png', engine / 'Contents/Resources/sodacore_studios.png')
    for file in (engine / 'Contents/Frameworks').glob('*.dylib'):
        run('codesign', '--force', '--sign', '-', file)
    run('codesign', '--force', '--sign', '-', engine)
# Fail closed on local/bundled content: release downloads require a licensed installation.
assert not list(app.rglob('*.big'))
assert not list(app.rglob('*Abrams*'))
shutil.copy2(launcher / 'ZeroHour.icns', resources / 'ZeroHour.icns')
lic = resources / 'Licenses'; lic.mkdir()
shutil.copy2(repo / 'LICENSE.md', lic / 'GameClient-GPL-3.md')
(lic / 'Credits.txt').write_text('Command & Conquer: Electronic Arts. Open-source improvements: TheSuperHackers. Online components: GeneralsOnline Development Team. Original macOS port: OKJID / OKJI. This edition: sodacore studios. Full attribution and corresponding sources accompany this release.\n')
for dependency in (repo / 'build/macos/_deps').glob('*-src'):
    for pattern in ['LICENSE*', 'COPYING*', 'NOTICE*']:
        for file in dependency.glob(pattern):
            if file.is_file(): shutil.copy2(file, lic / (dependency.name + '-' + file.name))
if args.engine:
    old_licenses = args.engine.parent / 'Lizenzen'
    if old_licenses.exists(): shutil.copytree(old_licenses, lic / 'Dependencies', dirs_exist_ok=True)
info = dict(CFBundlePackageType='APPL', CFBundleIdentifier='net.sodacore.zerohour', CFBundleName='Zero Hour',
    CFBundleDisplayName='Zero Hour', CFBundleExecutable='ZeroHourLauncher', CFBundleIconFile='ZeroHour.icns',
    CFBundleShortVersionString=version, CFBundleVersion=version, LSMinimumSystemVersion='13.3',
    NSHighResolutionCapable=True, ZeroHourUpdatePublicKey=(ROOT / 'work/release/update-public-key.txt').read_text().strip(),
    NSHumanReadableCopyright='Command & Conquer © Electronic Arts. Community port based on OKJID/GameClient. GPL v3 or later. See accompanying licenses and sources.')
(contents / 'Info.plist').write_bytes(plistlib.dumps(info))
for file in [macos / 'ZeroHourUpdateHelper', macos / 'ZeroHourLauncher', app]: run('codesign', '--force', '--sign', '-', file)
run('codesign', '--verify', '--deep', '--strict', app)
exe = engine / 'Contents/MacOS/GeneralsOnlineZH'
assert subprocess.check_output(['lipo', '-archs', str(exe)], text=True).strip() == 'arm64'
for binary in [exe, *list((engine / 'Contents/Frameworks').glob('*.dylib'))]:
    deps = '\n'.join(subprocess.check_output(['otool', '-L', str(binary)], text=True).splitlines()[1:])
    assert '/opt/homebrew/' not in deps and '/Users/' not in deps, 'Unbundled dependency'
metadata = {'version': version, 'architecture': 'arm64', 'NativeClientCRC32': zlib.crc32(exe.read_bytes()),
    'engineSHA256': hashlib.sha256(exe.read_bytes()).hexdigest(), 'sourceCommit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
    'builtAtUTC': __import__('datetime').datetime.now(__import__('datetime').timezone.utc).isoformat()}
(out / 'Version.json').write_text(json.dumps(metadata, indent=2) + '\n')
archive = out / f'Zero-Hour-{version}-macOS-arm64.zip'
run('ditto', '-c', '-k', '--sequesterRsrc', '--keepParent', app, archive)
manifest = {'version': version, 'architecture': 'arm64', 'minimumSystemVersion': '13.3.0',
    'bundleIdentifier': info['CFBundleIdentifier'], 'archive': archive.name, 'sha256': hashlib.sha256(archive.read_bytes()).hexdigest(), 'size': archive.stat().st_size}
(out / 'update.json').write_text(json.dumps(manifest, indent=2) + '\n')
compile_swift(out / 'sign-tool', ROOT / 'work/release/sign.swift')
run(out / 'sign-tool', 'sign', args.key.resolve(), out / 'update.json', out / 'update.sig')
(out / 'sign-tool').unlink()
# Publish corresponding source, including the dependency trees used in the native build.
run('python3', ROOT / 'work/release/source.py', str(out / f'Zero-Hour-{version}-Sources.tar.gz'))
shutil.copy2(ROOT / 'docs/INSTALLATION.md', stage / 'READ ME.txt')
shutil.copy2(out / 'Version.json', stage / 'Version.json')
(stage / 'Applications').symlink_to('/Applications')
dmg = out / f'Zero-Hour-{version}-macOS-arm64.dmg'
run('hdiutil', 'create', '-volname', 'Zero Hour', '-srcfolder', stage, '-format', 'UDZO', dmg)
run('hdiutil', 'verify', dmg)
(out / 'SHA256SUMS').write_text(''.join(hashlib.sha256(file.read_bytes()).hexdigest() + '  ' + file.name + '\n' for file in sorted(out.iterdir()) if file.is_file() and file.name != 'SHA256SUMS'))
print(json.dumps(metadata, indent=2))
