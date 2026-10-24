import requests
from flask import current_app


class ModelError(Exception):
    pass


def ask_model(prompt):
    headers = {"Authorization": "Bearer " + current_app.config["LLM_API_KEY"]}
    try:
        resp = requests.post(
            current_app.config["LLM_API_URL"],
            headers=headers,
            json={"prompt": prompt, "max_tokens": 512},
            timeout=30,
        )
        resp.raise_for_status()
    except requests.RequestException as e:
        raise ModelError(str(e))
    return resp.json()["text"]
