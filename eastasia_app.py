from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime
from flask import Flask, jsonify
from pytz import timezone
import requests
import signal
import time

app = Flask(__name__)

# Register an handler for the timeout
def handler(signum, frame):
    print("Timeout for this request")

def sensor():
    start_time = time.time()
    response = requests.get("https://test-app-uksouth-001.azurewebsites.net")
    response = response.json()
    round_trip_time = time.time()-start_time
    print("The round trip time is %s seconds, response is %s" % (
            round_trip_time, 
            response
        ) + 
        "\nat "+str(datetime.now(timezone("Australia/Sydney")).replace(tzinfo=None))
    )

# Register the signal function handler
signal.signal(signal.SIGALRM, handler)
# Define a timeout for your function
signal.alarm(20)

sched = BackgroundScheduler(daemon=True)
sched.add_job(sensor,'interval',seconds=3)
sched.start()

@app.route("/")
def hello_world():
    return jsonify({"response": "OK", "code": 200})

if __name__ == "__main__":
    app.run(port = 5000, debug=True)
