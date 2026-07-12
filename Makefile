.PHONY: help setup up up-turn down logs ps build migrate test clean config

help:
	@printf '%s\n' 'setup up up-turn down logs ps build migrate test clean config'

setup:
	@test -f .env || cp .env.example .env
	@printf '%s\n' 'Edit .env and replace every CHANGE_ME value before running make up.'

config:
	docker compose config --quiet

up:
	docker compose up --build -d

up-turn:
	docker compose --profile turn up --build -d

down:
	docker compose down

logs:
	docker compose logs -f

ps:
	docker compose ps

build:
	docker compose build

migrate:
	docker compose exec backend /app/bin/relay eval 'Relay.Release.migrate()'

test:
	cd backend && mix test
	npm --prefix frontend run lint
	npm --prefix frontend run build

clean:
	docker compose down --volumes --remove-orphans
