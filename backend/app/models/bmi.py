from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Enum
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.db.database import Base
from app.models.user import ModeType

class BMIRecord(Base):
    __tablename__ = "bmi_records"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    height = Column(Float)  # in cm
    weight = Column(Float)  # in kg
    bmi = Column(Float)
    bmi_category = Column(String)
    mode = Column(Enum(ModeType), default=ModeType.SWASTHYA)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationship with User
    user = relationship("User", backref="bmi_records")