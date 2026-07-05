from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "sqlite:///./tamilar_calendar.db"
    api_prefix: str = "/api/v1"
    cors_origins: str = "*"
    # Optional: https://api.prokerala.com (free tier ~5000 credits/month)
    prokerala_client_id: str = ""
    prokerala_client_secret: str = ""
    # Path to Firebase service account JSON (FCM push after metal rates sync)
    firebase_credentials_path: str = ""
    # Public API origin for push image URLs (e.g. http://192.168.1.8:4000 or https://api.example.com)
    public_base_url: str = ""

    class Config:
        env_file = ".env"


settings = Settings()
