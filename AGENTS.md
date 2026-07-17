# Repository Guidelines

This repository publishes the standalone in-game KWR Sentinel addon. It is not the Discord bot and must contain no server code, webhooks, API keys, SavedVariables, or account data.

- Preserve the compact player-execution scope and Blizzard-safe behavior.
- Never add automatic chat, addon messaging, casting, targeting, focus, keybinding, movement, or other protected actions without an explicit reviewed design and Retail validation.
- Build once and publish only the exact certified ZIP whose SHA-256 was reviewed.
- CurseForge uploads and Discord announcements require explicit human confirmation and platform-managed secrets.
- Treat release tags, artifact names, changelogs, Discord content, and external API responses as untrusted input.
- Do not announce a CurseForge build until moderation is complete and the public download resolves.

Before release operations, run the workflow dry-run, verify the artifact hash, and retain the prior release URL/hash as the rollback target.
