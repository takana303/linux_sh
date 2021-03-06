#!/bin/sh

LOGFILE="/var/log/daylog.log"
ONEFILE="/var/log/daylog.one"
DATE=`date +\%Y\%m\%d`
ECHO="${DATE}"

# リセット日
#crontab
#50 23 28-31 * * /usr/bin/test $(date -d '+1 day' +%d) -eq 02 && reboot
#なんかうまく動かない。。。
#00 00 01 * * sudo reboot
RESETDATE=1
if [ $(( `date +\%-d` )) -eq $(( RESETDATE )) ]; then
	echo "${DATE}: reset 0 Days: TOTAL 0.0" > $ONEFILE
fi

# uptime取得
if [ `uptime | tr -s [:space:] | sed -e 's/,//g' | cut -d " " -f 5` = "days" ]; then
	UPTIME_DAY=$(( `uptime | tr -s [:space:] | sed -e 's/,//g' | cut -d " " -f 4` ))
else
	UPTIME_DAY=0
fi
ECHO="${ECHO}: UPTIME ${UPTIME_DAY} Days"
echo $ECHO

# RX+TXをGBへ
RX=`cat /proc/net/dev | grep eth0 | tr -s [:space:] | cut -d " " -f 3`
TX=`cat /proc/net/dev | grep eth0 | tr -s [:space:] | cut -d " " -f 11`
RXATX=$(( RX + TX ))
GB=1073741824

COUNT=0
TOTAL_QUOTIENT=0
TOTAL_DECIMAL=0
REMAINDER=0

TOTAL_QUOTIENT=$(( RXATX / GB ))
REMAINDER=$(( RXATX % GB * 10 ))
while [ $REMAINDER -ne 0 -a $COUNT -lt 2 ]
do
	TOTAL_DECIMAL=$(( TOTAL_DECIMAL * 10 + REMAINDER / GB ))
	REMAINDER=$(( REMAINDER % GB * 10 ))
	COUNT=$(( COUNT + 1 ))
done

# TOTALTRAFFICを取得
# 再起動起きてたら前日のTRAFFICを足す
YESTERDAY_UPTIME=$(( `tail -n 1 /var/log/daylog.one | cut -d " " -f 3` ))
YESTERDAY_QUOTIENT=$(( `tail -n 1 /var/log/daylog.one | cut -d " " -f 6 | cut -d "." -f 1` ))
YESTERDAY_DECIMAL=$(( `tail -n 1 /var/log/daylog.one | cut -d " " -f 6 | cut -d "." -f 2` ))
if [ $((YESTERDAY_UPTIME)) -ge $((UPTIME_DAY)) ]; then
	TOTAL_tmp=$(( TOTAL_QUOTIENT * 100 + TOTAL_DECIMAL ))
	YESTERDAY_tmp=$(( YESTERDAY_QUOTIENT * 100 + YESTERDAY_DECIMAL ))
	TOTAL_tmp=$(( TOTAL_tmp + YESTERDAY_tmp ))
	TOTAL_QUOTIENT=$(( TOTAL_tmp / 100 ))
	TOTAL_DECIMAL=$(( TOTAL_tmp % 100 ))
	if [ $TOTAL_DECIMAL -lt 10 ]; then
		TOTAL_DECIMAL=0$TOTAL_DECIMAL
	fi
fi
ECHO="${ECHO}: TOTAL ${TOTAL_QUOTIENT}.${TOTAL_DECIMAL} GB"

# 前日のTOTALTRAFFICからTRAFFIC/dayを取得
COUNT=0
TODAY_TMP=$(( ( TOTAL_QUOTIENT * 100 + TOTAL_DECIMAL ) - ( YESTERDAY_QUOTIENT * 100 + YESTERDAY_DECIMAL ) ))
TODAY_QUOTIENT=$(( TODAY_TMP / 100 ))
TODAY_DECIMAL=$(( TODAY_TMP % 100 ))
if [ $TODAY_DECIMAL -lt 10 ]; then
	TODAY_DECIMAL=0$TODAY_DECIMAL
fi
ECHO="${ECHO}: TODAY ${TODAY_QUOTIENT}.${TODAY_DECIMAL} GB"

echo $ECHO >> $LOGFILE
echo $ECHO > $ONEFILE
