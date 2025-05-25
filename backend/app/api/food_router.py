from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile, Form
from sqlalchemy.orm import Session
from typing import List, Optional
import os
import shutil
from datetime import datetime

from app.db.database import get_db
from app.models.food import FoodEntry
from app.schemas.food import FoodEntry as FoodEntrySchema, FoodEntryCreate
from app.core.security import get_current_user
from app.models.user import User

router = APIRouter()

# Create directory for food images if it doesn't exist
UPLOAD_DIR = "uploads/food_images"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.post("/log", response_model=FoodEntrySchema, status_code=status.HTTP_201_CREATED)
async def create_food_entry(
    user_id: int = Form(...),
    food_name: str = Form(...),
    mode: str = Form("swasthya"),
    calories: Optional[float] = Form(None),
    protein: Optional[float] = Form(None),
    carbs: Optional[float] = Form(None),
    fat: Optional[float] = Form(None),
    saturated_fat: Optional[float] = Form(None),
    fiber: Optional[float] = Form(None),
    sugar: Optional[float] = Form(None),
    cholesterol: Optional[float] = Form(None),
    sodium: Optional[float] = Form(None),
    calcium: Optional[float] = Form(None),
    iron: Optional[float] = Form(None),
    image: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Verify user has permission to create entry for this user_id
    if user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to create entries for other users"
        )
    
    # Save image if provided
    image_path = None
    if image:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{user_id}_{timestamp}_{image.filename}"
        image_path = os.path.join(UPLOAD_DIR, filename)
        
        with open(image_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
    
    # Create food entry
    db_food = FoodEntry(
        user_id=user_id,
        food_name=food_name,
        mode=mode,
        calories=calories,
        protein=protein,
        carbs=carbs,
        fat=fat,
        saturated_fat=saturated_fat,
        fiber=fiber,
        sugar=sugar,
        cholesterol=cholesterol,
        sodium=sodium,
        calcium=calcium,
        iron=iron,
        image_path=image_path
    )
    
    db.add(db_food)
    db.commit()
    db.refresh(db_food)
    
    return db_food

@router.get("/history/{user_id}", response_model=List[FoodEntrySchema])
async def get_food_history(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Verify user has permission to view entries for this user_id
    if user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view entries for other users"
        )
    
    # Get food entries
    food_entries = db.query(FoodEntry).filter(FoodEntry.user_id == user_id).order_by(FoodEntry.created_at.desc()).all()
    
    return food_entries