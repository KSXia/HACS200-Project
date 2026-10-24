# AI-Powered Tutor

A small Flask service that answers student questions and generates practice
problems using a hosted language model.

## Setup

    python3 -m venv venv
    . venv/bin/activate
    pip install -r requirements.txt
    cp .env.example .env    # then fill in your own values
    make migrate
    make run

## Endpoints

See [docs/api.md](docs/api.md).

## Tests

    make test
