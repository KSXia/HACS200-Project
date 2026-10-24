import pytest

from config import TestConfig
from tutor import create_app


@pytest.fixture
def client():
    app = create_app(TestConfig)
    return app.test_client()
