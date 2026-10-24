from tutor.client import ask_model
from tutor.prompts import PRACTICE_PROMPT

LEVELS = ("beginner", "intermediate", "advanced")


def make_problems(topic, count=5, level="beginner"):
    if level not in LEVELS:
        raise ValueError("unknown level: " + level)
    prompt = PRACTICE_PROMPT.format(count=count, topic=topic, level=level)
    return [line for line in ask_model(prompt).split("\n") if line.strip()]
