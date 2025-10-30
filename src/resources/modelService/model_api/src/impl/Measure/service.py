from src.impl.Base.BaseService import BaseService
from src.utils.DSSReader import DSSReader
from src.utils.PathService import PathService
from src.utils.XMLReader import XMLReader

DATA_DIRECTORY="data"

class MeasureService(BaseService):
    name = 'measure_service'

    def get_all(self):
        files = PathService.get_all_files()
        if not files:
            return {"message": "No model execution found"}
        file = files[0]

        xml_reader = XMLReader()
        xml_reader.load_file(file)
        dss_file, dss_path = xml_reader.get_dss_file_info()
        dss_file = PathService.add_directory_to_filename(DATA_DIRECTORY, dss_file)
        dss_reader = DSSReader(dss_file, dss_path)
        return dss_reader.get_measures()

    def get_by_location(self, locations):
        files = PathService.get_all_files()
        if not files:
            return {"message": "No model execution found"}
        file = files[0]

        xml_reader = XMLReader()
        xml_reader.load_file(file)
        dss_file, dss_path = xml_reader.get_dss_file_info()
        dss_file = PathService.add_directory_to_filename(DATA_DIRECTORY, dss_file)
        dss_reader = DSSReader(dss_file)
        return dss_reader.get_measures(locations)