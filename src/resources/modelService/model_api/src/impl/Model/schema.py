from typing import List

from src.impl.Base.BaseSchema import BaseSchema


class TimeSeriesSchema(BaseSchema):
    pathname: str
    dates: List[str]
    values: List[float]

class FormulaSchema(BaseSchema):
    id: int
    version: str
    name: str
    stable_stove: bool
    stable_at: bool
    date: str
    file: str

class RawMaterialPresenceSchema(BaseSchema):
    formula_id: int
    formula_version: str
    raw_material_id: int
    percentage: float

class NutrientPresenceSchema(BaseSchema):
    formula_id: int
    formula_version: str
    nutrient_id: int
    percentage: float