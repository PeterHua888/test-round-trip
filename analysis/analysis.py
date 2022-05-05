import pandas as pd
import re

with open('round_trip.log', 'r') as f:
    logs = f.read()
    round_trip_time_app = re.findall('it takes (.*) seconds for app service', logs)
    round_trip_time_vm = re.findall('it takes (.*) seconds for vm', logs)
    round_trip_time_app = pd.Series([float(item) for item in round_trip_time_app])
    round_trip_time_vm = pd.Series([float(item) for item in round_trip_time_vm])
    print(round_trip_time_app.describe())
    print(round_trip_time_vm.describe())