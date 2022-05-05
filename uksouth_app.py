from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def hello_world():
    return jsonify({"response": "OK", "code": 200})

if __name__ == "__main__":
    app.run(port = 5000, debug=True)
