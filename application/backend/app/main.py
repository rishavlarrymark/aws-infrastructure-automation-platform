import logging
from contextlib import asynccontextmanager
from datetime import date, datetime, timedelta
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError
from fastapi import Depends, FastAPI, HTTPException, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import func, or_, select, text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session, selectinload
from app.config import settings
from app.database import Base, engine, get_db
from app import models, schemas

logging.basicConfig(level=getattr(logging, settings.log_level.upper(), logging.INFO),
                    format="%(asctime)s %(levelname)s %(name)s %(message)s")
logger = logging.getLogger("task_manager")
try:
    APP_TZ = ZoneInfo(settings.app_timezone)
except ZoneInfoNotFoundError:
    raise RuntimeError(f"Invalid APP_TIMEZONE: {settings.app_timezone}")

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting %s in %s", settings.app_name, settings.app_env)
    yield
    engine.dispose()
    logger.info("Database engine disposed")

app = FastAPI(title=settings.app_name, version="1.0.0", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=settings.cors_origin_list,
                   allow_credentials=False, allow_methods=["*"], allow_headers=["*"])

@app.exception_handler(SQLAlchemyError)
async def database_exception_handler(request: Request, exc: SQLAlchemyError):
    logger.exception("Database operation failed: %s %s", request.method, request.url.path)
    return JSONResponse(status_code=503, content={"detail": "Database operation failed. Check PostgreSQL connectivity and configuration.", "code": "database_unavailable"})

@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    logger.exception("Unhandled error: %s %s", request.method, request.url.path)
    return JSONResponse(status_code=500, content={"detail": "An unexpected server error occurred.", "code": "internal_error"})

@app.get("/health")
def health(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        return {"status": "ok", "database": "connected"}
    except SQLAlchemyError:
        logger.exception("Health check database probe failed")
        raise HTTPException(status_code=503, detail={"status": "degraded", "database": "unavailable"})

api = __import__("fastapi").APIRouter(prefix="/api/v1")

def today_local() -> date:
    return datetime.now(APP_TZ).date()

def task_is_overdue(task: models.Task, today: date) -> bool:
    return task.status != models.TaskStatus.completed and task.due_date is not None and task.due_date < today

def goal_output(goal: models.Goal) -> dict:
    task_total = len(goal.tasks)
    task_done = sum(t.status == models.TaskStatus.completed for t in goal.tasks)
    ms_total = len(goal.milestones)
    ms_done = sum(m.completed for m in goal.milestones)
    # Use task progress when tasks are linked; otherwise use milestone progress.
    denominator, numerator = (task_total, task_done) if task_total else (ms_total, ms_done)
    progress = round(numerator * 100 / denominator) if denominator else 0
    return {"id": goal.id, "title": goal.title, "description": goal.description,
            "goal_type": goal.goal_type, "priority": goal.priority, "status": goal.status,
            "target_date": goal.target_date, "created_at": goal.created_at,
            "task_count": task_total, "completed_task_count": task_done,
            "milestone_count": ms_total, "completed_milestone_count": ms_done, "progress": progress}

@api.get("/tasks", response_model=list[schemas.TaskOut])
def list_tasks(view: str | None = None, search: str | None = None,
               status: models.TaskStatus | None = None, priority: models.Priority | None = None,
               goal_id: int | None = Query(default=None, ge=1),
               sort: str = Query(default="due_date", pattern="^(due_date|created_at|title|priority)$"),
               order: str = Query(default="asc", pattern="^(asc|desc)$"),
               db: Session = Depends(get_db)):
    stmt = select(models.Task)
    if search and search.strip():
        pattern = f"%{search.strip()}%"
        stmt = stmt.where(or_(models.Task.title.ilike(pattern), models.Task.description.ilike(pattern)))
    if status: stmt = stmt.where(models.Task.status == status)
    if priority: stmt = stmt.where(models.Task.priority == priority)
    if goal_id is not None: stmt = stmt.where(models.Task.goal_id == goal_id)
    today = today_local()
    if view == "today": stmt = stmt.where(models.Task.due_date == today, models.Task.status != models.TaskStatus.completed)
    elif view == "tomorrow": stmt = stmt.where(models.Task.due_date == today + timedelta(days=1), models.Task.status != models.TaskStatus.completed)
    elif view == "overdue": stmt = stmt.where(models.Task.due_date.is_not(None), models.Task.due_date < today, models.Task.status != models.TaskStatus.completed)
    elif view == "missing": stmt = stmt.where(models.Task.due_date.is_(None), models.Task.status != models.TaskStatus.completed)
    elif view == "weekly":
        stmt = stmt.where(models.Task.due_date >= today, models.Task.due_date <= today + timedelta(days=6), models.Task.status != models.TaskStatus.completed)
    elif view == "monthly":
        month_start = today.replace(day=1)
        next_month = (month_start.replace(day=28) + timedelta(days=4)).replace(day=1)
        stmt = stmt.where(models.Task.due_date >= today, models.Task.due_date < next_month, models.Task.status != models.TaskStatus.completed)
    elif view == "completed": stmt = stmt.where(models.Task.status == models.TaskStatus.completed)
    elif view not in (None, "all"): raise HTTPException(400, "Unknown task view")
    column = getattr(models.Task, sort)
    if sort == "priority":
        # Stable priority ordering rather than alphabetical ordering.
        stmt = stmt.order_by(models.Task.priority.desc() if order == "desc" else models.Task.priority.asc())
    else:
        stmt = stmt.order_by(column.desc().nullslast() if order == "desc" else column.asc().nullslast())
    return list(db.scalars(stmt).all())

@api.post("/tasks", response_model=schemas.TaskOut, status_code=201)
def create_task(payload: schemas.TaskCreate, db: Session = Depends(get_db)):
    if payload.goal_id and not db.get(models.Goal, payload.goal_id): raise HTTPException(404, "Linked goal not found")
    obj = models.Task(**payload.model_dump())
    db.add(obj); db.commit(); db.refresh(obj)
    logger.info("Created task id=%s", obj.id)
    return obj

@api.get("/tasks/{task_id}", response_model=schemas.TaskOut)
def get_task(task_id: int, db: Session = Depends(get_db)):
    obj = db.get(models.Task, task_id)
    if not obj: raise HTTPException(404, "Task not found")
    return obj

@api.patch("/tasks/{task_id}", response_model=schemas.TaskOut)
def update_task(task_id: int, payload: schemas.TaskUpdate, db: Session = Depends(get_db)):
    obj = db.get(models.Task, task_id)
    if not obj: raise HTTPException(404, "Task not found")
    values = payload.model_dump(exclude_unset=True)
    if values.get("goal_id") and not db.get(models.Goal, values["goal_id"]): raise HTTPException(404, "Linked goal not found")
    for key, value in values.items(): setattr(obj, key, value)
    db.commit(); db.refresh(obj)
    logger.info("Updated task id=%s", obj.id)
    return obj

@api.delete("/tasks/{task_id}", status_code=204)
def delete_task(task_id: int, db: Session = Depends(get_db)):
    obj = db.get(models.Task, task_id)
    if not obj: raise HTTPException(404, "Task not found")
    db.delete(obj); db.commit()
    logger.info("Deleted task id=%s", task_id)

@api.get("/goals", response_model=list[schemas.GoalOut])
def list_goals(goal_type: models.GoalType | None = None, db: Session = Depends(get_db)):
    stmt = select(models.Goal).options(selectinload(models.Goal.tasks), selectinload(models.Goal.milestones))
    if goal_type: stmt = stmt.where(models.Goal.goal_type == goal_type)
    goals = db.scalars(stmt.order_by(models.Goal.target_date.asc().nullslast())).all()
    return [goal_output(g) for g in goals]

@api.post("/goals", response_model=schemas.GoalOut, status_code=201)
def create_goal(payload: schemas.GoalCreate, db: Session = Depends(get_db)):
    obj = models.Goal(**payload.model_dump())
    db.add(obj); db.commit(); db.refresh(obj)
    obj = db.scalar(select(models.Goal).where(models.Goal.id == obj.id).options(selectinload(models.Goal.tasks), selectinload(models.Goal.milestones)))
    return goal_output(obj)

@api.get("/goals/{goal_id}", response_model=schemas.GoalOut)
def get_goal(goal_id: int, db: Session = Depends(get_db)):
    obj = db.scalar(select(models.Goal).where(models.Goal.id == goal_id).options(selectinload(models.Goal.tasks), selectinload(models.Goal.milestones)))
    if not obj: raise HTTPException(404, "Goal not found")
    return goal_output(obj)

@api.patch("/goals/{goal_id}", response_model=schemas.GoalOut)
def update_goal(goal_id: int, payload: schemas.GoalUpdate, db: Session = Depends(get_db)):
    obj = db.get(models.Goal, goal_id)
    if not obj: raise HTTPException(404, "Goal not found")
    for key, value in payload.model_dump(exclude_unset=True).items(): setattr(obj, key, value)
    db.commit()
    obj = db.scalar(select(models.Goal).where(models.Goal.id == goal_id).options(selectinload(models.Goal.tasks), selectinload(models.Goal.milestones)))
    return goal_output(obj)

@api.delete("/goals/{goal_id}", status_code=204)
def delete_goal(goal_id: int, db: Session = Depends(get_db)):
    obj = db.get(models.Goal, goal_id)
    if not obj: raise HTTPException(404, "Goal not found")
    db.delete(obj); db.commit()

@api.get("/goals/{goal_id}/milestones", response_model=list[schemas.MilestoneOut])
def list_milestones(goal_id: int, db: Session = Depends(get_db)):
    if not db.get(models.Goal, goal_id): raise HTTPException(404, "Goal not found")
    return list(db.scalars(select(models.Milestone).where(models.Milestone.goal_id == goal_id).order_by(models.Milestone.due_date.asc().nullslast())).all())

@api.post("/goals/{goal_id}/milestones", response_model=schemas.MilestoneOut, status_code=201)
def create_milestone(goal_id: int, payload: schemas.MilestoneCreate, db: Session = Depends(get_db)):
    if not db.get(models.Goal, goal_id): raise HTTPException(404, "Goal not found")
    obj = models.Milestone(goal_id=goal_id, **payload.model_dump())
    db.add(obj); db.commit(); db.refresh(obj); return obj

@api.patch("/milestones/{milestone_id}", response_model=schemas.MilestoneOut)
def update_milestone(milestone_id: int, payload: schemas.MilestoneUpdate, db: Session = Depends(get_db)):
    obj = db.get(models.Milestone, milestone_id)
    if not obj: raise HTTPException(404, "Milestone not found")
    for key, value in payload.model_dump(exclude_unset=True).items(): setattr(obj, key, value)
    db.commit(); db.refresh(obj); return obj

@api.delete("/milestones/{milestone_id}", status_code=204)
def delete_milestone(milestone_id: int, db: Session = Depends(get_db)):
    obj = db.get(models.Milestone, milestone_id)
    if not obj: raise HTTPException(404, "Milestone not found")
    db.delete(obj); db.commit()

@api.get("/dashboard")
def dashboard(db: Session = Depends(get_db)):
    today = today_local()
    tasks = list(db.scalars(select(models.Task)).all())
    goals = list(db.scalars(select(models.Goal).options(selectinload(models.Goal.tasks), selectinload(models.Goal.milestones))).all())
    stats = {"total": len(tasks), "pending": sum(t.status == models.TaskStatus.pending for t in tasks),
             "in_progress": sum(t.status == models.TaskStatus.in_progress for t in tasks),
             "completed": sum(t.status == models.TaskStatus.completed for t in tasks),
             "overdue": sum(task_is_overdue(t, today) for t in tasks)}
    today_tasks = [t for t in tasks if t.due_date == today and t.status != models.TaskStatus.completed]
    upcoming = sorted([t for t in tasks if t.due_date and t.due_date > today and t.status != models.TaskStatus.completed], key=lambda t: t.due_date)[:6]
    open_goals = [g for g in goals if g.status == models.GoalStatus.active]
    goal_summaries = [goal_output(g) for g in open_goals]
    return {"date": today.isoformat(), "stats": stats,
            "today_tasks": [schemas.TaskOut.model_validate(t).model_dump(mode="json") for t in today_tasks[:6]],
            "upcoming_tasks": [schemas.TaskOut.model_validate(t).model_dump(mode="json") for t in upcoming],
            "short_term_goals": [g for g in goal_summaries if g["goal_type"] == models.GoalType.short_term][:4],
            "long_term_goals": [g for g in goal_summaries if g["goal_type"] == models.GoalType.long_term][:4]}

app.include_router(api)

from app.auth_routes import router as auth_router
app.include_router(auth_router)
