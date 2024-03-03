#!/bin/bash

################################################
# Author: Thomas Dang
# Website: www.thomasdang.ca
# Description: Auto-get malicious IPs for
#              Check Point SecureXL blocking
################################################

# Blocklist Feeds
URL[0]="https://opendbl.net/lists/etknown.list"
URL[1]="https://opendbl.net/lists/tor-exit.list"
URL[2]="https://opendbl.net/lists/bruteforce.list"
URL[3]="https://opendbl.net/lists/blocklistde-all.list"
URL[4]="https://opendbl.net/lists/talos.list"
URL[5]="https://opendbl.net/lists/dshield.list"
URL[6]="https://opendbl.net/lists/sslblock.list"

# Regular expression variables
INPUT_PATTERN='^(([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\/([89]|[12][0-9]|3[0-2]))?)$'

# Context variables
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
FEED_DIR="${SCRIPT_DIR}/feeds"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG="${LOG_DIR}/blocklist.log"
HOSTNAME=$(hostname)

# Creating directories
[ -d $FEED_DIR ] || mkdir -p $FEED_DIR
[ -d $LOG_DIR ] || mkdir -p $LOG_DIR

# Init log file
>> $LOG

# Fetching the feeds
for i in "${URL[@]}"; do
        echo "[$(date +'%d-%m-%Y %H:%M:%S')] ${HOSTNAME} - Fetching the following feed: ${i}" | tee -a $LOG
    filename=$(basename $i) # Extract filename from URL
        curl --insecure --retry 10 --retry-delay 60 $i | grep -Po $INPUT_PATTERN >> ${FEED_DIR}/${filename}

        # De-duplicate the IoCs in the feed (per-feed)
        echo "[$(date +'%d-%m-%Y %H:%M:%S')] ${HOSTNAME} - De-duplicating the following feed: ${i}" | tee -a $LOG
        sort -u ${FEED_DIR}/${filename} -o ${FEED_DIR}/${filename}