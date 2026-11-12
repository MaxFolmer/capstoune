# Changelog

## [v1.0.0] — 2026-11-12

- Гостевая книга FastAPI + PostgreSQL на основе MaxFolmer/guestbook-workshop.
- Зависимости uv и Python 3.12.12, контейнер от непривилегированного пользователя.
- Compose с проверкой готовности БД, volume и отдельным продовым запуском.
- CI с Ruff, pytest и PostgreSQL; GHCR latest и релизы semver после check.
- Версия в GET /, отдельные /health и /ready, проверка входных сообщений.
- Скрипты обновления/отката, README и аварийная инструкция.
- Исходная схема messages сохранена без удаления или изменения столбцов.
