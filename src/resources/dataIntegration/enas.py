import glob
import threading
from datetime import datetime
from ftplib import FTP
import math

ftp_host = 'ftp-spt.enas.sardegna.it'
ftp_user = 'ftp.acquaount'
ftp_password = 'acquaount'

headers = []
output_data = []
device_id = ""

values = {
    '1067': 'Water Storage',
    '10329': 'Water Storage',
    '40000': 'Water Flow',
    '50065': 'Water Flow',
    '50058': 'Water Flow',
}


def level_to_volume(sensor_id, level_m_slm):
    if sensor_id == '1067':
        volume = (2894 * (level_m_slm ** 3) - 111359 * (level_m_slm ** 2) + 1634875 * level_m_slm - 8486796)
        return int(math.floor(volume))
    elif sensor_id == '10329':
        if level_m_slm < 80:
            # formula for levels < 80 m s.l.m.
            volume = 0.0336 * math.exp(0.0926 * level_m_slm)
        else:
            # formula for levels >= 80 m s.l.m.
            volume = 0.256 * (level_m_slm ** 2) - 31.129 * level_m_slm + 909.35
        return volume
    return 0.0


def process_line(line):
    global headers, output_data, device_id
    arr = line.split(";")
    date_format = "%Y-%m-%d %H:%M"
    try:
        dt_object = datetime.strptime(arr[1].strip("\""), date_format)
    except ValueError:
        return None
    ft_ts = dt_object.strftime("%Y-%m-%dT%H:%M:%SZ")

    if arr[0] not in values:
        return None

    measure = {
        'info': {
            'deviceID': arr[0],
            'timestamp': ft_ts
        },
        'values': {
            values[arr[0]]: float(arr[2].replace(",", "."))
        }
    }
    output_data.append(measure)

    if values[arr[0]] == "Water Storage":
        measure = {
            'info': {
                'deviceID': arr[0],
                'timestamp': ft_ts
            },
            'values': {
                values[arr[0]] + ' m3': level_to_volume(arr[0], float(arr[2].replace(",", ".")))
            }
        }
        output_data.append(measure)
    return None


def process_line2(line, thing, value):
    global headers, output_data, device_id
    arr = line.split(";")
    if arr[0].startswith("\""):
        date_format = "%Y-%m-%d %H:%M"
        dt_object = datetime.strptime(arr[0].strip("\"")[:-3], date_format)
        ft_ts = dt_object.strftime("%Y-%m-%dT%H:%M:%SZ")

        try:
            measure = {
                'info': {
                    'deviceID': thing,
                    'timestamp': ft_ts
                },
                'values': {
                    value: float(arr[2].replace(",", "."))
                }
            }
            output_data.append(measure)
        except Exception:
            pass
    else:
        date_format = "%d/%m/%Y %H:%M"
        dt_object = datetime.strptime(arr[0].strip("\""), date_format)
        ft_ts = dt_object.strftime("%Y-%m-%dT%H:%M:%SZ")

        try:
            measure = {
                'info': {
                    'deviceID': thing,
                    'timestamp': ft_ts
                },
                'values': {
                    value: float(arr[1].replace(",", "."))
                }
            }
            output_data.append(measure)
        except Exception:
            pass


def ftp_connection():
    global output_data
    ftp = FTP()

    ftp.connect(ftp_host, port=21)
    ftp.login(ftp_user, ftp_password)

    files = ftp.nlst()
    print("Files in the current directory:", files)

    # ftp.retrlines(f"RETR 1067.csv", callback=process_line)

    ftp.quit()


def get_function(thing, ftplock):
    def get_data_from_enas():
        global output_data
        ftplock.acquire()

        ftp = FTP()

        ftp.connect(ftp_host, port=21)
        ftp.login(ftp_user, ftp_password)

        files = ftp.nlst()
        # print("Files in the current directory:", files)

        headers = []
        output_data = []
        device_id = ""

        selected_file = ""
        for file in files:
            if file.startswith(thing):
                selected_file = file
                break

        ftp.retrlines(f"RETR {selected_file}", callback=process_line)

        ftp.quit()
        if ftplock.locked():
            ftplock.release()
        return output_data

    return get_data_from_enas


def get_historic_function(thing, ftplock):
    def get_data_from_enas():
        global output_data
        ftplock.acquire()
        ftp = FTP()

        ftp.connect(ftp_host, port=9008)
        ftp.login(ftp_user, ftp_password)

        files = ftp.nlst()
        # print("Files in the current directory:", files)

        headers = []
        output_data = []
        device_id = ""

        for file in files:
            if file.startswith(thing):
                ftp.retrlines(f"RETR {file}", callback=process_line)

        ftp.quit()
        if ftplock.locked():
            ftplock.release()
        return output_data

    return get_data_from_enas


def get_historic_function2(thing):
    def get_data_from_enas():
        global output_data
        output_data = []

        for file in glob.glob("dades/*"):
            if file[len("dades\\"):].startswith(thing):
                with open(file, 'r') as f:
                    for line in [l.rstrip('\n') for l in f.readlines()][1:]:
                        process_line2(line, thing, values[thing])

        return output_data

    return get_data_from_enas


if __name__ in "__main__":
    print(get_function('1067', threading.Lock())())
