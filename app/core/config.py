import os
from typing import List

class Settings:
    PROJECT_NAME: str = "ElectroPhone Store"
    PROJECT_VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Secret Key for JWT
    SECRET_KEY: str = os.getenv("SECRET_KEY", "super-secret-key-change-in-production-telefonos-fastapi-2026")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7 # 7 days
    
    # Database
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./telefonos.db")
    
    # Admin defaults
    FIRST_ADMIN_EMAIL: str = os.getenv("FIRST_ADMIN_EMAIL", "admin@electrophone.com")
    FIRST_ADMIN_PASSWORD: str = os.getenv("FIRST_ADMIN_PASSWORD", "admin123456")

settings = Settings()
