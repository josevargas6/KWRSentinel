# KWR Sentinel Release Handoff

Status: distribution-prep

Date: 2026-07-17

## Product Scope

KWR Sentinel is the official compact non-commander player client for Knomercy
War Room. The release scope is:

- one commander-linked execution card;
- one target-confirmation cue;
- one conservative readiness alert;
- same-client KWR bridge only until the transport spec gates are implemented.

It is not a reporter map, enemy table, tactical board, Discord bot, or second
commander UI.

## GitHub

- KWR source repo: `https://github.com/josevargas6/KnomercyWarRoom`
- Sentinel source repo: `https://github.com/josevargas6/KWRSentinel`
- Current local limitation: this checkout has no `.git` directory and this
  shell does not provide `git`, so source sync must use GitHub API operations
  or a Git-enabled shell.

## CurseForge Package Requirements

The Sentinel upload artifact must be the `KWRSentinel_<VERSION>.zip` file
created by:

```powershell
./tools/build.ps1 -IncludeSentinel
```

Upload only the dedicated Sentinel archive to the Sentinel CurseForge project.
Do not upload the KWR distribution archive, developer archive, Discord bot
files, local SavedVariables, or workspace-only docs.

Package shape required by CurseForge and the Blizzard client:

- zip root folder: `KWRSentinel/`
- TOC path: `KWRSentinel/KWRSentinel.toc`
- TOC basename matches parent folder: `KWRSentinel`
- Retail interface number: `120007`
- addon title: `KWR Sentinel`
- release notes source: `KWRSentinel/CURSEFORGE_DESCRIPTION.md`

CurseForge support confirms that the TOC basename must match the parent addon
folder and each TOC must include the appropriate interface number for the game
flavor.

## Discord Updates

Discord is an announcement and support surface only for this addon release. It
must not be treated as approval authority or gameplay transport.

Recommended channels:

- `#announcements`: public release availability and download links.
- `#kwr-support`: install help, bug reports, and known limitations.
- `#kwr-field-testing`: alpha/beta Retail validation instructions.
- restricted ops thread: build hashes, GitHub release URL, CurseForge file ID,
  and rollback notes.

Minimum release post:

```text
KWR Sentinel <version> is available for alpha testing.
Download: <GitHub release URL>
CurseForge: <CurseForge file URL after moderation>
Install folder: World of Warcraft/_retail_/Interface/AddOns/KWRSentinel
Scope: compact execution card, target confirmation, readiness alert.
Limitations: same-client KWR bridge only; no cross-player relay yet.
```

## Download Links

Before public announcement, fill these exact links from the published artifacts:

- GitHub release: `TBD`
- Sentinel ZIP: `TBD`
- CurseForge project: `https://www.curseforge.com/wow/addons/kwr-sentinel`
- CurseForge file: `TBD after upload/moderation`
- SHA-256 manifest: `TBD`

## Validation Gate

Before uploading or announcing:

```powershell
./tools/validate.ps1
./tools/knowledge-audit.ps1
fengari tests/smoke.lua
fengari tests/soak.lua
./tools/build.ps1 -IncludeSentinel
```

Then verify the generated Sentinel archive contains only the `KWRSentinel/`
root and includes `KWRSentinel/KWRSentinel.toc`.

