from pathlib import Path
import argparse,hashlib,json,plistlib,shutil,subprocess,zlib
parser=argparse.ArgumentParser();parser.add_argument('--game-data',type=Path,required=True);args=parser.parse_args()
root=Path(__file__).resolve().parent.parent
stage=root/'work/distribution-complete';stage.mkdir(exist_ok=True)
app=stage/'Zero Hour.app';base=root/'work/distribution/Zero Hour.app'
if not app.exists():shutil.copytree(base,app,copy_function=shutil.copyfile)
contents=app/'Contents';res=contents/'Resources'
shutil.copyfile(root/'work/ZeroHourLauncherComplete',contents/'MacOS/ZeroHourLauncher')
(contents/'MacOS/ZeroHourLauncher').chmod(0o755)
# Reuse the engine implementation; the icon metadata needs a fresh bundle signature.
shutil.copytree(base/'Contents/Resources/Engine.app',res/'Engine.app',dirs_exist_ok=True,copy_function=shutil.copyfile)
engine=res/'Engine.app/Contents/MacOS/GeneralsOnlineZH'
expected=json.loads((root/'work/distribution/Versionskennung.json').read_text())
assert hashlib.sha256(engine.read_bytes()).hexdigest()==expected['engineSHA256']
engine.chmod(0o755)
(res/'Engine.app/Contents/Frameworks/libGameNetworkingSockets.dylib').chmod(0o755)
info=plistlib.loads((contents/'Info.plist').read_bytes());info['CFBundleShortVersionString']='0.2.1';info['CFBundleVersion']='20261014.5';info['CFBundleIconFile']='ZeroHour.icns'
(contents/'Info.plist').write_bytes(plistlib.dumps(info))
icon=root/'work/zero-hour-macos/Platform/MacOS/PrivateLauncher/ZeroHour.icns'
shutil.copyfile(icon,res/'ZeroHour.icns')
shutil.copyfile(icon,res/'Engine.app/Contents/Resources/ZeroHour.icns')
einfo=plistlib.loads((res/'Engine.app/Contents/Info.plist').read_bytes())
einfo['CFBundleIconFile']='ZeroHour.icns';einfo['CFBundleShortVersionString']='0.2.1';einfo['CFBundleVersion']='20261014.5'
(res/'Engine.app/Contents/Info.plist').write_bytes(plistlib.dumps(einfo))
subprocess.run(['codesign','--force','--sign','-',str(res/'Engine.app')],check=True)
manifest={};total=0
for folder in sorted(args.game_data.iterdir()):
 if not folder.is_dir():continue
 # Only game archives and loose game assets; no Windows binaries, account data or saves.
 selected=[p for p in folder.iterdir() if p.is_file() and (p.suffix.lower()=='.big' or p.name.lower()=='readme.doc')]
 selected += [p for p in (folder/'Data').rglob('*') if p.is_file() and not p.name.startswith('.')]
 for source in selected:
  assert not source.is_symlink(), 'Unexpected symlink in game assets'
  rel=Path(folder.name)/source.relative_to(folder)
  target=res/'Spieldaten'/rel;target.parent.mkdir(parents=True,exist_ok=True)
  shutil.copyfile(source,target)
  digest=hashlib.sha256(source.read_bytes()).hexdigest()
  assert hashlib.sha256(target.read_bytes()).hexdigest()==digest
  manifest[str(rel)]=digest;total+=target.stat().st_size
assert any(n.lower().endswith('/inizh.big') for n in manifest)
assert any(n.lower().endswith('/ini.big') for n in manifest)
(res/'Spieldaten-Pruefsummen.json').write_text(json.dumps(manifest,indent=2)+'\n')
subprocess.run(['codesign','--force','--sign','-',str(app)],check=True)
subprocess.run(['codesign','--verify','--deep','--strict',str(app)],check=True)
expected['engineSHA256']=hashlib.sha256(engine.read_bytes()).hexdigest()
expected['NativeClientCRC32']=zlib.crc32(engine.read_bytes())
expected['release']='0.2.1';(stage/'Versionskennung.json').write_text(json.dumps(expected,indent=2)+'\n')
link=stage/'Programme'
if not link.exists():link.symlink_to('/Applications')
(stage/'Installation und Hinweise.txt').write_text('''ZERO HOUR FÜR APPLE SILICON — KOMPLETTPAKET 0.2.1

INSTALLATION
1. Zero Hour.app in den Ordner Programme ziehen.
2. Zero Hour öffnen und auf Spiel starten klicken.

Generals- und Zero-Hour-Spieldateien sind in dieser Ausgabe integriert.
Eine Ordnerauswahl oder eine zusätzliche Windows-Installation ist nicht nötig.
Die App findet ihre Dateien auch nach dem Verschieben automatisch wieder.

Dieses Komplettpaket enthält die Original-Spielinhalte aus deiner Installation.
Die Lizenztexte des Originalspiels und der Community-Engine bleiben erhalten.
Original-Spielinhalte gehören nicht zum beigefügten Open-Source-Quelltext.
Spielstände, Windows-Programme, persönliche Zugangsdaten und Einladungscodes
sind nicht enthalten.

Die App ist lokal signiert, aber nicht Apple-notarisiert. macOS kann beim ersten
Start eine Freigabe unter Datenschutz & Sicherheit > Dennoch öffnen verlangen.

BEDIENUNG
WASD und Pfeiltasten: Kamera bewegen. Mausrad: zoomen.
Command + Return: Vollbild/Fenster wechseln.
Auflösung und Vollbild lassen sich im Startfenster einstellen.
Neue Auflösungen: 6016 x 3384 und 7680 x 2160.
Für 5120 x 1440-Monitore ist 3840 x 1080 eine sparsamere 32:9-Einstellung.
Die sodacore studios-Startkarte wird groß für fünf Sekunden angezeigt.

ONLINE
Server-Adresse und Einladungscode des privaten Dienstes im Startfenster eintragen.
Relay-Adresse leer lassen, wenn derselbe Server-Host UDP-Port 3478 verwendet.
Einzelspieler funktioniert ohne diese Angaben.
Die öffentliche Internet-Anbindung des bisherigen Testservers ist noch nicht fertig.
Versionskennung.json enthält die Kennung für den Server-Versionsabgleich.
Alle Teilnehmer sollten dieselbe veröffentlichte Paketversion verwenden.

DATEN UND UPDATES
Spielstände, Einstellungen und Protokoll liegen separat unter:
~/Library/Application Support/Zero Hour/
Ein Update durch Ersetzen der App lässt diese Daten erhalten.

QUELLTEXT UND LIZENZEN
Die verwendeten Community-Quellen liegen im beigefügten Quelltextarchiv.
Lizenzen und Mitwirkende: App > Contents/Resources/Lizenzen.
Original-Spiel: Electronic Arts; Verbesserungen: TheSuperHackers;
Online-Komponenten: GeneralsOnline; macOS-Port: OKJID / OKJI.
Angepasste Ausgabe: sodacore studios.

VORAUSSETZUNGEN
Apple Silicon, Deployment-Ziel macOS 13.3 oder neuer.
Ältere macOS-Versionen als die bisherigen Testsysteme wurden nicht praktisch geprüft.
''')
print(f'Complete package prepared: {len(manifest)} game files, {total/1024**3:.2f} GiB; engine CRC32: {expected["NativeClientCRC32"]}')
