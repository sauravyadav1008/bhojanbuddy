from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.db.database import get_db
from app.models.bmi import BMIRecord
from app.schemas.bmi import BMIRecordCreate, BMIRecord as BMIRecordSchema
from app.core.security import get_current_user
from app.models.user import User

router = APIRouter()

@router.post("/", response_model=BMIRecordSchema, status_code=status.HTTP_201_CREATED)
async def create_bmi_record(
    bmi_data: BMIRecordCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Verify user has permission to create record for this user_id
    if bmi_data.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to create records for other users"
        )
    
    # Create BMI record
    db_bmi = BMIRecord(
        user_id=bmi_data.user_id,
        height=bmi_data.height,
        weight=bmi_data.weight,
        bmi=bmi_data.bmi,
        bmi_category=bmi_data.bmi_category,
        mode=bmi_data.mode
    )
    
    db.add(db_bmi)
    db.commit()
    db.refresh(db_bmi)
    
    return db_bmi

@router.get("/{user_id}", response_model=List[BMIRecordSchema])
async def get_bmi_history(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Verify user has permission to view records for this user_id
    if user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view records for other users"
        )
    
    # Get BMI records
    bmi_records = db.query(BMIRecord).filter(BMIRecord.user_id == user_id).order_by(BMIRecord.created_at.desc()).all()
    
    return bmi_records