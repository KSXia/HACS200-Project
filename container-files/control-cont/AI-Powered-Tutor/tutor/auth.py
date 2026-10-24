import functools
import hashlib
import hmac

from flask import current_app, jsonify, request


def sign(user_id):
    key = current_app.config["SECRET_KEY"].encode()
    return hmac.new(key, str(user_id).encode(), hashlib.sha256).hexdigest()


def require_token(view):
    @functools.wraps(view)
    def wrapped(*args, **kwargs):
        user_id = request.headers.get("X-User-Id", "")
        token = request.headers.get("X-Token", "")
        if not user_id or not hmac.compare_digest(token, sign(user_id)):
            return jsonify(error="unauthorized"), 401
        request.user_id = user_id
        return view(*args, **kwargs)

    return wrapped
