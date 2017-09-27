# endian-gpo - Linking Endians transparent proxy with Active Directory Group Policies
# Copyright (c) 2017 Dorian Stoll
# Licensed under the Terms of the MIT License

from flask import Flask
from flask import request

import threading
import schedule
import subprocess

app = Flask(__name__)
lock = threading.Lock()

# Constants
settingsFile = "/var/efw/proxy/settings"

def reload_proxy():
    subprocess.call("/usr/local/bin/restartsquid", shell=True)
    
def load_whitelist():
    data = []
    with open(settingsFile) as settings:
        for line in settings:
            if line.startswith("BYPASS_SOURCE="):
                data = line.replace("BYPASS_SOURCE=", "").replace("\n", "").split(",")
    return data

def save_whitelist(whitelist):
    with open(settingsFile, "r+") as settings:
        data = settings.read()        
        for line in data.split("\n"):
            if line.startswith("BYPASS_SOURCE="):
                print line
                data = data.replace(line, "BYPASS_SOURCE=" + ",".join(whitelist))
        settings.seek(0)
        settings.write(data)
    

@app.route("/register", methods=["POST"])
def register():
    """
    Registers a new MAC Address for bypassing the transparent proxy
    """
    with lock: # Force synchronous execution
        whitelist = load_whitelist()
        mac = request.form.get("mac")
        if mac in whitelist:
            return "MAC Address already registered for transparent proxy bypass", 200
        else:
            whitelist.append(mac)
            save_whitelist(whitelist)
            reload_proxy()
            return "MAC Address was successfully registered for transparent proxy bypass", 200
            
@app.route("/unregister", methods=["POST"])
def unregister():
    """
    Unregisters a new MAC Address for bypassing the transparent proxy
    """
    with lock: # Force synchronous execution
        whitelist = load_whitelist()
        mac = request.form.get("mac")
        if mac in whitelist:
            whitelist.remove(mac)
            save_whitelist(whitelist)
            reload_proxy()
            return "MAC Address was removed from the whitelist", 200
        else:
            return "MAC Address not registered for transparent proxy bypass", 200
    
if __name__ == "__main__":
    app.run(host='0.0.0.0', port=7777) 