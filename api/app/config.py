from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "sqlite:///./tamilar_calendar.db"
    api_prefix: str = "/api/v1"
    cors_origins: str = "*"
    # Optional: https://api.prokerala.com (free tier ~5000 credits/month)
    prokerala_client_id: str = ""
    prokerala_client_secret: str = ""

    class Config:
        env_file = ".env"


settings = Settings()
