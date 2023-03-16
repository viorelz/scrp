#!/bin/bash

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
#STATE_DEPENDENT=4

HWMON_DIR="/sys/class/hwmon"
CORETEMP_DIR=""

PARAM_WARN_TEMP=0
PARAM_CRIT_TEMP=0
USE_PARAM_TEMPS=0

# get command options
while getopts w:c: option; do
    case "${option}" in
        w)
            PARAM_WARN_TEMP=${OPTARG}
            USE_PARAM_TEMPS=1
        ;;
        c)
            PARAM_CRIT_TEMP=${OPTARG}
            USE_PARAM_TEMPS=1
        ;;
        *)
            USE_PARAM_TEMPS=0
        ;;
    esac
done

LIST=$(find $HWMON_DIR -type l)

for ITEM in $LIST; do
    l=$(grep coretemp "$ITEM"/name)
    res=$?
    if [ $res -eq 0 ]; then
        CORETEMP_DIR=$ITEM
        break
    fi
done

STATE=$STATE_OK
OUTPUT_TEXT=""

LABELS=$(ls "$CORETEMP_DIR"/temp*_label)
for LABEL in $LABELS; do
    NAME=$(cat "$LABEL")
    # get the curernt temperature
    TEMP_FILE=$(basename "$LABEL")
    TEMP=$(echo "$TEMP_FILE" | cut -d '_' -f1)
    T=$(cat "$CORETEMP_DIR/${TEMP}"_input)
    CURR_TEMP=${T::-3}
    # get the high temperature
    if [[ $USE_PARAM_TEMPS -eq 1 ]]; then
        WARN_TEMP=$PARAM_WARN_TEMP
    else
        T=$(cat "$CORETEMP_DIR/${TEMP}"_max)
        WARN_TEMP=${T::-3}
    fi
    # get the critical temperature
    if [[ $USE_PARAM_TEMPS -eq 1 ]]; then
        CRIT_TEMP=$PARAM_CRIT_TEMP
    else
        T=$(cat "$CORETEMP_DIR/${TEMP}"_crit)
        CRIT_TEMP=${T::-3}
    fi
    # check the thresholds
    if [[ $CURR_TEMP -ge $CRIT_TEMP ]]; then
        # temperature is critical
        STATE=$STATE_CRITICAL
        OUTPUT_TEXT="$OUTPUT_TEXT $NAME : $CURR_TEMP"
    elif [[ $CURR_TEMP -ge $WARN_TEMP ]]; then
        # temperature is high
        if [[ $STATE -lt $STATE_CRITICAL ]]; then
            STATE=$STATE_WARNING
        fi
        OUTPUT_TEXT="$OUTPUT_TEXT $NAME : $CURR_TEMP"
    else
        # temperature is normal
#        STATE=$STATE_OK
        OUTPUT_TEXT="$OUTPUT_TEXT $NAME : $CURR_TEMP"
    fi
done

case $STATE in
    "$STATE_OK") STATE_TEXT="Ok" ;;
    "$STATE_WARNING") STATE_TEXT="WARNING" ;;
    "$STATE_CRITICAL") STATE_TEXT="CRITICAL" ;;
    "$STATE_UNKNOWN") STATE_TEXT="UNKNOWN" ;;
esac

OUTPUT_TEXT=$(echo "$OUTPUT_TEXT" | sed -e 's/, //')
echo "CPU TEMPERATURE: $STATE_TEXT - $OUTPUT_TEXT"
exit $STATE
