# python
from flask import Flask, jsonify, render_template
from config import SERVERS
from debug_finder import DebugPortFinderService

app = Flask(__name__)

debug_service = DebugPortFinderService(SERVERS)

@app.route("/debug", methods=["GET"])
def get_debug_ports():
    result = debug_service.find_debug_port_users()
    return jsonify(result)

@app.route("/debug/html", methods=["GET"])
def get_debug_ports_html():
    result = debug_service.find_debug_port_users()
    return render_template("debug_ports.html", result=result)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)