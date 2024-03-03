'''
Azure Check Point Block IP Script

This script is used to block an IP address on a Check Point gateway. It is designed to be run as a hybrid runbook on an automation server.

Inputs: 
    - IP address to block
    - Directory containing the blocklist feed files
    - Directory containing the blocklist database files
    - Name of the blocklist to update
    - User account to own the blocklist files
    - Optional: List of gateways to update the blocklist on
    - Optional: User account to use for SSH to the gateways
'''

import sys
import os
import pwd
import grp
import pickle
import datetime

ip = sys.argv[1]
feed_dir = sys.argv[2]
db_dir = sys.argv[3]
blockfile = sys.argv[4]
user_account = sys.argv[5]
# Optional argument for fwaccel dos deny
if len(sys.argv) > 6:
    gateways = sys.argv[6].split(",")
    gw_user = sys.argv[7]
else:
    gateways = None

feed_file = os.path.join(feed_dir, f"{blockfile}.list")
db_file = os.path.join(db_dir, f"{blockfile}.pickle")
print(f"Feed file: {feed_file}")
print(f"DB file: {db_file}")

# Get the current blocklist
try:
    print(f"Loading blocklist from {db_file}")
    with open(db_file, 'rb') as f:
        blocklist = pickle.load(f)
except FileNotFoundError:
    print(f"Blocklist {db_file} not found, creating new blocklist")
    # If the blocklist doesn't exist, create a new one
    blocklist = {}

# Add the IP to the blocklist
print(f"Adding {ip} to blocklist")
blocklist[ip] = datetime.datetime.now()

# Save the blocklist
print(f"Saving blocklist to {db_file}")
with open(db_file, 'wb') as f:
    pickle.dump(blocklist, f)

# Save the blocklist as a text file
print(f"Saving blocklist to {feed_file}")
with open(feed_file, 'w') as f:
    for ip in blocklist:
        # Only keep IPs that have been blocked in the last 7 days
        if blocklist[ip] > datetime.datetime.now() - datetime.timedelta(days=7):
            f.write(f"{ip}\n")

# Change the owner of the blocklist files to the user account
print(f"Changing owner of {feed_file} to {user_account}")
uid = pwd.getpwnam(user_account).pw_uid
gid = grp.getgrnam(user_account).gr_gid
os.chown(feed_file, uid, gid)

# Update the blocklist on the gateways if specified
for gateway in gateways:
    from fabric import Connection
    print(f"Updating blocklist on {gateway}")
    with Connection(gateway, user=gw_user, connect_kwargs={"key_filename": f"/home/{user_account}/.ssh/id_rsa"}) as conn:
        result = conn.run(f"fwaccel dos deny -a {ip}", pty=True)
        print(result)