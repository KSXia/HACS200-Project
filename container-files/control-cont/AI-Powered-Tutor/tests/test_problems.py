from unittest import mock

import pytest

from tutor import problems


def test_make_problems_splits_lines():
    with mock.patch.object(problems, "ask_model", return_value="a\n\nb"):
        assert problems.make_problems("math") == ["a", "b"]


def test_make_problems_rejects_bad_level():
    with pytest.raises(ValueError):
        problems.make_problems("math", level="expert")
