# KWR Sentinel Discord Channel Updates

Status: ready-to-post

Date: 2026-07-17

No Discord connector or webhook credential is available in this workspace, so
these messages are prepared for manual posting or for the KWR Sentinel Discord
bot once its production connection is available.

## #announcements

```text
KWR Sentinel 6.1.0-alpha.25 is available for alpha testing.

Download:
https://github.com/josevargas6/KWRSentinel/releases/download/v6.1.0-alpha.25/KWRSentinel_6_1_0_ALPHA_25.zip

Release page:
https://github.com/josevargas6/KWRSentinel/releases/tag/v6.1.0-alpha.25

Install folder:
World of Warcraft/_retail_/Interface/AddOns/KWRSentinel

Scope:
Compact player execution card, commander trust badge, target confirmation cue, and one conservative readiness alert.

Current limitation:
Same-client KWR bridge only. Cross-player Sentinel relay is not enabled in this alpha.
```

## #kwr-support

```text
KWR Sentinel alpha support notes:

- Use /sentinel or /kwrs to toggle the execution card.
- Use /kwrs map for the Blizzard battlefield map.
- Use /kwrs score for the Blizzard scoreboard.
- If no commander data appears, confirm KnomercyWarRoom is installed on the same client for this alpha.
- Sentinel does not target, focus, cast, move, send chat, or automate gameplay.

Bug reports should include:
- Retail version
- battleground
- whether KWR was installed on the same client
- screenshot of the card if visible
- any Lua error text
```

## #kwr-field-testing

```text
KWR Sentinel 6.1.0-alpha.25 field-test targets:

1. Enter a Retail battleground with KWR and KWRSentinel installed on the same client.
2. Confirm the card shows LOCAL KWR when commander bridge data is available.
3. Confirm NO COMMANDER appears when KWR is disabled or unavailable.
4. Confirm the target cue is white on the reviewed target, red on a different enemy, and muted with no target instruction.
5. Confirm one readiness alert appears during staging and does not repeat during combat.
6. Confirm /kwrs map and /kwrs score only toggle Blizzard-native UI.

Report any taint, Lua errors, unreadable text, repeated alerts, or incorrect target state.
```

## Restricted Ops Thread

```text
KWR Sentinel 6.1.0-alpha.25 distribution receipt

GitHub repo:
https://github.com/josevargas6/KWRSentinel

GitHub prerelease:
https://github.com/josevargas6/KWRSentinel/releases/tag/v6.1.0-alpha.25

ZIP:
https://github.com/josevargas6/KWRSentinel/releases/download/v6.1.0-alpha.25/KWRSentinel_6_1_0_ALPHA_25.zip

SHA-256:
8075D9B3B766550FDAB2BBB0A961E66A72B380F6743CD0C8E85542E735144807

Validation:
- validate.ps1 passed
- knowledge-audit.ps1 passed
- smoke.lua passed, 277 checks
- soak.lua passed
- build.ps1 -IncludeSentinel package audit passed

CurseForge:
Upload pending moderation / file URL still TBD.
```
