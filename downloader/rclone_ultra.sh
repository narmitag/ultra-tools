#!/bin/sh

### CONFIG ###
WEBHOOK_URL=""
REMOTE="ultra-thor:/staging/"
DEST="/data"
LOG_DIR="/logs"
LOCK_FILE="/tmp/rclone_ultra.lock"
BW_LIMIT="08:00,10M 23:00,40M"
LOG_RETENTION_DAYS=30

START_TS=$(date +%s)
HOST=$(hostname)

### FUNCTIONS ###
slack_post() {
  curl -s -X POST -H 'Content-type: application/json' \
    --data "$1" \
    "$WEBHOOK_URL" >/dev/null
}

### LOCKFILE ###
if [ -f "$LOCK_FILE" ]; then
  slack_post "{
    \"blocks\": [
      {\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\":warning: *Ultra.cc rclone skipped*\"}},
      {\"type\":\"context\",\"elements\":[{\"type\":\"mrkdwn\",\"text\":\"Another run is already in progress on *$HOST*\"}]}
    ]
  }"
  exit 1
fi

touch "$LOCK_FILE"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/ultra_$(date +%F_%H-%M).log"

### START MESSAGE ###
slack_post "{
  \"blocks\": [
    {\"type\":\"header\",\"text\":{\"type\":\"plain_text\",\"text\":\"⬇️ Ultra.cc rclone started\"}},
    {\"type\":\"section\",\"fields\": [
      {\"type\":\"mrkdwn\",\"text\":\"*Host:*\\n$HOST\"},
      {\"type\":\"mrkdwn\",\"text\":\"*Destination:*\\n$DEST\"},
      {\"type\":\"mrkdwn\",\"text\":\"*Bandwidth:*\\n$BW_LIMIT\"}
    ]}
  ]
}"

### RUN RCLONE ###
rclone copy "$REMOTE" "$DEST" \
  --config /config/rclone.conf \
  --transfers 4 \
  --checkers 4 \
  --buffer-size 32M \
  --bwlimit "$BW_LIMIT" \
  --log-file "$LOG_FILE" \
  --log-level INFO

RC=$?
END_TS=$(date +%s)
DURATION=$((END_TS - START_TS))

### EXTRACT STATS ###
SUMMARY_LINE=$(grep -E "Transferred:" "$LOG_FILE" | tail -1)

FILES=$(echo "$SUMMARY_LINE" | awk -F',' '{print $1}' | sed 's/Transferred://')
SIZE=$(echo "$SUMMARY_LINE" | awk -F',' '{print $2}')
SPEED=$(echo "$SUMMARY_LINE" | awk -F',' '{print $4}')

DURATION_FMT=$(printf '%02dh %02dm %02ds\n' $((DURATION/3600)) $((DURATION%3600/60)) $((DURATION%60)))

### STATUS ###
if [ $RC -eq 0 ]; then
  STATUS=":white_check_mark: *Completed successfully*"
else
  STATUS=":x: *FAILED* (exit code $RC)"
fi

### FINAL MESSAGE ###
slack_post "{
  \"blocks\": [
    {\"type\":\"header\",\"text\":{\"type\":\"plain_text\",\"text\":\"Ultra.cc rclone finished\"}},
    {\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"$STATUS\"}},
    {\"type\":\"divider\"},
    {\"type\":\"section\",\"fields\": [
      {\"type\":\"mrkdwn\",\"text\":\"*Files:*\\n$FILES\"},
      {\"type\":\"mrkdwn\",\"text\":\"*Data:*\\n$SIZE\"},
      {\"type\":\"mrkdwn\",\"text\":\"*Avg speed:*\\n$SPEED\"},
      {\"type\":\"mrkdwn\",\"text\":\"*Duration:*\\n$DURATION_FMT\"},
      {\"type\":\"mrkdwn\",\"text\":\"*Host:*\\n$HOST\"}
    ]}
  ]
}"

### CLEANUP ###
find "$LOG_DIR" -type f -name "*.log" -mtime +$LOG_RETENTION_DAYS -delete
rm -f "$LOCK_FILE"

exit $RC
