from datetime import datetime

from src.impl.Base.BaseService import BaseService
from src.utils.DSSReader import DSSReader
from src.utils.PathService import PathService
from src.utils.XMLReader import XMLReader


# from fastapi_sqlalchemy import db

class ModelService(BaseService):
    name = 'model_service'
    

    def get_all_last_execution(self):
        def extract_datetime(file_path):
            # The date and time are between the final "\\" and "_RUN" in each file path
            date_str = file_path.split("\\")[-1].split("_RUN")[0]
            return datetime.strptime(date_str, "%d%b%Y_%H-%M-%S")

        files = PathService.get_all_files()
        # Find the file with the most recent date and time
        if not files:
            return {"message": "No model execution found"}
        file = max(files, key=extract_datetime)

        xml_reader = XMLReader()
        xml_reader.load_file(file)
        dss_file, dss_path = xml_reader.get_dss_file_info()
        dss_file = PathService.add_directory_to_filename("data", dss_file)
        dss_reader = DSSReader(dss_file)
        dss_paths = dss_reader.list_options()
        dss_paths = DSSReader.group_and_merge_dates(dss_paths)
        data = []
        for dss_path in dss_paths[:4]:
            print(dss_path)
            data.append({"pathname": dss_path, "data": dss_reader.get_data(dss_path)})
        return data
    
    def get_last_execution(self, locations, measures):
        def extract_datetime(file_path):
            # The date and time are between the final "\\" and "_RUN" in each file path
            date_str = PathService.get_file_name(file_path).split("_RUN")[0]
            return datetime.strptime(date_str, "%d%b%Y_%H-%M-%S")

        files = PathService.get_all_files()
        # Find the file with the most recent date and time
        if not files:
            return {"message": "No model execution found"}
        file = max(files, key=extract_datetime)

        xml_reader = XMLReader()
        xml_reader.load_file(file)
        dss_file, dss_path = xml_reader.get_dss_file_info()
        dss_file = PathService.add_directory_to_filename("data", dss_file)
        dss_reader = DSSReader(dss_file)
        dss_paths = dss_reader.list_options(locations, measures)
        dss_paths = DSSReader.group_and_merge_dates(dss_paths)
        data = []
        for dss_path in dss_paths[:4]:
            print(dss_path)
            data.append({"pathname": dss_path, "data": dss_reader.get_data(dss_path)})
        return data