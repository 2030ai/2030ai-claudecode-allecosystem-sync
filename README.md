# Claude Code Ecosystem Sync

Синхронизация скиллов и MCP-серверов между **Claude Code**, **Cursor** и **Codex CLI**.

Claude Code CLI — источник истины. Cursor и Codex получают симлинки на скиллы и записи MCP-серверов.

## Установка

Скопируйте в Claude Code, Codex или Cursor:

```
Склонируй https://github.com/2030ai/2030ai-claudecode-allecosystem-sync.git
как скилл ecosystem-sync в ~/.claude/skills/ecosystem-sync.
Если директория уже существует — сделай git pull.
```

## Использование

```
/ecosystem-sync audit   # Что не синхронизировано (только чтение)
/ecosystem-sync sync    # Создать недостающие симлинки и записи
```

> В Codex и Cursor слеш-команды недоступны — попросите агента прочитать и выполнить `SKILL.md`.

## Что делает

- **Скиллы:** создаёт симлинки из `~/.claude/skills/` в директории Cursor и Codex (глобальные и проектные)
- **MCP-серверы:** копирует записи из `~/.claude.json` в конфиги Cursor (JSON) и Codex (TOML)
- **Только добавление** — ничего не удаляет и не перезаписывает
- Нативные скиллы платформ не затрагиваются

## Подробности

- [`references/platform-matrix.md`](references/platform-matrix.md) — сравнение платформ
- [`references/mcp-format-guide.md`](references/mcp-format-guide.md) — конвертация JSON ↔ TOML
- [`references/native-skills-registry.md`](references/native-skills-registry.md) — списки встроенных скиллов
- [`references/troubleshooting.md`](references/troubleshooting.md) — решение проблем


> README на русском — для людей. SKILL.md и `references/` на английском — для AI-агентов.

## Лицензия

MIT
