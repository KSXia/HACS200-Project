from flask import Blueprint, jsonify, request

from tutor.auth import require_token
from tutor.client import ModelError
from tutor.problems import make_problems

bp = Blueprint("practice", __name__)


@bp.route("/practice", methods=["POST"])
@require_token
def practice():
    body = request.get_json() or {}
    topic = body.get("topic", "").strip()
    if not topic:
        return jsonify(error="topic is required"), 400
    try:
        problems = make_problems(topic, body.get("count", 5), body.get("level", "beginner"))
    except ValueError as e:
        return jsonify(error=str(e)), 400
    except ModelError:
        return jsonify(error="model unavailable"), 502
    return jsonify(problems=problems)
