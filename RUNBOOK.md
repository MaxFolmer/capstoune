# Runbook

Работать из корня проекта на сервере. Прод имеет постоянное имя guestbook-prod.
.env должен содержать IMAGE, пароль БД и прочие переменные из .env.example.
Доступ к серверу и DNS хранит владелец проекта, не Git.

Перед любыми командами compose экспортировать фактический тег:
`export IMAGE_TAG=v1.1.0` (сверить с evidence/deployments.log).

## Сервис недоступен

```sh
docker compose -p guestbook-prod -f compose.prod.yaml --env-file .env ps
docker compose -p guestbook-prod -f compose.prod.yaml logs --tail=100 app db
curl -f http://localhost:8000/health
curl -f http://localhost:8000/ready
df -h
```

Перед командами compose для прода экспортировать текущий тег:
`export IMAGE_TAG=v1.1.0` (или фактический из evidence/deployments.log).
/health проверяет процесс; /ready — соединение с БД. При 503 проверить db,
место на диске, пароль и журнал. Не удалять volume. При смене пароля в .env
уже созданная PostgreSQL не меняет пароль автоматически.

## Неправильный релиз

```sh
bash scripts/deploy.sh v1.0.0
curl -f http://localhost:8000/ready
curl -f http://localhost:8000/messages
```

Подставить последний проверенный тег из журнала. Команда сначала скачивает
образ; если скачивание не удалось, работающий контейнер не трогается.
При провале healthcheck изучить логи и явно выполнить откат. Автоматического
отката нет. После отката проверить данные, версию в GET / и внешний HTTPS-адрес.
Не перезаписывать релизные теги. Для исправления выпускать новый patch.

## Резервная копия и восстановление

```sh
mkdir -p evidence
chmod 700 evidence
docker compose -p guestbook-prod -f compose.prod.yaml exec -T db sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' > evidence/backup.dump
```

Копировать бэкап на отдельное защищённое хранилище. Проверять восстановление
в отдельную тестовую базу. Для восстановления прода сначала остановить app,
сохранить текущую БД, согласовать потерю записей после даты бэкапа, затем:

```sh
docker compose -p guestbook-prod -f compose.prod.yaml stop app
docker compose -p guestbook-prod -f compose.prod.yaml exec -T db sh -c 'pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists --exit-on-error' < evidence/backup.dump
docker compose -p guestbook-prod -f compose.prod.yaml up -d --wait
```

Не публиковать .env, дампы и логи с персональными данными. После инцидента
записать время, симптом, релиз, причину, действие и результат проверки.
