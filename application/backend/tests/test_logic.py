from datetime import date
from types import SimpleNamespace
from app.logic import task_is_overdue, calculate_progress


def test_task_without_due_date_is_not_overdue():
    assert not task_is_overdue(SimpleNamespace(status="Pending", due_date=None), date(2026, 10, 20))


def test_completed_past_due_task_is_not_overdue():
    assert not task_is_overdue(SimpleNamespace(status="Completed", due_date=date(2020, 1, 1)), date(2026, 10, 20))


def test_pending_past_due_task_is_overdue():
    assert task_is_overdue(SimpleNamespace(status="Pending", due_date=date(2020, 1, 1)), date(2026, 10, 20))


def test_goal_progress_uses_tasks_when_linked_tasks_exist():
    assert calculate_progress(4, 1, 8, 8) == 25


def test_goal_progress_falls_back_to_milestones():
    assert calculate_progress(0, 0, 4, 3) == 75


def test_empty_goal_progress_is_zero():
    assert calculate_progress(0, 0, 0, 0) == 0
