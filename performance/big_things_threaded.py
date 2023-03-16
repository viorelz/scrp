
import subprocess
import os
import sys
import Queue
import threading
import smtplib
import pickle
from email.mime.text import MIMEText

# reference values
max_database_size = 500.0     # db size in MB
max_folder_size = 1024.0      # dir size in MB
min_change = 100.0

mail_to = ['maintenance@domain.tld']

# get the script directory
script_dir = os.path.dirname(sys.argv[0])

db_size_query = """
SELECT table_schema AS "Database", ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS "Size (MB)"
FROM information_schema.TABLES
  WHERE table_schema='DBNAME'
"""
sites_folder = "/var/www"
home_folder = "/home"
ispcfg_hosts = ['host8', 'host12', 'host13', 'host14', 'host15']
is_ispcfg = False
big_databases_file_name = "big_databases.pkl"
big_folders_file_name = "big_folders.pkl"

databases_to_ignore = ['Database', 'information_schema', 'mysql', 'performance_schema']
folders_to_ignore = ['html', 'cgi-bin', 'log']

# work queues
input_databases_queue = Queue.Queue()
output_databases_queue = Queue.Queue()
input_folders_queue = Queue.Queue()
output_folders_queue = Queue.Queue()

max_threads = 5

# dictionaries for results
databases = {}
folders = {}

class ThreadBigDatabases(threading.Thread):
    def __init__(self, in_queue, out_queue):
        threading.Thread.__init__(self)
        self.in_queue = in_queue
        self.out_queue = out_queue

    def run(self):
        while True:
            db_name = self.in_queue.get()
            db_size = get_database_size(db_name)
            if db_size > max_database_size:
                self.out_queue.put((db_name, db_size))
            self.in_queue.task_done()

class ThreadBigFolders(threading.Thread):
    def __init__(self, in_queue, out_queue):
        threading.Thread.__init__(self)
        self.in_queue = in_queue
        self.out_queue = out_queue

    def run(self):
        while True:
            folder_name = self.in_queue.get()
            folder_size = get_folder_size(folder_name)
            if folder_size > max_folder_size:
                self.out_queue.put((folder_name, folder_size))
            self.in_queue.task_done()

class ThreadGetResults(threading.Thread):
    def __init__(self, queue, results):
        threading.Thread.__init__(self)
        self.queue = queue
        self.results = results

    def run(self):
        while True:
            res = self.queue.get()
            x_name = res[0]
            x_size = res[1]
            self.results[x_name] = x_size
            self.queue.task_done()


# routine to get list of databases
def get_databases_list():
    p = subprocess.Popen(['mysql', '-e', 'show databases'], stdout=subprocess.PIPE)
    res = p.communicate()
    l = res[0][:-1].split('\n')[1:]
    dbs = []
    for d in l:
        if d not in databases_to_ignore:
            dbs.append(d)
    return dbs

# routine to get list of folders
def get_folders_list(path):
    res = os.listdir(path)
    dirs = []
    for d in res:
        fldr = os .path.join(path, d)
        if is_ispcfg:
            if os.path.islink(fldr):
                dirs.append(os.path.join(fldr, 'web'))
        else:
            if d not in folders_to_ignore:
                if os.path.isdir(fldr):
                    dirs.append(fldr)
    return dirs

# routine to get size of database
def get_database_size(db_name):
    query = db_size_query.replace('DBNAME', db_name)
    p = subprocess.Popen(['mysql', '-e', query], stdout=subprocess.PIPE)
    res = p.communicate()
    l = res[0].split('\n')
    a = l[1].split('\t')
    db_size = a[1]
    if db_size == 'NULL':
        db_size = '0.0'
    return float(db_size)

# routine to get the size of a folder
def get_folder_size(folder_name):
    p = subprocess.Popen(['du', '-s', folder_name], stdout=subprocess.PIPE)
    res = p.communicate()
    dir_size = float(res[0].split('\t')[0]) / 1024
    return dir_size


def main():
    global is_ispcfg
    # get the hostname
    p = subprocess.Popen(['hostname'], stdout=subprocess.PIPE)
    h = p.communicate()
    host = h[0].split('.')[0]
    if host in ispcfg_hosts:
        # this is an ISPConfig host
        is_ispcfg = True
    else:
        is_ispcfg = False

    # get the big databases
    dbs = get_databases_list()
    for db in dbs:
        input_databases_queue.put(db)
    # spawn a pool of threads and pass them queue instances
    for i in range(max_threads):
        t = ThreadBigDatabases(input_databases_queue, output_databases_queue)
        t.setDaemon(True)
        t.start()
    # get the results
    for i in range(max_threads):
        gr = ThreadGetResults(output_databases_queue, databases)
        gr.setDaemon(True)
        gr.start()
    input_databases_queue.join()
    output_databases_queue.join()

    # get the big folders
    dirs = get_folders_list(sites_folder)
    for dir in dirs:
        input_folders_queue.put(dir)
    # spawn a pool of threads and pass them queue instances
    for i in range(max_threads):
        t = ThreadBigFolders(input_folders_queue, output_folders_queue)
        t.setDaemon(True)
        t.start()
    # get the results
    for i in range(max_threads):
        gr = ThreadGetResults(output_folders_queue, folders)
        gr.setDaemon(True)
        gr.start()
    input_folders_queue.join()
    output_folders_queue.join()

    dirs = get_folders_list(home_folder)
    for dir in dirs:
        input_folders_queue.put(dir)
    # spawn a pool of threads and pass them queue instances
    for i in range(max_threads):
        t = ThreadBigFolders(input_folders_queue, output_folders_queue)
        t.setDaemon(True)
        t.start()
    # get the results
    for i in range(max_threads):
        gr = ThreadGetResults(output_folders_queue, folders)
        gr.setDaemon(True)
        gr.start()
    input_folders_queue.join()
    output_folders_queue.join()

    # create the pickle files if they do not exist
    big_databases_file = os.path.join(script_dir, big_databases_file_name)
    big_folders_file = os.path.join(script_dir, big_folders_file_name)
    if not os.path.isfile(big_databases_file):
        with open(big_databases_file, 'wb') as f:
            pickle.dump(databases, f, pickle.HIGHEST_PROTOCOL)
    if not os.path.isfile(big_folders_file):
        with open(big_folders_file, 'wb') as f:
            pickle.dump(folders, f, pickle.HIGHEST_PROTOCOL)

    # read the sizes from the previous run
    big_databases_file = os.path.join(script_dir, big_databases_file_name)
    big_folders_file = os.path.join(script_dir, big_folders_file_name)
    with open(big_databases_file, 'rb') as f:
        old_databases = pickle.load(f)
    with open(big_folders_file, 'rb') as f:
        old_folders = pickle.load(f)
    # write the new sizes
    with open(big_databases_file, 'wb') as f:
        pickle.dump(databases, f, pickle.HIGHEST_PROTOCOL)
    with open(big_folders_file, 'wb') as f:
        pickle.dump(folders, f, pickle.HIGHEST_PROTOCOL)

    # send the email
    sorted_dbs = sorted(databases, key=databases.get, reverse=True)
    sorted_dirs = sorted(folders, key=folders.get, reverse=True)
    msg = "Databases bigger than " + '%.2f' % max_database_size + " MB:\n"
    for d in sorted_dbs:
        msg += "%20s" % d + ": " + '%10.2f' % databases[d] + " MB"
        if d in old_databases:
            dif = databases[d] - old_databases[d]
            if dif > 0:
                msg += ",   up %6.2f" %abs(dif) + " MB"
            elif dif < 0:
                msg += ", down %6.2f" %abs(dif) + " MB"
        msg += "\n"
    msg += "\nFolders bigger than " + '%.2f' % max_folder_size + " MB:\n"
    for d in sorted_dirs:
        msg += "%50s" % d + ": " + '%10.2f' % folders[d] + " MB"
        if d in old_folders:
            dif = folders[d] - old_folders[d]
            if dif > min_change:
                msg += ",   up %6.2f" %abs(dif) + " MB"
            elif dif < -min_change:
                msg += ", down %6.2f" %abs(dif) + " MB"
        msg += "\n"

    mail_from = "root@" + h[0]
    msg = MIMEText(msg)
    msg['Subject'] = "Big things on " + h[0]

    s = smtplib.SMTP('localhost')
    s.sendmail(mail_from, mail_to, msg.as_string())
    s.quit()

if __name__ == '__main__':
    main()
