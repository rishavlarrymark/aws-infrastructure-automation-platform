
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr, Field
import os, time, hmac, hashlib, base64, json, smtplib
from email.message import EmailMessage
from urllib.parse import quote
from google.auth.transport.requests import Request as GoogleRequest
from google.oauth2 import id_token
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.auth import (
    create_access_token,
    get_current_user,
    hash_password,
    verify_password,
)
from app.config import settings
from app.database import get_db
from app.models import User
from app.schemas import (
    GoogleLoginRequest,
    LoginRequest,
    RegisterRequest,
    TokenOut,
    UserOut,
)


class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ResetPasswordRequest(BaseModel):
    token: str = Field(min_length=20, max_length=4096)
    password: str = Field(min_length=8, max_length=128)

def _reset_secret() -> bytes:
    secret = settings.daymark_reset_secret

    if len(secret) < 32:
        raise HTTPException(
            status_code=503,
            detail="Password reset is not configured. Set DAYMARK_RESET_SECRET (32+ characters).",
        )

    return secret.encode()

def _make_reset_token(email: str) -> str:
    payload = base64.urlsafe_b64encode(json.dumps({"email": email, "exp": int(time.time()) + 1800}, separators=(",", ":")).encode()).decode().rstrip("=")
    signature = hmac.new(_reset_secret(), payload.encode(), hashlib.sha256).hexdigest()
    return payload + "." + signature

def _read_reset_token(token: str) -> str:
    try:
        payload, signature = token.rsplit(".", 1)
        expected = hmac.new(_reset_secret(), payload.encode(), hashlib.sha256).hexdigest()
        if not hmac.compare_digest(signature, expected):
            raise ValueError()
        data = json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))
        if int(data["exp"]) < int(time.time()):
            raise ValueError()
        return str(data["email"]).strip().lower()
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid or expired password-reset token")

def _send_reset_email(email: str, token: str) -> None:
    host = settings.smtp_host
    username = settings.smtp_username
    password = settings.smtp_password
    sender = settings.smtp_from or username
    port = settings.smtp_port
    frontend_url = os.getenv("FRONTEND_RESET_URL", "http://localhost:5173/reset-password")
    if not all((host, username, password, sender)):
        raise HTTPException(status_code=503, detail="Password reset email is not configured. Set SMTP_HOST, SMTP_USERNAME, SMTP_PASSWORD and SMTP_FROM.")
    message = EmailMessage()
    message["Subject"] = "Reset your Daymark password"
    message["From"] = sender
    message["To"] = email
    message.set_content(f"Use this link within 30 minutes to reset your Daymark password:\
{frontend_url}?token={quote(token)}\
\
If you did not request this, you can ignore this email.")
    port = int(os.getenv("SMTP_PORT", "587"))
    with smtplib.SMTP(host, port, timeout=15) as server:
        server.starttls()
        server.login(username, password)
        server.send_message(message)


router = APIRouter(prefix="/api/v1/auth", tags=["Authentication"])


def issue_token(user: User) -> TokenOut:
    return TokenOut(
        access_token=create_access_token(user.id),
        user=UserOut.model_validate(user),
    )


@router.post(
    "/register",
    response_model=TokenOut,
    status_code=status.HTTP_201_CREATED,
)
def register(
    data: RegisterRequest,
    db: Session = Depends(get_db),
):
    email = str(data.email).strip().lower()

    existing_user = db.scalar(
        select(User).where(User.email == email)
    )
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists",
        )

    user = User(
        full_name=data.full_name.strip(),
        email=email,
        password_hash=hash_password(data.password),
    )
    db.add(user)

    try:
        db.commit()
        db.refresh(user)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Unable to create an account with these details",
        )

    return issue_token(user)


@router.post("/login", response_model=TokenOut)
def login(
    data: LoginRequest,
    db: Session = Depends(get_db),
):
    email = str(data.email).strip().lower()

    user = db.scalar(
        select(User).where(User.email == email)
    )

    if (
        user is None
        or user.password_hash is None
        or not verify_password(data.password, user.password_hash)
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account is disabled",
        )

    return issue_token(user)


@router.post("/google", response_model=TokenOut)
def google_login(
    data: GoogleLoginRequest,
    db: Session = Depends(get_db),
):
    if not settings.google_client_id:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Google Sign-In is not configured yet",
        )

    try:
        claims = id_token.verify_oauth2_token(
            data.credential,
            GoogleRequest(),
            settings.google_client_id,
        )
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Google credential",
        )

    google_sub = claims.get("sub")
    email = str(claims.get("email", "")).strip().lower()
    email_verified = claims.get("email_verified") is True
    full_name = str(claims.get("name", "")).strip()

    if not google_sub or not email or not email_verified:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Google account must have a verified email",
        )

    user = db.scalar(
        select(User).where(User.google_sub == google_sub)
    )

    if user is not None:
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="This account is disabled",
            )
        return issue_token(user)

    # Do not silently link Google to an existing password account.
    existing_user = db.scalar(
        select(User).where(User.email == email)
    )
    if existing_user is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "An account with this email already exists. "
                "Sign in with that account before linking Google."
            ),
        )

    user = User(
        full_name=full_name or email.split("@")[0],
        email=email,
        google_sub=google_sub,
        password_hash=None,
    )
    db.add(user)

    try:
        db.commit()
        db.refresh(user)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Unable to complete Google Sign-In. Please try again.",
        )

    return issue_token(user)


@router.get("/me", response_model=UserOut)
def get_me(
    current_user: User = Depends(get_current_user),
):
    return current_user


@router.post("/forgot-password")
def forgot_password(data: ForgotPasswordRequest, db: Session = Depends(get_db)):
    # Do not disclose whether an account exists. Email delivery failures are logged by the API's handler.
    email = str(data.email).strip().lower()
    user = db.scalar(select(User).where(User.email == email))
    if user is not None and user.is_active and user.password_hash is not None:
        token = _make_reset_token(email)
        _send_reset_email(email, token)
    return {"message": "If an eligible account exists, password-reset instructions will be sent."}


@router.post("/reset-password")
def reset_password(data: ResetPasswordRequest, db: Session = Depends(get_db)):
    email = _read_reset_token(data.token)
    user = db.scalar(select(User).where(User.email == email))
    if user is None or user.password_hash is None or not user.is_active:
        raise HTTPException(status_code=400, detail="Invalid or expired password-reset token")
    user.password_hash = hash_password(data.password)
    db.add(user)
    db.commit()
    return {"message": "Password updated. Please sign in with your new password."}
