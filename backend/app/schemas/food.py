from pydantic import BaseModel
from typing import Optional, Literal
from datetime import datetime

class FoodEntryBase(BaseModel):
    food_name: str
    mode: Literal["beast", "swasthya"] = "swasthya"
    
    # Basic nutritional information
    calories: Optional[float] = None
    protein: Optional[float] = None
    carbs: Optional[float] = None
    fat: Optional[float] = None
    
    # Detailed nutritional information
    saturated_fat: Optional[float] = None
    fiber: Optional[float] = None
    sugar: Optional[float] = None
    cholesterol: Optional[float] = None
    sodium: Optional[float] = None
    calcium: Optional[float] = None
    iron: Optional[float] = None

class FoodEntryCreate(FoodEntryBase):
    user_id: int

class FoodEntryInDB(FoodEntryBase):
    id: int
    user_id: int
    image_path: Optional[str] = None
    created_at: datetime
    
    class Config:
        orm_mode = True

class FoodEntry(FoodEntryInDB):
    pass