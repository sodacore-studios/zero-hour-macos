"""Increment the 0.3 release line; version/tag creation only runs after checks."""
import subprocess
versions = []
for tag in subprocess.check_output(['git', 'tag', '--list', 'v0.3.*'], text=True).splitlines():
    fields = tag[1:].split('.')
    if len(fields) == 3 and all(x.isdigit() for x in fields): versions.append(tuple(map(int, fields)))
patch = max((x[2] for x in versions), default=-1) + 1
print(f'version=0.3.{patch}')
