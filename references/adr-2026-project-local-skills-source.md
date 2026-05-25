# ADR: Project-Local Skill Source

Date: 2026-05-25

## Decision

Project-local skills use `.agents/skills/<skill-name>/SKILL.md` as the canonical source. Platform roots are compatibility mirrors:

- `.claude/skills/<skill-name> -> ../../.agents/skills/<skill-name>`
- `.codex/skills/<skill-name> -> ../../.agents/skills/<skill-name>`
- `.cursor/skills/<skill-name> -> ../../.agents/skills/<skill-name>`

## Rationale

Project-local skills are repository content, not platform-owned user state. Keeping the source under `.agents` makes the repository the source of truth while still exposing the same skill to Claude Code, Codex, and Cursor through their native discovery paths.

## Consequences

- Do not create new `.claude/commands/*.md`; useful command behavior should become a skill.
- Do not use lowercase manifest filenames; manifests are always `SKILL.md`.
- Mirror roots should contain symlinks, not independent skill copies.
- `registry/` remains a generated cache. Each project remains the source of truth for its own local skills, instructions, and config.
- `agent_docs/` remains curated shared memory. Claude memory and Codex Memories are operational/generated recall layers; only distilled stable signal belongs in docs or policy files.
