from fastapi import APIRouter
from src.impl.Measure.service import MeasureService

router = APIRouter(prefix='/measure', tags=['Measure'])

measure_service = MeasureService()

@router.get("")
def get_all_measures():
    return measure_service.get_all()

@router.get("/{locations}")
def get_measures(locations):
    return measure_service.get_by_location(locations)

