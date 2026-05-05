# Claude Code → Codex App Ecosystem Sync

Один промпт для Codex App, чтобы перенести и проверить экосистему Claude Code: скиллы, MCP, project-local настройки, память и инструкции агента.

Claude Code остаётся источником истины. Codex App получает всё, что можно безопасно подключить глобально на уровне пользователя и локально в текущем проекте.

## Быстрый запуск

Откройте Codex App в любом проекте и отправьте один промпт:

```text
Прочитай репозиторий https://github.com/2030ai/2030ai-claudecode-allecosystem-sync
и используй его как инструкцию ecosystem-sync.

Цель: обеспечить полную работоспособность моей экосистемы Claude Code в Codex App.
Проверь и при необходимости синхронизируй глобальные и project-local skills, MCP-серверы,
AGENTS/CLAUDE instructions, Codex trusted projects и связанные элементы памяти/контекста.

Сначала сделай audit/dry-run и покажи короткий список действий.
Записи в конфиги выполняй только после моего подтверждения.
Не удаляй и не перезаписывай существующие файлы, не трогай ~/.codex/auth.json,
не показывай токены, все секреты маскируй как <TOKEN>.

Работай гибко и кроссплатформенно: сам определи ОС, домашнюю директорию,
текущий проект и обычную папку проектов. На Windows используй PowerShell/Python/native APIs,
на macOS/Linux — shell или Python. Спроси только если без этого рискованно продолжать.
```

Для read-only проверки замените фразу “при необходимости синхронизируй” на “только проверь, ничего не меняй”.

Тот же текст лежит отдельно в [`PROMPT.md`](PROMPT.md), если нужен чистый copy-paste без README.

## Что Codex Должен Сделать

- Найти Claude Code конфиги и скиллы в `~/.claude/`.
- Подключить глобальные скиллы в `~/.codex/skills/`, не трогая нативные Codex skills.
- Подключить project-local скиллы в `<project>/.agents/skills/`; legacy `<project>/.codex/skills/` только диагностировать.
- Синхронизировать MCP из Claude Code в Codex TOML, включая HTTP MCP через `url` + `http_headers`.
- Проверить `AGENTS.md` / `CLAUDE.md`, project trust в Codex и локальные project configs.
- Сначала показать audit/dry-run, потом выполнять изменения только с подтверждением.

## Windows И Linux

Инструкция не привязана к macOS. Пути через `~` означают домашнюю директорию пользователя:

- macOS/Linux: `~/.claude`, `~/.codex`, `~/.cursor`.
- Windows: `%USERPROFILE%\.claude`, `%USERPROFILE%\.codex`, `%USERPROFILE%\.cursor`.

Codex должен использовать platform-native операции. Команды в `SKILL.md` — примеры, а не требование запускать Bash на Windows. Для symlink на Windows может понадобиться Developer Mode или запуск с правами, которые позволяют создавать symbolic links; если symlink создать нельзя, агент должен остановиться и объяснить, что включить, а не копировать файлы молча.

## Главные Гарантии

- Только добавление: без удаления, без silent overwrite.
- Нативные скиллы Codex/Cursor не перезаписываются.
- `~/.codex/auth.json` не трогается никогда.
- Токены не выводятся в лог и не показываются пользователю.
- Если конфиг не парсится, агент останавливается и показывает ошибку.

## Если Нужен Slash Skill

Основной сценарий — промпт выше. Установка как skill необязательна.

Если всё же хотите slash-команду в Claude Code:

```text
Склонируй https://github.com/2030ai/2030ai-claudecode-allecosystem-sync.git
как скилл ecosystem-sync в ~/.claude/skills/ecosystem-sync.
Если директория уже существует — сделай git pull.
```

После установки:

```text
/ecosystem-sync audit
/ecosystem-sync sync
```

## Файлы

- [`SKILL.md`](SKILL.md) — основная инструкция для AI-агента.
- [`PROMPT.md`](PROMPT.md) — короткий промпт для запуска из Codex App.
- [`references/platform-matrix.md`](references/platform-matrix.md) — что и куда синхронизируется.
- [`references/mcp-format-guide.md`](references/mcp-format-guide.md) — правила конвертации MCP JSON ↔ TOML.
- [`references/native-skills-registry.md`](references/native-skills-registry.md) — нативные скиллы, которые нельзя трогать.
- [`references/troubleshooting.md`](references/troubleshooting.md) — диагностика частых проблем.
- [`scripts/check-codex-project-skill-duplicates.py`](scripts/check-codex-project-skill-duplicates.py) — read-only проверка дублей `.agents/skills` + legacy `.codex/skills`.

README на русском — для людей. `SKILL.md` и `references/` на английском — для AI-агентов.

## Лицензия

MIT
