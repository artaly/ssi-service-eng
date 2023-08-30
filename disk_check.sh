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
		missing_params+="$1"
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

DISK_USAGE=$(df -P | awk -v c="$CRITICAL" -v w="$WARNING" 'NR > 1 && (0+$5 >= c || 0+$5 >= w) {print $1, $5}')

echo "$DISK_USAGE" | while IFS= read -r line; do
	partition=$(echo "$line" | awk '{print $1}')
	usage=$(echo "$line" | awk '{print $2}' | tr -d '%')
	if [[ $usage -ge $CRITICAL ]]; then
		EMAIL_SUBJECT="$CURRENT_DATE disk_check - critical"
		echo "Used disk is greater than critical!"
		CONTENT=$(echo "$usage" "$partition")
		echo "$CONTENT" | mail -v -s "$EMAIL_SUBJECT" $EMAIL
		exit 2
	fi

	if [[ $usage -ge $WARNING && $usage -le $CRITICAL ]]; then
		echo "$partition: used disk is greater than or equal to warning threshold but less than critical! Usage: $usage%"
		exit 1 
	fi
	
	if [[ $usage -le $WARNING ]]; then
		echo "$partition: Used disk is less than warning threshold. Usage: $usage%".
		exit 0
	fi
done
