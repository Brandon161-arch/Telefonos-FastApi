from typing import Optional
from pydantic import BaseModel, ConfigDict

class BrandBase(BaseModel):
    name: str
    slug: str
    logo_url: Optional[str] = None
    description: Optional[str] = None

class BrandCreate(BrandBase):
    pass

class BrandUpdate(BaseModel):
    name: Optional[str] = None
    slug: Optional[str] = None
    logo_url: Optional[str] = None
    description: Optional[str] = None

class BrandResponse(BrandBase):
    id: int

    model_config = ConfigDict(from_attributes=True)
