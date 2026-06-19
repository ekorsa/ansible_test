# Ansible Web + DB Auto-Deploy

A learning project demonstrating end-to-end infrastructure automation with **Ansible** and **GitHub Actions CI/CD**. Two Docker containers simulate a production-like environment — one runs Nginx (web server), the other runs PostgreSQL (database server).

---

## Architecture

```
GitHub push → GitHub Actions (self-hosted runner)
                     │
                     └─ ansible-playbook setup_web_db.yaml
                               │
                 ┌─────────────┴─────────────┐
                 ▼                           ▼
         web_server (Docker)         db_server (Docker)
         Ubuntu 24.04                Ubuntu 24.04
         Port 8080 (HTTP)            Port 2222 (SSH)
         Port 2221 (SSH)
         Nginx + static site         PostgreSQL + my_company_db
```

---

## Project Structure

```
ansible-test/
├── setup_web_db.yaml      # Main Ansible playbook (web + db plays)
├── hosts.ini              # Inventory: web_node (2221) + db_node (2222)
├── vault.yml              # Ansible Vault — encrypted DB credentials
├── init_db.sql            # SQL schema: creates the `users` table
└── web_sup_project/
    └── index.html         # Static page deployed to Nginx

.github/workflows/
└── deploy.yml             # GitHub Actions workflow (self-hosted runner)

docker_web_db.sh           # Script to spin up both Docker containers
actions-runner/            # GitHub Actions self-hosted runner binaries
```

---

## What the Playbook Does

### Play 1 — Web Server (`hosts: web`)

| Step | Task |
|------|------|
| 1 | Install Nginx via `apt` |
| 2 | Copy `web_sup_project/` files to `/var/www/html/` |
| 3 | Ensure Nginx is started and enabled |

### Play 2 — Database Server (`hosts: db`)

| Step | Task |
|------|------|
| 1 | Install PostgreSQL and `python3-psycopg2` |
| 2 | Ensure PostgreSQL is started and enabled |
| 3 | Create database `my_company_db` |
| 4 | Create DB user (credentials from Ansible Vault) |
| 5 | Grant ALL privileges on `my_company_db` to the user |
| 6 | Copy `init_db.sql` to the remote server |
| 7 | Execute SQL to initialize the `users` table |

---

## Prerequisites

- Docker installed on the host machine
- Ansible installed on the CI runner (`community.postgresql` collection required)
- A self-hosted GitHub Actions runner registered to this repository
- `ANSIBLE_VAULT_PASSWORD` secret configured in GitHub repository settings

---

## Quick Start

### 1. Start Docker containers

```bash
chmod +x docker_web_db.sh
./docker_web_db.sh
```

This launches two Ubuntu 24.04 + systemd containers:

| Container | SSH port | HTTP port |
|-----------|----------|-----------|
| `web_server` | 2221 | 8080 |
| `db_server` | 2222 | — |

Both containers have root SSH access configured (`root:root`).

### 2. Run the playbook manually

```bash
cd ansible-test
ansible-playbook setup_web_db.yaml -i hosts.ini --vault-password-file .vault_pass.txt
```

### 3. Verify

```bash
# Check the web page
curl http://localhost:8080

# Connect to the database
docker exec -it db_server psql -U postgres -d my_company_db -c "\dt"
```

---

## CI/CD — GitHub Actions

The workflow in `.github/workflows/deploy.yml` triggers automatically on every push to `main`:

1. **Checkout** — pulls repository code onto the self-hosted runner
2. **Create Vault password file** — writes `ANSIBLE_VAULT_PASSWORD` secret to `.vault_pass.txt`
3. **Run playbook** — executes `ansible-playbook setup_web_db.yaml` with the vault file

> The runner must be running on the same machine as the Docker containers so it can reach `127.0.0.1:2221` and `127.0.0.1:2222`.

---

## Secrets Management

Database credentials are stored encrypted with **Ansible Vault** in `ansible-test/vault.yml`.

Variables used in the playbook:

| Variable | Purpose |
|----------|---------|
| `vault_db_user` | PostgreSQL application user name |
| `vault_db_password` | PostgreSQL application user password |

To edit the vault:

```bash
ansible-vault edit ansible-test/vault.yml
```

---

---

# Ansible Web + DB Auto-Deploy (RU)

Учебный проект, демонстрирующий сквозную автоматизацию инфраструктуры с помощью **Ansible** и **GitHub Actions CI/CD**. Два Docker-контейнера имитируют производственную среду: один запускает Nginx (веб-сервер), второй — PostgreSQL (сервер базы данных).

---

## Архитектура

```
Пуш в GitHub → GitHub Actions (self-hosted runner)
                        │
                        └─ ansible-playbook setup_web_db.yaml
                                    │
                    ┌───────────────┴──────────────┐
                    ▼                              ▼
            web_server (Docker)            db_server (Docker)
            Ubuntu 24.04                   Ubuntu 24.04
            Порт 8080 (HTTP)               Порт 2222 (SSH)
            Порт 2221 (SSH)
            Nginx + статический сайт       PostgreSQL + my_company_db
```

---

## Структура проекта

```
ansible-test/
├── setup_web_db.yaml      # Основной плейбук Ansible (web + db plays)
├── hosts.ini              # Инвентарь: web_node (2221) + db_node (2222)
├── vault.yml              # Ansible Vault — зашифрованные учётные данные БД
├── init_db.sql            # SQL-схема: создание таблицы `users`
└── web_sup_project/
    └── index.html         # Статическая страница, развёртываемая в Nginx

.github/workflows/
└── deploy.yml             # Workflow GitHub Actions (self-hosted runner)

docker_web_db.sh           # Скрипт запуска обоих Docker-контейнеров
actions-runner/            # Бинарные файлы self-hosted runner GitHub Actions
```

---

## Что делает плейбук

### Play 1 — Веб-сервер (`hosts: web`)

| Шаг | Задача |
|-----|--------|
| 1 | Установить Nginx через `apt` |
| 2 | Скопировать файлы `web_sup_project/` в `/var/www/html/` |
| 3 | Убедиться, что Nginx запущен и включён в автозапуск |

### Play 2 — Сервер базы данных (`hosts: db`)

| Шаг | Задача |
|-----|--------|
| 1 | Установить PostgreSQL и `python3-psycopg2` |
| 2 | Убедиться, что PostgreSQL запущен и включён в автозапуск |
| 3 | Создать базу данных `my_company_db` |
| 4 | Создать пользователя БД (учётные данные из Ansible Vault) |
| 5 | Выдать пользователю все привилегии на `my_company_db` |
| 6 | Скопировать `init_db.sql` на удалённый сервер |
| 7 | Выполнить SQL для инициализации таблицы `users` |

---

## Требования

- Docker, установленный на хост-машине
- Ansible на CI-runner (требуется коллекция `community.postgresql`)
- Self-hosted runner GitHub Actions, зарегистрированный для этого репозитория
- Секрет `ANSIBLE_VAULT_PASSWORD`, настроенный в настройках репозитория GitHub

---

## Быстрый старт

### 1. Запуск Docker-контейнеров

```bash
chmod +x docker_web_db.sh
./docker_web_db.sh
```

Запускает два контейнера Ubuntu 24.04 + systemd:

| Контейнер | Порт SSH | Порт HTTP |
|-----------|----------|-----------|
| `web_server` | 2221 | 8080 |
| `db_server` | 2222 | — |

Оба контейнера настроены для root-доступа по SSH (`root:root`).

### 2. Запуск плейбука вручную

```bash
cd ansible-test
ansible-playbook setup_web_db.yaml -i hosts.ini --vault-password-file .vault_pass.txt
```

### 3. Проверка

```bash
# Проверить веб-страницу
curl http://localhost:8080

# Подключиться к базе данных
docker exec -it db_server psql -U postgres -d my_company_db -c "\dt"
```

---

## CI/CD — GitHub Actions

Workflow в `.github/workflows/deploy.yml` запускается автоматически при каждом пуше в `main`:

1. **Checkout** — скачивает код репозитория на self-hosted runner
2. **Создание файла пароля Vault** — записывает секрет `ANSIBLE_VAULT_PASSWORD` в `.vault_pass.txt`
3. **Запуск плейбука** — выполняет `ansible-playbook setup_web_db.yaml` с файлом vault

> Runner должен работать на той же машине, что и Docker-контейнеры, чтобы иметь доступ к `127.0.0.1:2221` и `127.0.0.1:2222`.

---

## Управление секретами

Учётные данные базы данных хранятся в зашифрованном виде с помощью **Ansible Vault** в файле `ansible-test/vault.yml`.

Переменные, используемые в плейбуке:

| Переменная | Назначение |
|------------|-----------|
| `vault_db_user` | Имя пользователя PostgreSQL |
| `vault_db_password` | Пароль пользователя PostgreSQL |

Для редактирования vault:

```bash
ansible-vault edit ansible-test/vault.yml
```
