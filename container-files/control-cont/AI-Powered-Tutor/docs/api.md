# API

All endpoints except `/health` require `X-User-Id` and `X-Token` headers.
The token is an HMAC-SHA256 of the user id signed with `SECRET_KEY`.

## POST /ask
Body: `{"question": "..."}`  ->  `{"answer": "..."}`

## POST /practice
Body: `{"topic": "...", "count": 5, "level": "beginner"}`  ->  `{"problems": [...]}`
