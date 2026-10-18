from pathlib import Path
import plistlib,shutil,subprocess,json,zlib,hashlib
root=Path(__file__).resolve().parent.parent
stage=root/'work/distribution';stage.mkdir(exist_ok=True)
app=stage/'Zero Hour.app';contents=app/'Contents';res=contents/'Resources'
(contents/'MacOS').mkdir(parents=True,exist_ok=True);res.mkdir(exist_ok=True)
shutil.copy2(root/'work/ZeroHourLauncher',contents/'MacOS/ZeroHourLauncher')
engine=res/'Engine.app';ec=engine/'Contents'
for name in ['MacOS','Frameworks','Resources']:(ec/name).mkdir(parents=True,exist_ok=True)
repo=root/'work/zero-hour-macos';built=repo/'build/macos/GeneralsMD/GeneralsOnlineZH.app/Contents'
shutil.copy2(built/'MacOS/GeneralsOnlineZH',ec/'MacOS/GeneralsOnlineZH')
shutil.copy2(repo/'build/macos/bin/libGameNetworkingSockets.dylib',ec/'Frameworks/libGameNetworkingSockets.dylib')
shutil.copy2(built/'Resources/MacOSShaders.metal',ec/'Resources/MacOSShaders.metal')
shutil.copy2(repo/'Platform/MacOS/PrivateLauncher/sodacore_studios.png',ec/'Resources/sodacore_studios.png')
base={'CFBundlePackageType':'APPL','CFBundleShortVersionString':'0.2.0','CFBundleVersion':'20261014.3','LSMinimumSystemVersion':'13.3','NSHighResolutionCapable':True,'NSHumanReadableCopyright':'Command & Conquer © Electronic Arts. Community port based on OKJID/GameClient. GNU GPL v3 or later. See licenses and accompanying sources.'}
for p,extra in [(contents,{'CFBundleName':'Zero Hour','CFBundleDisplayName':'Zero Hour','CFBundleExecutable':'ZeroHourLauncher','CFBundleIdentifier':'local.zerohour.launcher'}),(ec,{'CFBundleName':'Zero Hour Spiel','CFBundleDisplayName':'Zero Hour Spiel','CFBundleExecutable':'GeneralsOnlineZH','CFBundleIdentifier':'local.zerohour.engine'})]:
 (p/'Info.plist').write_bytes(plistlib.dumps(base|extra))
lic=res/'Lizenzen';lic.mkdir(exist_ok=True)
shutil.copy2(repo/'LICENSE.md',lic/'GameClient-GPL-3.md')
(lic/'Mitwirkende.txt').write_text('Command & Conquer Generals Zero Hour: Electronic Arts.\nOpen-source improvements: TheSuperHackers.\nOnline components: GeneralsOnline Development Team.\nOriginal macOS port: OKJID / OKJI.\nThis customized macOS edition: sodacore studios.\nSee the accompanying source files and license notices for full attribution.\n')
for dep in (repo/'build/macos/_deps').glob('*-src'):
 for pattern in ['LICENSE*','COPYING*','NOTICE*']:
  for p in dep.glob(pattern):
   if p.is_file():shutil.copy2(p,lic/(dep.name+'-'+p.name))
for p in [ec/'Frameworks/libGameNetworkingSockets.dylib',ec/'MacOS/GeneralsOnlineZH',engine,contents/'MacOS/ZeroHourLauncher',app]:
 subprocess.run(['codesign','--force','--sign','-',str(p)],check=True)
subprocess.run(['codesign','--verify','--deep','--strict',str(app)],check=True)
exe=ec/'MacOS/GeneralsOnlineZH'
(stage/'Versionskennung.json').write_text(json.dumps({'release':'0.2.0','NativeClientCRC32':zlib.crc32(exe.read_bytes()),'engineSHA256':hashlib.sha256(exe.read_bytes()).hexdigest(),'ver':1,'netver':1,'servicesver':1},indent=2)+'\n')
link=stage/'Programme'
if not link.exists():link.symlink_to('/Applications')
(stage/'Installation und Hinweise.txt').write_text('''ZERO HOUR FÜR APPLE SILICON — TESTVERSION 0.2.0

1. Zero Hour.app in den Ordner Programme ziehen.
2. App öffnen und den Ordner mit deiner installierten Windows-Version von
   Generals und Zero Hour auswählen. Die Original-Spieldateien gehören nicht
   zu diesem Paket. Sie müssen lokal auf dem Mac verfügbar bleiben.
3. Auflösung, Vollbild und WASD wählen. Spiel starten.

Die App ist lokal signiert, aber nicht mit einem Apple-Developer-ID-Zertifikat
signiert oder notarisiert. macOS kann beim ersten Start eine Freigabe unter
Systemeinstellungen > Datenschutz & Sicherheit > Dennoch öffnen verlangen.

BEDIENUNG
WASD und Pfeiltasten: Kamera bewegen. Mausrad: zoomen.
Command + Return: zwischen Vollbild und Fenster wechseln.
Bei aktiviertem WASD sind die ursprünglichen unmodifizierten W/A/S/D-Befehle
im Gefecht durch Kamerabewegung ersetzt. Zum klassischen Layout den Haken entfernen.
Textfelder und Chat verwenden weiterhin Buchstaben.
Auflösung lässt sich im Spiel über Options > Resolution > Accept ändern.
Zusätzlich auswählbar: 6016 x 3384 und 7680 x 2160.
Für 5120 x 1440-Monitore ist 3840 x 1080 ein sparsamerer 32:9-Modus.

EIGENER SERVER
Server-Adresse im Startfenster ändern, zum Beispiel https://spiel.example.org.
Der API-Pfad /env/prod/contract/1 wird bei Bedarf automatisch ergänzt.
Spielername und Einladungscode vom Betreiber eintragen.
Relay leer: derselbe Hostname mit UDP-Port 3478. Bei einem separaten Relay
hostname:port eintragen. Änderungen gelten ab dem nächsten Spielstart.
Ohne Server-Adresse sind Einzelspieler und Gefechte möglich.

Bei einem Server-Umzug muss auch der Betreiber die öffentliche WebSocketUrl
(wss://...), das TLS-Zertifikat und die Erreichbarkeit des TURN-Relays anpassen.
Der Relay benötigt UDP 3478 und den konfigurierten UDP-Relay-Portbereich;
ein HTTP-Reverse-Proxy allein reicht dafür nicht.
Dieses Paket enthält keinen laufenden Server und keine Einladungscodes.
Die Internet-Erreichbarkeit des bisherigen Testdienstes ist noch nicht fertig geprüft.
Alle Teilnehmer müssen dieselbe App-Version verwenden. Der Betreiber trägt den
Wert NativeClientCRC32 aus Versionskennung.json in die private Server-Konfiguration
ein. Auch bei einem eigenen Neubau muss dieser Wert erneut abgeglichen werden.

DATEN UND UPDATES
Einstellungen, Protokoll und Spielstände liegen unter:
~/Library/Application Support/Zero Hour/
Die Schaltfläche Datenordner öffnen zeigt diesen Ordner.
Ein Update erfolgt durch Ersetzen der App in Programme.

QUELLTEXT UND LIZENZEN
Engine: https://github.com/OKJID/GameClient, macos-port.
Die zu dieser Testversion gehörenden Quellen einschließlich Änderungen und
Abhängigkeiten liegen im beigefügten Quelltext-Archiv. Lizenztexte befinden
sich auch in der App unter Contents/Resources/Lizenzen.
Das Paket enthält keine kommerziellen Spielarchive, persönlichen Daten,
privaten Server-Schlüssel, Spielstände oder vorkonfigurierten Konten.

VORAUSSETZUNGEN UND TESTSTAND
Apple Silicon; Deployment-Ziel macOS 13.3 oder neuer.
Der bisherige Engine-Build läuft auf macOS 15.6.1 und dem lokalen Test-Mac.
Ältere macOS-Versionen wurden nicht praktisch geprüft.
''')
print(app)
