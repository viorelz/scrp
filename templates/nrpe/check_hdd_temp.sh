#!/bin/bash

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
#STATE_DEPENDENT=4

DEFAULT_WARN_TEMP=55
DEFAULT_CRIT_TEMP=75

# get temperature fo SCSI devices
get_scsi_temp() {
    DEVICE=$1
    CURR_TEMP=$(smartctl -x "$DEVICE" | grep "Current Temperature:" | awk '{print $3}')
}

# get temperature for SSD devices
get_ssd_temp() {
    DEVICE=$1
    CURR_TEMP=$(smartctl -x "$DEVICE" | grep "Temperature:" | awk '{print $2}')
}

WARN_TEMP=$DEFAULT_WARN_TEMP
CRIT_TEMP=$DEFAULT_CRIT_TEMP

# get command options
while getopts w:c: option; do
    case "${option}" in
        w)
            WARN_TEMP=${OPTARG}
        ;;
        c)
            CRIT_TEMP=${OPTARG}
        ;;
        *)
            WARN_TEMP=$DEFAULT_WARN_TEMP
            CRIT_TEMP=$DEFAULT_CRIT_TEMP
        ;;
    esac
done

# get a list of devices
DEVICES=$(smartctl --scan | cut -d' ' -f1)

STATE=$STATE_OK
OUTPUT_TEXT=""
DEVICE_TYPE="scsi"

for DEVICE in $DEVICES; do
    l=$(echo "$DEVICE" | grep /sd)
    res=$?
    if [[ $res -eq 0 ]]; then
        # scsi device
        DEVICE_TYPE="scsi"
    fi
    l=$(echo "$DEVICE" | grep /nvme)
    res=$?
    if [[ $res -eq 0 ]]; then
        # ssd device
        DEVICE_TYPE="ssd"
    fi
    case "$DEVICE_TYPE" in
        scsi)
            get_scsi_temp "$DEVICE"
        ;;
        ssd)
            get_ssd_temp "$DEVICE"
        ;;
        *)
            STATE=$STATE_UNKNOWN
            OUTPUT_TEXT="Unknown device"
            break
        ;;
    esac
    # check the thresholds
    if [[ $CURR_TEMP -ge $CRIT_TEMP ]]; then
        # temperature is critical
        STATE=$STATE_CRITICAL
        OUTPUT_TEXT="$OUTPUT_TEXT $DEVICE : $CURR_TEMP"
    elif [[ $CURR_TEMP -ge $WARN_TEMP ]]; then
        # temperature is WARN
        if [[ $STATE -lt $STATE_CRITICAL ]]; then
            STATE=$STATE_WARNING
        fi
        OUTPUT_TEXT="$OUTPUT_TEXT $DEVICE : $CURR_TEMP"
    else
        # temperature is normal
#        STATE=$STATE_OK
        OUTPUT_TEXT="$OUTPUT_TEXT $DEVICE : $CURR_TEMP"
    fi
done

case $STATE in
    "$STATE_OK") STATE_TEXT="Ok" ;;
    "$STATE_WARNING") STATE_TEXT="WARNING" ;;
    "$STATE_CRITICAL") STATE_TEXT="CRITICAL" ;;
    "$STATE_UNKNOWN") STATE_TEXT="UNKNOWN" ;;
esac

OUTPUT_TEXT=$(echo "$OUTPUT_TEXT" | sed -e 's/, //')
echo "HDD TEMPERATURE: $STATE_TEXT - $OUTPUT_TEXT"
exit $STATE
