import xml.etree.ElementTree as ET

class XMLReader:
    def __init__(self, file_path=None):
        self.file_path = file_path
        self.tree = None
        self.root = None
        if file_path:
            self.load_file(file_path)

    def load_file(self, file_path):
        """Load and parse the XML file."""
        self.file_path = file_path
        try:
            self.tree = ET.parse(file_path)
            self.root = self.tree.getroot()
            print(f"File '{file_path}' loaded successfully.")
        except Exception as e:
            print(f"Error loading file '{file_path}': {e}")

    def get_root_tag(self):
        """Get the tag of the root element."""
        if self.root:
            return self.root.tag
        else:
            print("No XML file loaded.")
            return None

    def find_elements(self, tag):
        """Find all elements with a specific tag."""
        if self.root:
            return self.root.findall(tag)
        else:
            print("No XML file loaded.")
            return []
        
    def find_element(self, tag):
        """Find the first element with a specific tag."""
        if self.root:
            return self.root.find(tag)
        else:
            print("No XML file loaded.")
            return None

    def get_element_text(self, element):
        """Get the text content of an element."""
        if element is not None:
            return element.text
        else:
            print("Element is None.")
            return None

    def get_element_attributes(self, element):
        """Get the attributes of an element."""
        if element is not None:
            return element.attrib
        else:
            print("Element is None.")
            return None

    def print_element(self, element):
        """Print an element and its sub-elements."""
        if element is not None:
            print(ET.tostring(element, encoding='unicode'))
        else:
            print("Element is None.")

    def get_dss_file_info(self):
        """Get the DssFileName and DssPathname from the XML."""
        if not self.root:
            print("No XML file loaded.")
            return None, None
        
        time_series_element = self.root.find(".//TimeSeries")
        if time_series_element is not None:
            dss_file_name_element = time_series_element.find("DssFileName")
            dss_pathname_element = time_series_element.find("DssPathname")
            dss_file_name = self.get_element_text(dss_file_name_element)
            dss_pathname = self.get_element_text(dss_pathname_element)
            return dss_file_name, dss_pathname
        else:
            print("TimeSeries element not found.")
            return None, None




