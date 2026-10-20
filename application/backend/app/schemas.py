from datetime import date, datetime
from pydantic import BaseModel, ConfigDict, Field, field_validator
from app.models import TaskStatus, Priority, GoalType, GoalStatus

class TaskBase(BaseModel):
    title: str = Field(min_length=1, max_length=180)
    description: str | None = Field(default=None, max_length=10000)
    status: TaskStatus = TaskStatus.pending
    priority: Priority = Priority.medium
    due_date: date | None = None
    goal_id: int | None = Field(default=None, ge=1)
    @field_validator("title")
    @classmethod
    def title_not_blank(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Title cannot be blank")
        return v.strip()

class TaskCreate(TaskBase): pass
class TaskUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=180)
    description: str | None = Field(default=None, max_length=10000)
    status: TaskStatus | None = None
    priority: Priority | None = None
    due_date: date | None = None
    goal_id: int | None = Field(default=None, ge=1)
    @field_validator("title")
    @classmethod
    def title_not_blank(cls, v: str | None) -> str | None:
        if v is not None and not v.strip(): raise ValueError("Title cannot be blank")
        return v.strip() if v else v

class TaskOut(TaskBase):
    id: int
    created_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)

class GoalBase(BaseModel):
    title: str = Field(min_length=1, max_length=180)
    description: str | None = Field(default=None, max_length=10000)
    goal_type: GoalType = GoalType.short_term
    priority: Priority = Priority.medium
    status: GoalStatus = GoalStatus.active
    target_date: date | None = None
    @field_validator("title")
    @classmethod
    def title_not_blank(cls, v: str) -> str:
        if not v.strip(): raise ValueError("Title cannot be blank")
        return v.strip()

class GoalCreate(GoalBase): pass
class GoalUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=180)
    description: str | None = Field(default=None, max_length=10000)
    goal_type: GoalType | None = None
    priority: Priority | None = None
    status: GoalStatus | None = None
    target_date: date | None = None

class GoalOut(GoalBase):
    id: int
    created_at: datetime
    task_count: int = 0
    completed_task_count: int = 0
    milestone_count: int = 0
    completed_milestone_count: int = 0
    progress: int = 0
    model_config = ConfigDict(from_attributes=True)

class MilestoneBase(BaseModel):
    title: str = Field(min_length=1, max_length=180)
    due_date: date | None = None
    completed: bool = False
class MilestoneCreate(MilestoneBase): pass
class MilestoneUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=180)
    due_date: date | None = None
    completed: bool | None = None
class MilestoneOut(MilestoneBase):
    id: int
    goal_id: int
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)
