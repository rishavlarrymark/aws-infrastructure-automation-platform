from datetime import date


def task_is_overdue(task, today: date) -> bool:
    """A task is overdue only when it has a past due date and is not completed."""
    status = getattr(task.status, "name", str(task.status)).lower().replace(" ", "_")
    return status != "completed" and task.due_date is not None and task.due_date < today


def calculate_progress(task_total: int, completed_tasks: int, milestone_total: int, completed_milestones: int) -> int:
    """Use task progress when tasks exist; otherwise use milestones."""
    total, done = (task_total, completed_tasks) if task_total else (milestone_total, completed_milestones)
    return round(done * 100 / total) if total else 0
