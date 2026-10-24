from flask import Blueprint, current_app, jsonify, request

from tutor import db
from tutor.auth import require_token
from tutor.client import ModelError, ask_model
from tutor.prompts import TUTOR_PROMPT

bp = Blueprint("ask", __name__)


@bp.route("/ask", methods=["POST"])
@require_token
def ask():
    question = (request.get_json() or {}).get("question", "").strip()
    if not question:
        return jsonify(error="question is required"), 400
    if len(question) > current_app.config["MAX_QUESTION_LENGTH"]:
        return jsonify(error="question too long"), 413
    try:
        answer = ask_model(TUTOR_PROMPT.format(question=question))
    except ModelError:
        return jsonify(error="model unavailable"), 502
    db.log_question(request.user_id, question, answer)
    return jsonify(answer=answer)
