#!/bin/sh

export PATH=/sbin:/opt/bin:/opt/usr/bin:/opt/sbin:/opt/usr/sbin:/bin:/usr/bin:/usr/sbin:/opt/usr/local/bin
export LD_LIBRARY_PATH=/opt/lib:/opt/usr/lib:/lib:/usr/lib:/opt/usr/local/lib

if [ $# -lt 1 ]; then
    echo "Usage ${0} minutes"
    exit 0
fi

DATA_PATH=`dirname $0`
MINUTES=$1
LOG_FILE=/var/log/messages
#workaround on busybox
SECONDS=$((`date +%s`-${MINUTES}*60))
DATE_THRESHOLD=`date -D "%s" -d ${SECONDS} +%H:%M:%S`
NOW_DATE=`date +%H:%M:%S`

if [ ${DATE_THRESHOLD} \> ${NOW_DATE} ]; then
    DATE_THRESHOLD="00:00:00"
fi

FAIL_NUM1=`grep "Bad password attempt" ${LOG_FILE} | awk -v date_t="${DATE_THRESHOLD}" '$3 >= date_t' | wc -l`
FAIL_NUM2=`grep "Login attempt for nonexistent" ${LOG_FILE} | awk -v date_t="${DATE_THRESHOLD}" '$3 >= date_t' | wc -l`

SUCC_NUM=`grep "Password auth succeeded" ${LOG_FILE} | awk -v date_t="${DATE_THRESHOLD}" '$3 >= date_t' | wc -l`
PUT_JSON_PATH=${DATA_PATH}/cosm.json

COSM_KEY=`awk '$1=="key" {print $2}' ${DATA_PATH}/cosm.conf`
FEED_ID=`awk '$1=="feed_id" {print $2}' ${DATA_PATH}/cosm.conf`

echo "{
  \"version\":\"1.0.0\",
  \"datastreams\":[
      {\"id\":\"fail\", \"current_value\":\"$((${FAIL_NUM1}+${FAIL_NUM2}))\"},
      {\"id\":\"succ\", \"current_value\":\"${SUCC_NUM}\"}
  ]
}" > ${PUT_JSON_PATH}

curl --request PUT \
     --data-binary @${PUT_JSON_PATH} \
     --header "X-ApiKey: ${COSM_KEY}" \
     --verbose \
     http://api.cosm.com/v2/feeds/${FEED_ID}