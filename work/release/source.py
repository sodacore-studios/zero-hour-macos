"""Archive tracked corresponding sources and fetched dependency sources only."""
from pathlib import Path
import subprocess
import sys
import tarfile
root = Path(__file__).resolve().parents[2]

def clean(info):
    parts = Path(info.name).parts
    if any(part in {'.git', '__pycache__', 'CMakeFiles', 'node_modules'} for part in parts): return None
    if info.name.endswith(('.o', '.a', '.dylib', '.pyc')): return None
    return info

with tarfile.open(sys.argv[1], 'w:gz') as archive:
    files = subprocess.check_output(['git', 'ls-files', '-z'], cwd=root).decode().split('\0')
    for name in files:
        if name and (root / name).is_file(): archive.add(root / name, arcname='Zero-Hour-Sources/' + name, recursive=False)
    for source in (root / 'work/zero-hour-macos/build/macos/_deps').glob('*-src'):
        archive.add(source, arcname='Zero-Hour-Sources/dependency-sources/' + source.name, filter=clean)
