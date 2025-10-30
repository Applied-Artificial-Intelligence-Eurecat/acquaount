import logging
import sys

from fastapi.middleware.cors import CORSMiddleware
from fastapi.routing import APIRouter

from src.configuration.Configuration import Configuration
from src.versions.v1 import router as v1_router


# from fastapi_sqlalchemy import DBSessionMiddleware


class App:

    def __init__(self, app):
        self.app = app

    def setup_routers(self):
        self.app.include_router(v1_router)
        for route in self.app.routes:
            if isinstance(route, APIRouter):
                route.operation_id = route.tags[-1].replace(
                    ' ', '').lower() if len(route.tags) > 0 else ''
                route.operation_id += '_' + route.name

    def setup_middlewares(self):
        pass
        # self.app.add_middleware(DBSessionMiddleware, db_url=Configuration.database.url)
        self.app.add_middleware(CORSMiddleware,
                                allow_origins=Configuration.cors.origins,
                                allow_credentials=Configuration.cors.credentials,
                                allow_methods=Configuration.cors.methods,
                                allow_headers=Configuration.cors.headers,
                                expose_headers=Configuration.cors.expose_headers, )

    def setup_exceptions(self):
        from src.error import error_handler as eh
        from src.error.UnavailableServiceException import UnavailableServiceException
        from src.error.InvalidDataException import InvalidDataException
        self.app.add_exception_handler(InvalidDataException, eh.invalid_data_exception_handler)
        self.app.add_exception_handler(UnavailableServiceException, eh.unavailable_service_exception_handler)

    def setup_logger(self, logger):
        logger.setLevel(logging.DEBUG)
        stream_handler = logging.StreamHandler(sys.stdout)
        log_formatter = logging.Formatter(
            '%(asctime)s [%(processName)s: %(process)d] [%(threadName)s: %(thread)d] [%(levelname)s] %(name)s: %(message)s'
        )
        stream_handler.setFormatter(log_formatter)
        logger.addHandler(stream_handler)

    def setup_all(self, logger):
        self.setup_logger(logger)
        self.setup_routers()
        self.setup_middlewares()
        self.setup_exceptions()
