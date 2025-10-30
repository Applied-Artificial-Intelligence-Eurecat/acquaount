from typing import Annotated

from fastapi import APIRouter
from fastapi import Query
from src.impl.Model.service import ModelService

router = APIRouter(prefix='/model', tags=['Model'])

model_service = ModelService()

@router.get('/last')
def get_all_last():
    return model_service.get_all_last_execution()

@router.get('/last/')
async def get_last(locations: Annotated[list, Query()] = [], measures: Annotated[list, Query()] = []):
    return model_service.get_last_execution(locations, measures)