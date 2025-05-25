from pydantic import BaseModel
from typing import Optional, Literal
from datetime import datetime

class BMIRecordBase(BaseModel):
    height: float
    weight: float
    bmi: float
    bmi_category: str
    mode: Literal["beast", "swasthya"] = "swasthya"

class BMIRecordCreate(BMIRecordBase):
    user_id: int

class BMIRecordInDB(BMIRecordBase):
    id: int
    user_id: int
    created_at: datetime
    
    class Config:
        orm_mode = True

class BMIRecord(BMIRecordInDB):
    pass