#!/bin/bash
set -e

# Check if rsync is installed
if ! command -v rsync &> /dev/null; then
  echo "Error: rsync is not installed. Please install rsync or use scp instead."
  exit 1
fi

# Parse and execute rsync uploads
echo "Starting rsync upload operations"

# Initialize a counter for reporting
COUNT=0
TOTAL=$(echo "$RSYNC_UPLOAD_CONFIG" | grep -c "=>")

IFS=$'\n'
for LINE in $(echo "$RSYNC_UPLOAD_CONFIG" | grep "=>"); do
  # Extract source and destination paths
  LOCAL_PATH=$(echo "$LINE" | sed -E 's/^(.+) =>.+$/\1/' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed "s/'//g")
  REMOTE_PATH=$(echo "$LINE" | sed -E 's/^.+=> (.+)$/\1/' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed "s/'//g")

  # Increment counter
  COUNT=$((COUNT+1))

  echo "[$COUNT/$TOTAL] Uploading via rsync: $LOCAL_PATH => $REMOTE_PATH"

  # Handle wildcards in local path
  if [[ "$LOCAL_PATH" == *"*"* ]]; then
    # Get the base directory without the wildcard
    LOCAL_DIR=$(dirname "$LOCAL_PATH")
    WILD_PATTERN=$(basename "$LOCAL_PATH")

    # Use find to get actual files matching the pattern
    FOUND_FILES=$(find "$LOCAL_DIR" -name "$WILD_PATTERN" 2>/dev/null)

    if [ -z "$FOUND_FILES" ]; then
      echo "Warning: No files found matching pattern $LOCAL_PATH"
      continue
    fi

    # Create remote directory if needed
    if [ -n "$SSH_PASS" ]; then
      export SSHPASS="$SSH_PASS"
      sshpass -e ssh -p "$SSH_PORT" $SSH_OPTIONS "$SSH_USER@$SSH_HOST" "mkdir -p '$REMOTE_PATH'"
    else
      ssh -p "$SSH_PORT" $SSH_OPTIONS "$SSH_USER@$SSH_HOST" "mkdir -p '$REMOTE_PATH'"
    fi

    # Upload each file found
    for FILE in $FOUND_FILES; do
      echo "  Uploading: $FILE"
      if [ -n "$SSH_PASS" ]; then
        export SSHPASS="$SSH_PASS"
        sshpass -e rsync -avz -e "ssh -p $SSH_PORT $SSH_OPTIONS" "$FILE" "$SSH_USER@$SSH_HOST:$REMOTE_PATH"
      else
        rsync -avz -e "ssh -p $SSH_PORT $SSH_OPTIONS" "$FILE" "$SSH_USER@$SSH_HOST:$REMOTE_PATH"
      fi
    done
  else
    # Regular file upload
    if [ -n "$SSH_PASS" ]; then
      export SSHPASS="$SSH_PASS"
      sshpass -e rsync -avz -e "ssh -p $SSH_PORT $SSH_OPTIONS" "$LOCAL_PATH" "$SSH_USER@$SSH_HOST:$REMOTE_PATH"
    else
      rsync -avz -e "ssh -p $SSH_PORT $SSH_OPTIONS" "$LOCAL_PATH" "$SSH_USER@$SSH_HOST:$REMOTE_PATH"
    fi
  fi

  if [ $? -eq 0 ]; then
    echo "✅ Upload successful: $LOCAL_PATH => $REMOTE_PATH"
  else
    echo "❌ Upload failed: $LOCAL_PATH => $REMOTE_PATH"
    exit 1
  fi
done

echo "Rsync upload operations completed successfully"
exit 0