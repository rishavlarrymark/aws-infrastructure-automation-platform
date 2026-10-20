from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    app_name: str = "Task Management API"
    app_env: str = "development"
    port: int = 8000
    database_url: str = "postgresql+psycopg://taskapp:change-this-local-password@localhost:5432/taskmanager"
    cors_origins: str = "http://localhost:5173"
    app_timezone: str = "Asia/Kolkata"
    log_level: str = "INFO"
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]

@lru_cache
def get_settings() -> Settings:
    return Settings()

settings = get_settings()
