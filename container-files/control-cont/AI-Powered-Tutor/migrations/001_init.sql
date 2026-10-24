CREATE TABLE questions (
    id         SERIAL PRIMARY KEY,
    user_id    TEXT NOT NULL,
    question   TEXT NOT NULL,
    answer     TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX questions_user_idx ON questions (user_id);
