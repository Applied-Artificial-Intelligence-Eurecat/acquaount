from fastapi import APIRouter
from src.impl.Location.service import LocationService

router = APIRouter(prefix='/location', tags=['Location'])

location_service = LocationService()

@router.get("")
def get_all_locations():
    return location_service.get_all()

@router.get("/{measures}")
def get_locations(measures):
    return location_service.get_by_measure(measures)

