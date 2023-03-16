#!/usr/bin/python3

import subprocess
import sys

# get a list of devices
p = subprocess.Popen(["smartctl", "--scan"], shell=False, stdout=subprocess.PIPE)
outs, errs = p.communicate()
retcode = p.returncode
if retcode != 0:
    print("Could not get device list!")
    sys.exit(1)
b = str(outs, 'utf-8').split('\n')
b = b[:-1]
devices = []
for c in b:
    d = c.split(' ')[0]
    devices.append(d)

returnCode = 0
returnMessage = ""
response = {}

# check each device's health
for device in devices:
    p = subprocess.Popen(["smartctl", "-H", device], shell=False, stdout=subprocess.PIPE)
    outs, errs = p.communicate()
    b = str(outs, 'utf-8').split('\n')
    retcode = p.returncode
    if retcode == 0:
        retMessage = device + ": Ok"
        retCode = 0
        response[device] = [retCode, retMessage]
    else:
        if b[4].endswith("PASSED"):
            retMessage = device + ": Ok"
            retCode = 0
            response[device] = [retCode, retMessage]
        elif b[3].endswith("Permission denied"):
             retMessage = device + ": Permission denied"
             retCode = retcode
             response[device] = [retCode, retMessage]
        else:
             e = b[5].replace('  ', '')
             errMsg = e.split(' ')[1]
             retMessage = device + " is ill: " + errMsg + ", "
             retCode = retcode
             response[device] = [retCode, retMessage]
for key in response.keys():
    r = response[key]
    if r[0] != 0:
        returnCode = r[0]
    returnMessage += r[1] + ", "
print(returnMessage[:-2])
sys.exit(returnCode)
