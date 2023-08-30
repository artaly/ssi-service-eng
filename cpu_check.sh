#!/bin/bash

CRITICAL=""
WARNING=""
EMAIL=""
CURRENT_DATE=$(date "+%Y%m%d %H:%M")

while getopts ":c:w:e:" opt; do
	case "$opt" in
		c) CRITICAL="$OPTARG" ;;
		w) WARNING="$OPTARG" ;;
		e) EMAIL="$OPTARG" ;;
		\?) echo "Invalid option: -$OPTARG" >&2; exit 1;;
		:) echo "Option -$OPTARG requires an argument." >&2; exit 1;;
	esac
done

missing_params=""

check_missing_param() {
	if [[ -z ${!1} ]]; then
		missing_params+=" $1"
	fi
}

check_missing_param "CRITICAL"
check_missing_param "WARNING"
check_missing_param "EMAIL"

if [[ -n $missing_params ]]; then
	echo "Required parameter(s) missing: $missing_params"
	exit 1
fi

if [[ $CRITICAL -le $WARNING ]]; then
	echo "Critical threshold must be greater than the warning threshold"
	exit
fi

CPU_USAGE=$(top -bn1 | grep '%Cpu' | \sed "s/.*,*\([0-9.]*\)%* id.*/\1/" | \awk '{print 100 - $1}')

if [[ $CPU_USAGE -ge $CRITICAL ]]; then
	echo "Used CPU is greater than or equal to critical threshold!"
	echo "CPU Usage: $CPU_USAGE"
	
	TOP_PROCESSES=$(ps aux --sort=-%mem | head -n 11 | tail -n +2)
	echo "$TOP_PROCCESSES" | mail -v -s "$EMAIL_SUBJECT" $EMAIL

	exit
elif [[ $CPU_USAGE -ge $WARNING && $CPU_USAGE -le $CRITICAL ]]; then
	echo "Used CPU is greater than or equal to warning threshold but less than critical threshold!"
	echo "Used CPU: $CPU_USAGE"
	exit 1
else
	echo "Used CPU is less then warning threshold"
	echo "USED CPU: $CPU_USAGE"
	exit 0
fi

echo "$CRITICAL"
echo "$WARNING"
echo "$EMAIL"
