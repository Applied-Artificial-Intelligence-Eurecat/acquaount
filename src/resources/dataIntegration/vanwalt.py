import threading
from datetime import datetime, timedelta
from ftplib import FTP

ftp_host = '3.122.140.39'
ftp_user = 'acquaount'
ftp_password = '4BzUUyniqa6'

headers = []
output_data = []
device_id = ""


def process_line(line):
    global headers, output_data, device_id
    if line.startswith('Serial'):
        device_id = line.split(":")[1][1:]
        return None
    if line.startswith('Timestamp_UTC'):
        headers = line.split(",")
        return None
    if len(headers) > 0:
        ft_ts = ""
        for i, value in enumerate(line.split(",")):
            if i == 0:
                try:
                    date_format = "%d-%b-%Y %H:%M:%S"
                    dt_object = datetime.strptime(value, date_format)
                    ft_ts = dt_object.strftime("%Y-%m-%dT%H:%M:%SZ")
                except ValueError:
                    try:
                        val = value.split("\n")[0]
                    except IndexError:
                        continue
                    if val.startswith("File created: "):
                        val = val[len("File created: "):]
                        date_format = "%Y/%m/%d %H:%M:%S"
                        dt_object = datetime.strptime(val, date_format)
                        ft_ts = dt_object.strftime("%Y-%m-%dT%H:%M:%SZ")
            else:
                try:
                    measure = {
                        'info': {
                            'deviceID': device_id,
                            'timestamp': ft_ts
                        },
                        'values': {
                            headers[i]: value
                        }
                    }
                    output_data.append(measure)
                except IndexError:
                    continue


def ftp_connection():
    global output_data
    ftp = FTP()

    ftp.connect(ftp_host, port=9008)
    ftp.login(ftp_user, ftp_password)

    files = ftp.nlst()
    print("Files in the current directory:", files)

    # ftp.retrlines(f"RETR exemple.csv", callback=process_line)

    ftp.quit()


def get_function(thing, ftplock):
    def get_data_from_vanwalt():
        global output_data
        ftplock.acquire()

        ftp = FTP()

        ftp.connect(ftp_host, port=9008)
        ftp.login(ftp_user, ftp_password)

        files = ftp.nlst()
        # print("Files in the current directory:", files)

        selected_file = ""
        for file in files:
            if file.startswith(thing + "_" + (datetime.now() - timedelta(days=1)).strftime('%Y%m%d')):
                selected_file = file
                break

        ftp.retrlines(f"RETR {selected_file}", callback=process_line)

        ftp.quit()
        ftplock.release()
        return output_data

    return get_data_from_vanwalt


def get_historic_function(thing, ftplock):
    def get_data_from_vanwalt():
        global output_data
        ftplock.acquire()
        ftp = FTP()

        ftp.connect(ftp_host, port=9008)
        ftp.login(ftp_user, ftp_password)

        files = ftp.nlst()
        # print("Files in the current directory:", files)

        for file in files:
            if file.startswith(thing):
                ftp.retrlines(f"RETR {file}", callback=process_line)

        ftp.quit()
        ftplock.release()
        return output_data

    return get_data_from_vanwalt


if __name__ in "__main__":
    f = get_function("Well_N8_Arborea", threading.Lock())
    dt = f()
    print(dt)
    ks = []
    print(dt[0])
    for measure in dt:
        for key in measure['values']:
            if key not in ks:
                ks.append(key)
    print(ks, len(ks))
