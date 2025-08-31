.PHONY: help setup start stop clean test logs

help:
	@echo "Available commands:"
	@echo "  make setup    - Initial setup"
	@echo "  make start    - Start all services"
	@echo "  make stop     - Stop all services"
	@echo "  make clean    - Clean up"
	@echo "  make test     - Run tests"

setup:
	./scripts/setup.sh

start:
	docker compose up -d
	npm run dev

stop:
	docker compose down

clean:
	docker compose down -v

test:
	npm test

logs:
	docker compose logs -f
