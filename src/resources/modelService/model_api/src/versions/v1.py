from fastapi import APIRouter
from src.impl.Location import router as Location
from src.impl.Measure import router as Measure
from src.impl.Model import router as Model

router = APIRouter(prefix="/v1")

router.include_router(Model.router)
router.include_router(Location.router)
router.include_router(Measure.router)
