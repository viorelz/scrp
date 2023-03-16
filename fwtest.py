#!/usr/bin/python3

import sys
import json
import glob
import os
import collections
import csv
import sys

cfg_file_name = "frameworks.json"
web_dir = "/var/www"
exceptions = ['cgi-bin', 'html', 'log']
hostname = os.getenv('HOSTNAME')

# get the path of the script
p = sys.argv[0]
# load the frameworks config file
wp = os.path.dirname(p)
cfg_file = os.path.join(wp, cfg_file_name)
with open(cfg_file, 'r') as f:
    cfg = json.load(f)

# get a list of folders in the web folder
web_folders = []
wd = os.path.join(web_dir, '*')
for f in sorted(glob.glob(wd)):
    if os.path.basename(f) in exceptions:
        continue
    if os.path.isdir(f):
        web_folders.append(f)

# browse through every folder
keys = list(cfg.keys())
frameworks = collections.OrderedDict()
for web_folder in web_folders:
    fws = []
    wf = os.path.join(web_folder, '**')
#    print(wf)
    # go through all items in folder
    for thing in sorted(glob.glob(wf, recursive=True)):
        # skip symlinks
        if os.path.islink(thing):
            continue
        name = os.path.basename(thing)
        if (name in keys) and (cfg[name] not in fws):
            fws.append(cfg[name])
    if not fws:
        fws.append('Unknown')
    frameworks[web_folder] = fws
#print('\n', 30 * '-')

out_file_name = hostname + "_" + "frameworks.csv"
out_file = os.path.join(wp, out_file_name)
with open(out_file, mode='w', newline='') as csv_file:
    field_names = ['Host', 'Folder', 'Frameworks']
    writer = csv.writer(csv_file, delimiter=',')
    writer.writerow(field_names)
    for k in frameworks:
        f = ','.join(frameworks[k])
        print(f"{k}  -   {f}")
        l = []
        l.append(hostname)
        l.append(k)
        l.append(f)
        writer.writerow(l)
