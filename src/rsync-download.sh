#!/bin/bash
set -e

# Check if rsync is installed
if ! command -v rsync &> /dev/null; then
  echo "Error: rsync is not installed. Please install rsync or use scp instead."
  exit 1
fi

# Parse and execute rsync downloads
echo "Starting rsync download operations"

# Initialize a counter for reporting
COUNT=0
TOTAL=$(echo "$RSYNC_DOWNLOAD_CONFIG" | grep -c "=>")

IFS=$'\n'
for LINE in $(echo "$RSYNC_DOWNLOAD_CONFIG" | grep "=>"); do
  # Extract source and destination paths
  REMOTE_PATH=$(echo "$LINE" | sed -E 's/^(.+) =>.+$/\1/' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed "s/'//g")
  LOCAL_PATH=$(echo "$LINE" | sed -E 's/^.+=> (.+)$/\1/' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed "s/'//g")

  # Increment counter
  COUNT=$((COUNT+1))

  echo "[$COUNT/$TOTAL] Downloading via rsync: $REMOTE_PATH => $LOCAL_PATH"

  # Create destination directory if it doesn't exist
  mkdir -p "$(dirname "$LOCAL_PATH")"

  # Execute rsync command with proper handling of options
  if [ -n "$SSH_PASS" ]; then
    # Check if sshpass is installed
    if ! command -v sshpass &> /dev/null; then
      echo "Error: sshpass is not installed. Cannot use password authentication with rsync."
      exit 1
    fi
    export SSHPASS="$SSH_PASS"
    sshpass -e rsync -a -v -z --delete -e "ssh -p $SSH_PORT $SSH_OPTIONS" "$SSH_USER@$SSH_HOST:$REMOTE_PATH" "$LOCAL_PATH"
  else
    rsync -a -v -z --delete -e "ssh -p $SSH_PORT $SSH_OPTIONS" "$SSH_USER@$SSH_HOST:$REMOTE_PATH" "$LOCAL_PATH"
  fi

  if [ $? -eq 0 ]; then
    echo "✅ Download successful: $REMOTE_PATH => $LOCAL_PATH"
  else
    echo "❌ Download failed: $REMOTE_PATH => $LOCAL_PATH"
    exit 1
  fi
done

echo "Rsync download operations completed successfully"
exit 0