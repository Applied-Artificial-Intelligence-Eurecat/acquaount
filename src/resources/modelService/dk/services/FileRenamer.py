from PathService import PathService
from XMLReader import XMLReader

# Example usage:
if __name__ == "__main__":
    # Create an instance of FileRenamer with the initial file path
    files = PathService.get_all_files()
    xml_reader = XMLReader()
    for file in files:
        xml_reader.load_file(file)
        # Find elements with a specific tag
        element = xml_reader.find_element("ExecutionTime")

        text = xml_reader.get_element_text(element)
        text = "_".join(text.split(", ")).replace(":", "-")
        print(f"Text: {text}")
    
        # Rename the file
        if text in PathService.get_file_name(file):
            print("File already renamed")
        else:
            PathService.rename_file(file, f"{text}_{PathService.get_file_name(file)}")
