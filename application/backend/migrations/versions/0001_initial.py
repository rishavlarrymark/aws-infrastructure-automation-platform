"""Initial task, goal and milestone schema.

Revision ID: 0001_initial
Revises:
"""
from alembic import op
import sqlalchemy as sa

revision = "0001_initial"
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    task_status = sa.Enum("pending", "in_progress", "completed", name="task_status")
    priority = sa.Enum("low", "medium", "high", name="priority")
    goal_type = sa.Enum("short_term", "long_term", name="goal_type")
    goal_priority = sa.Enum("low", "medium", "high", name="goal_priority")
    goal_status = sa.Enum("active", "completed", "paused", name="goal_status")
    bind = op.get_bind()
    op.create_table("goals",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("title", sa.String(180), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("goal_type", goal_type, nullable=False),
        sa.Column("priority", goal_priority, nullable=False),
        sa.Column("status", goal_status, nullable=False),
        sa.Column("target_date", sa.Date(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False))
    op.create_index("ix_goals_id", "goals", ["id"])
    op.create_table("tasks",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("title", sa.String(180), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("status", task_status, nullable=False),
        sa.Column("priority", priority, nullable=False),
        sa.Column("due_date", sa.Date(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("goal_id", sa.Integer(), sa.ForeignKey("goals.id", ondelete="SET NULL"), nullable=True))
    op.create_index("ix_tasks_id", "tasks", ["id"])
    op.create_index("ix_tasks_title", "tasks", ["title"])
    op.create_index("ix_tasks_due_date", "tasks", ["due_date"])
    op.create_index("ix_tasks_goal_id", "tasks", ["goal_id"])
    op.create_table("milestones",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("goal_id", sa.Integer(), sa.ForeignKey("goals.id", ondelete="CASCADE"), nullable=False),
        sa.Column("title", sa.String(180), nullable=False),
        sa.Column("due_date", sa.Date(), nullable=True),
        sa.Column("completed", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False))
    op.create_index("ix_milestones_id", "milestones", ["id"])
    op.create_index("ix_milestones_goal_id", "milestones", ["goal_id"])

def downgrade():
    op.drop_table("milestones")
    op.drop_table("tasks")
    op.drop_table("goals")
    for name in ("goal_status", "goal_priority", "goal_type", "priority", "task_status"):
        sa.Enum(name=name).drop(op.get_bind(), checkfirst=True)
