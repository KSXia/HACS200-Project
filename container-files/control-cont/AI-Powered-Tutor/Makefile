.PHONY: run test migrate

run:
	python3 app.py

test:
	python3 -m pytest tests/

migrate:
	psql "$$DATABASE_URL" -f migrations/001_init.sql
