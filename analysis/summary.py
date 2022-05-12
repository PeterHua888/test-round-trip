import pandas as pd
import re

def compare_app_service_against_vm():
    f= open('round_trip_comparison.log', 'r')
    logs = f.read()
    round_trip_time_app = re.findall('it takes (.*) seconds for app service', logs)
    round_trip_time_vm = re.findall('it takes (.*) seconds for vm', logs)
    round_trip_time_app = pd.Series([float(item) for item in round_trip_time_app])
    round_trip_time_vm = pd.Series([float(item) for item in round_trip_time_vm])
    print("Round trip time summary from HK App Service to UK App Service")
    print(round_trip_time_app.describe())
    print("\n")
    print("Round trip time summary from HK App Service to UK VM")
    print(round_trip_time_vm.describe())
    print("\n")

def summarise_app_service_round_trip_time():
    f = open('round_trip.log', 'r')
    logs = f.read()
    round_trip_time = re.findall("The round trip time is (.*) seconds, response is {'code': 200, 'response': 'OK'}", logs)
    round_trip_time = pd.Series([float(item) for item in round_trip_time])
    print("Round trip time summary from HK App Service to UK App Service")
    print(round_trip_time.describe())
    print("\n")
    print("\n")

if __name__ == "__main__":
    summarise_app_service_round_trip_time()
    compare_app_service_against_vm()