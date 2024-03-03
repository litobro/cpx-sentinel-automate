#!/bin/bash

################################################
# Author: Thomas Dang
# Website: www.thomasdang.ca
# Description: Auto-block malicious IPs using
#              Check Point SecureXL from server
################################################

# Import Check Point Environment
source /opt/CPshrd-R81.20/tmp/.CPprofile.sh

REMOTE_HOST="[Insert your hybrid runbook automation worker here]"
REMOTE_USER="[Whatever user you configured on the remote]"
REMOTE_FEED_DIR="[Path to the directory where the blocklist files are stored on the remote]"
LOCAL_FEED_DIR="${FWDIR}/conf/deny_lists" # This is the default directory where the blocklist files are stored on the local
IDENTITY_FILE="/home/svc-blocklist/.ssh/id_rsa" # This is the default identity file for the user that will be used to authenticate to the remote
COMMAND_FILE="commands.txt" # This is the default command file that will be used to store the sftp commands
LOG_FILE="[Wherever you want to log output to]" # This is the default log file that will be used to store the output of the script

# Create the command file
echo "$(date) - Creating the command file..." | tee -a ${LOG_FILE}
echo "cd ${REMOTE_FEED_DIR}" > ${COMMAND_FILE}
echo "lcd ${LOCAL_FEED_DIR}" >> ${COMMAND_FILE}
echo "get -r *" >> ${COMMAND_FILE}

# Get the latest blocklist files
echo "$(date) - Getting the latest blocklist files from ${REMOTE_HOST} to ${LOCAL_FEED_DIR}..." | tee -a ${LOG_FILE}
sftp -i $IDENTITY_FILE -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -b ${COMMAND_FILE} ${REMOTE_USER}@${REMOTE_HOST} | tee -a ${LOG_FILE}

# Remove the command file
echo "$(date) - Removing the command file..." | tee -a ${LOG_FILE}
rm ${COMMAND_FILE} | tee -a ${LOG_FILE}

# Load all the blocklist files
echo "$(date) - Loading all blocklist files in ${LOCAL_FEED_DIR} and flushing old IPs..." | tee -a ${LOG_FILE}
fwaccel dos deny -F -L | tee -a ${LOG_FILE}