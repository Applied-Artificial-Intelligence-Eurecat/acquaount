import importlib

from src.utils.Singleton import Singleton


class BaseService(metaclass=Singleton):

    def needs_service(service):
        
        def wrapper(f):

            def get_service(*args):
                s = args[0]
                ser = service
                if isinstance(service, str):
                    ser = importlib.import_module(
                        'src.impl.' + service.replace('Service', '') +
                        '.' + service)
                    ser = getattr(ser, service)
                
                if getattr(s, service) is None:
                    setattr(s, service, ser())
                return f(*args)
            return get_service
        
        return wrapper