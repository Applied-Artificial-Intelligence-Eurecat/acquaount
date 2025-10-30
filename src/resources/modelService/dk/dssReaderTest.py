from collections import defaultdict

from pydsstools.heclib.dss import HecDss


class DSSReader:
    def __init__(self, dss_file, pathname=None):
        self.dss_file = dss_file
        self.pathname = pathname
        self.ts = None
        self.dates = []
        self.values = []
        self.filtered_dates = []
        self.filtered_values = []

    def set_pathname(self, pathname):
        self.pathname = pathname

    def read_data(self, pathname):
        fid = HecDss.Open(self.dss_file)
        self.ts = fid.read_ts(pathname, window_flag=0)

        self.dates = self.ts.pytimes
        self.values = self.ts.values

    def _filter_data(self):
        try:
            # Assuming self.values is a numpy array, the following is more efficient and safe
            mask = self.values >= 0  # Create a boolean mask where values are >= 0
            self.filtered_dates = [date for date, m in zip(self.dates, mask) if m]
            self.filtered_values = self.values[mask].tolist()  # Use the mask to filter values and convert to list
            # print(type(self.filtered_values))
            # print(self.filtered_values)
            self.filtered_values = [round(value, 2) for value in self.filtered_values]
        except Exception:
            return

    def get_data(self, pathname):
        self.read_data(pathname)
        self._filter_data()
        return {"dates": self.filtered_dates, "values": self.filtered_values}

    @staticmethod
    def group_and_merge_dates(paths):
        grouped_paths = defaultdict(list)

        for path in paths:
            # Split the path into parts
            parts = path.split('/')
            # Use the key that doesn't include the date (assuming the date is the 4th part)
            key = '/'.join(parts[:4] + parts[5:])
            # Extract the date
            date = parts[4]
            # Group by the key without the date
            grouped_paths[key].append(date)

        merged_paths = []

        for key, dates in grouped_paths.items():
            # Sort dates correctly by converting the date string to a format suitable for sorting
            dates.sort(key=lambda x: (int(x[-4:]), x[2:5]))  # Sort by year first, then by month/day
            start_date = dates[0]
            end_date = dates[-1]
            # Recreate the full path with the merged date range
            merged_path = f"{key.split('/')[0]}/{key.split('/')[1]}/{key.split('/')[2]}/{key.split('/')[3]}/{start_date} - {end_date}/{key.split('/')[4]}/{key.split('/')[5]}/"
            merged_paths.append(merged_path)

        return merged_paths

    def list_options(self, locations=None, measures=None):
        """List all the pathnames in the DSS file."""
        pathnames = []
        fid = HecDss.Open(self.dss_file)
        if not locations and not measures:
            return fid.getPathnameList("//*/*/*/*/*/", sort=1)
        if locations and not measures:
            for location in locations:
                pathnames += fid.getPathnameList(f"//{location}/*/*/*/*/", sort=1)
            return pathnames
        if not locations and measures:
            for measure in measures:
                pathnames += fid.getPathnameList(f"//*/{measure}/*/*/*/", sort=1)
            return pathnames
        for location in locations:
            for measure in measures:
                pathnames += fid.getPathnameList(f"//{location}/{measure}/*/*/*/", sort=1)
        return pathnames

    def get_locations(self, second_field=None):
        """Return all the different first fields in the DSS file."""
        pathnames = self.list_options()
        first_fields = set()
        for pathname in pathnames:
            parts = pathname.split('/')
            if len(parts) > 1 and (second_field is None or parts[3] == second_field):
                first_fields.add(parts[2])
        return list(first_fields)

    def get_measures(self, first_field=None):
        """Return all the second fields for a given first field in the DSS file."""
        pathnames = self.list_options()
        second_fields = set()
        for pathname in pathnames:
            parts = pathname.split('/')
            if len(parts) > 2 and (first_field is None or parts[2] == first_field):
                second_fields.add(parts[3])
        return list(second_fields)


if __name__ in "__main__":
    reader = DSSReader('results/ERA5_Land_2006_2022_v2.dss')
    for pathname in reader.list_options(["CANTONIERA"], ["FLOW", "STORAGE"])[1:]:
        print(reader.get_data(pathname))
        break

