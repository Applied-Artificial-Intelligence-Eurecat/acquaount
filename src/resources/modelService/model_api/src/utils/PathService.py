from pathlib import Path

RESULTS_PATH = Path('data/results')
RESULTS_DIR = "data/results"


class PathService:
    @staticmethod
    def get_all_files_from(input_dir: Path) -> list[str]:
        return [str(path) for path in input_dir.iterdir()]
    
    @staticmethod
    def get_all_files() -> list[str]:
        return PathService.get_all_files_from(RESULTS_PATH)
    
    @staticmethod
    def get_file_name(file_path: str) -> str:
        return Path(file_path).name
    
    @staticmethod
    def rename_file(origin_file: str, new_name: str):
        origin_file = Path(origin_file)
        """Rename the file to the new name."""
        if not origin_file.is_file():
            print(f"File '{origin_file}' does not exist.")
            return

        new_path = origin_file.with_name(new_name)

        try:
            origin_file.rename(new_path)
            print(f"File renamed to '{new_name}' successfully.")
        except Exception as e:
            print(f"Error renaming file: {e}")
    
    @staticmethod
    def add_directory_to_filename(directory: str, filename: str) -> str:
        """Add a directory to a filename and return the full path."""
        full_path = Path(directory) / filename
        return str(full_path)