# Guestbook · CI/CD Capstone

Гостевая книга на FastAPI + PostgreSQL на основе моего проекта
[guestbook-workshop](https://github.com/MaxFolmer/guestbook-workshop).
Проект сохраняет исходные /messages и SQL-схему, добавляет проверку готовности,
версию, тесты, выпуск контейнеров и процедуру отката.

## Запуск

Нужны Docker Engine с Compose v2, Python 3 и uv для разработки.
Из корня проекта:

```sh
python3 scripts/init-env.py
docker compose up -d --build --wait
curl -fsS http://localhost:8000/ready
curl -fsS -H 'Content-Type: application/json' -d '{"author":"Max","text":"Hello"}' http://localhost:8000/messages
curl -fsS http://localhost:8000/messages
```

Swagger: http://localhost:8000/docs. По умолчанию порт доступен только локально.
`docker compose down` сохраняет сообщения; `down -v` уничтожает данные.
Пароль генерируется локально, .env не коммитится. База доступна приложению как db.

## Проверки

```sh
uv sync --locked
uv run ruff check .
DATABASE_URL=postgresql://test:test@localhost/test uv run pytest -q
```

Интеграционный тест требует отдельную тестовую PostgreSQL и `INTEGRATION=1`.
В Actions она создаётся автоматически. CI работает на push main, тегах и PR;
публикация имеет `needs: check`. Main публикует latest и sha-коммита; semver-тег
публикует vX.Y.Z и sha. Тег обязан принадлежать main и совпадать с pyproject/CHANGELOG.
Образы собираются для amd64 и arm64. Прод использует версии, не latest.

## Репозиторий и публикация

Репозиторий: https://github.com/MaxFolmer/capstoune

- [Actions](https://github.com/MaxFolmer/capstoune/actions)
- [Образы GHCR](https://github.com/MaxFolmer/capstoune/pkgs/container/capstoune)
- [Теги](https://github.com/MaxFolmer/capstoune/tags)

GET /version возвращает имя сервиса и версию для диагностики выката.

Main публикует `ghcr.io/maxfolmer/capstoune:latest`. Тег `vX.Y.Z`
публикует образ с тем же тегом. Версия pyproject.toml должна совпадать с тегом;
сначала обновить версию, config.py и значение ARG в Dockerfile, выполнить
`uv lock`, добавить запись CHANGELOG, закоммитить и отправить в main.
После зелёного CI создать и отправить аннотированный тег:

```sh
git tag -a v1.0.0 -m 'Release 1.0.0'
git push origin v1.0.0
```

Повторно не использовать опубликованные теги.

## Выкат на сервер и защита

На сервере нужны Docker Engine и Compose v2. Клонируйте репозиторий,
выполните `python3 scripts/init-env.py`, добавьте в .env
`IMAGE=ghcr.io/maxfolmer/capstoune` и запускайте:

```sh
bash scripts/deploy.sh v1.0.0
curl -fsS http://localhost:8000/ready
```

Если пакет приватный, сначала выполните `docker login ghcr.io` токеном
с read:packages. Для публичного доступа настройте HTTPS reverse proxy;
приложение по умолчанию слушает только 127.0.0.1 сервера.

Когда опубликованы обе версии, выполните на сервере:

```sh
bash scripts/demo-rollback.sh v1.0.0 v1.1.0
```

Скрипт добавляет сообщение, выкатывает новую версию, возвращает старую,
проверяет готовность, версию и наличие сообщения. Результаты — в evidence/.
CI также проверяет контейнерный откат v1.1.0 → v1.0.0 на временном runner;
это отдельная проверка, которую нельзя выдавать за демонстрацию на сервере.
Покажите Actions, Packages, версии, живой сервис и результаты отката.
Статус реальных доказательств находится в docs/DEFENSE.md.

## Инженерное решение

Выбран простой recreate на одном сервере: короткий перерыв допустим для учебной
гостевой книги. База и volume общие между версиями; при откате меняется только
контейнер приложения. Ни столбцы, ни типы, ни сохранённые значения не изменяются.
CREATE TABLE IF NOT EXISTS идемпотентен. Добавление /ready и поля version в /
не меняет контракт /messages. Будущие миграции — expand/contract: сначала добавить
nullable-поле, поддерживать обе версии, удалять старое лишь после окна отката.
Откат приложения не равен откату базы; резервные копии нужны отдельно.

Инциденты и команды: [RUNBOOK.md](RUNBOOK.md).
Текущее состояние проверки: [docs/DEFENSE.md](docs/DEFENSE.md).

Справочники: [uv Docker](https://docs.astral.sh/uv/guides/integration/docker/),
[GHCR Actions](https://docs.github.com/en/packages/managing-github-packages-using-github-actions-workflows/publishing-and-installing-a-package-with-github-actions).
