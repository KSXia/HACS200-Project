from flask import Flask

from config import Config


def create_app(config=Config):
    app = Flask(__name__)
    app.config.from_object(config)

    from tutor import db
    from tutor.routes import ask, health, practice

    db.init_app(app)
    app.register_blueprint(health.bp)
    app.register_blueprint(ask.bp)
    app.register_blueprint(practice.bp)
    return app
