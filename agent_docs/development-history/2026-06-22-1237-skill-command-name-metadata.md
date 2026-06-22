# [2026-06-22 12:37] Skill command-name metadata

Файл: `agent_docs/development-history/2026-06-22-1237-skill-command-name-metadata.md`

## Что сделано

- Root skill metadata приведена к команде `/ecosystem-sync`.
- Первый H1 в `SKILL.md` приведён к `# /ecosystem-sync`.
- Добавлен `agents/openai.yaml` с `display_name: "/ecosystem-sync"`.

## Зачем

Чтобы название skill в UI совпадало с командой, которую вводит пользователь.

## Обновлено

- [ ] agent_docs/architecture.md (не применимо)
- [ ] agent_docs/adr/YYYY-MM-DD-HHMM-title.md (не применимо)
- [ ] Тесты (не применимо, metadata-only)
- [x] Документация

## Связанные решения

- Не применимо.

## Следующие шаги

- При изменении skill metadata сохранять соответствие `/ecosystem-sync`.
