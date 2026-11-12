from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
    greeting: str = "Добро пожаловать в гостевую книгу!"
    database_url: str
    app_version: str = "1.0.0"


settings = Settings()
