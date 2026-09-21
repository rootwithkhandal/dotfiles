# Windows Registry Tweaks

Registry files are split by intent:

- `add/`: enables or adds Explorer/context-menu behavior.
- `remove/`: disables or removes the matching behavior.
- `backup/`: full exported backup files, kept for recovery only.

Import one file at a time and review it before applying. Prefer importing from an elevated PowerShell prompt with `reg import <file.reg>`.
