from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Enum
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.db.database import Base
from app.models.user import ModeType

class FoodEntry(Base):
    __tablename__ = "food_entries"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    food_name = Column(String)
    image_path = Column(String, nullable=True)
    mode = Column(Enum(ModeType), default=ModeType.SWASTHYA)
    
    # Basic nutritional information
    calories = Column(Float, nullable=True)  # kcal
    protein = Column(Float, nullable=True)   # g
    carbs = Column(Float, nullable=True)     # g
    fat = Column(Float, nullable=True)       # g
    
    # Detailed nutritional information
    saturated_fat = Column(Float, nullable=True)  # g
    fiber = Column(Float, nullable=True)          # g
    sugar = Column(Float, nullable=True)          # g
    cholesterol = Column(Float, nullable=True)    # mg
    sodium = Column(Float, nullable=True)         # mg
    calcium = Column(Float, nullable=True)        # mg
    iron = Column(Float, nullable=True)           # mg
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationship with User
    user = relationship("User", backref="food_entries")