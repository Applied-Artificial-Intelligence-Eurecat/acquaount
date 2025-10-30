import logging

from fastapi import FastAPI
from fastapi.responses import RedirectResponse

from App import App
from src.configuration.Configuration import Configuration

# from fastapi_sqlalchemy import DBSessionMiddleware
# from sqlalchemy import create_engine
# from src.impl.Base.BaseModel import Base

Configuration()

# Base.metadata.create_all(bind=create_engine(Configuration.database.url))

tags_metadata = [

]

app = FastAPI(title="AQCUAOUNT Model API",
              description="AQCUAOUNT Model API",
              version="0.1.0",
              docs_url="/docs",
              redoc_url="/redoc",
              openapi_url="/openapi.json",
              openapi_tags=tags_metadata,
              debug=True,
              swagger_ui_parameters={"syntaxHighlight.theme": "obsidian"})

logger = logging.getLogger(__name__)


@app.get("/")
def root():
    return RedirectResponse(url="/docs")


App(app).setup_all(logger)
