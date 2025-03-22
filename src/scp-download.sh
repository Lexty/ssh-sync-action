#!/bin/bash
set -e

# Setup ssh command for executing remote commands
if [ -n "$SSH_PASS" ]; then
  export SSHPASS="$SSH_PASS"
  SSH_CMD="sshpass -e ssh -p $SSH_PORT $SSH_OPTIONS"
else
  SSH_CMD="ssh -p $SSH_PORT $SSH_OPTIONS"
fi

# Parse and execute scp downloads
echo "Starting scp download operations"

# Initialize a counter for reporting
COUNT=0
TOTAL=$(echo "$SCP_DOWNLOAD_CONFIG" | grep -c "=>")

IFS=$'\n'
for LINE in $(echo "$SCP_DOWNLOAD_CONFIG" | grep "=>"); do
  # Extract source and destination paths
  REMOTE_PATH=$(echo "$LINE" | sed -E 's/^(.+) =>.+$/\1/' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed "s/'//g")
  LOCAL_PATH=$(echo "$LINE" | sed -E 's/^.+=> (.+)$/\1/' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed "s/'//g")

  # Increment counter
  COUNT=$((COUNT+1))

  echo "[$COUNT/$TOTAL] Downloading via scp: $REMOTE_PATH => $LOCAL_PATH"

  # Create destination directory if it doesn't exist
  DIR_PATH=$(dirname "$LOCAL_PATH")
  mkdir -p "$DIR_PATH"
  echo "Created local directory: $DIR_PATH"

  # Handle wildcards in remote path
  if [[ "$REMOTE_PATH" == *"*"* ]]; then
    echo "Detected wildcard in remote path: $REMOTE_PATH"

    # Get the directory and pattern parts
    REMOTE_DIR=$(dirname "$REMOTE_PATH")
    PATTERN=$(basename "$REMOTE_PATH")

    # List files matching the pattern on the remote server
    echo "Finding remote files matching pattern: $PATTERN in $REMOTE_DIR"

    # Get list of files, one per line
    if [ -n "$SSH_PASS" ]; then
      REMOTE_FILES=$(sshpass -e ssh -p "$SSH_PORT" $SSH_OPTIONS "$SSH_USER@$SSH_HOST" "find $REMOTE_DIR -name '$PATTERN' -type f 2>/dev/null")
    else
      REMOTE_FILES=$(ssh -p "$SSH_PORT" $SSH_OPTIONS "$SSH_USER@$SSH_HOST" "find $REMOTE_DIR -name '$PATTERN' -type f 2>/dev/null")
    fi

    # Check if any files were found
    if [ -z "$REMOTE_FILES" ]; then
      echo "Warning: No files found matching pattern $REMOTE_PATH on remote server"
      continue
    fi

    echo "Found files:"
    echo "$REMOTE_FILES"

    # Process each file separately
    while IFS= read -r REMOTE_FILE; do
      # Skip empty lines
      if [ -z "$REMOTE_FILE" ]; then
        continue
      fi

      FILENAME=$(basename "$REMOTE_FILE")

      # Check if LOCAL_PATH ends with a slash or is a directory name
      if [[ "$LOCAL_PATH" == */ ]]; then
        # If LOCAL_PATH ends with a slash, it's a directory
        DEST_PATH="${LOCAL_PATH}${FILENAME}"
      else
        # Check if LOCAL_PATH refers to an existing directory
        if [ -d "$LOCAL_PATH" ]; then
          DEST_PATH="${LOCAL_PATH}/${FILENAME}"
        else
          # Extract the destination directory and make sure it includes the target filename
          DEST_PATH="$LOCAL_PATH/$FILENAME"
        fi
      fi

      echo "Downloading file: $REMOTE_FILE => $DEST_PATH"
      if [ -n "$SSH_PASS" ]; then
        sshpass -e scp $SCP_OPTIONS -P "$SSH_PORT" $SSH_OPTIONS "$SSH_USER@$SSH_HOST:$REMOTE_FILE" "$DEST_PATH"
      else
        scp $SCP_OPTIONS -P "$SSH_PORT" $SSH_OPTIONS "$SSH_USER@$SSH_HOST:$REMOTE_FILE" "$DEST_PATH"
      fi

      if [ $? -eq 0 ]; then
        echo "✅ Download successful: $REMOTE_FILE => $DEST_PATH"
      else
        echo "❌ Download failed: $REMOTE_FILE => $DEST_PATH"
        exit 1
      fi
    done <<< "$REMOTE_FILES"

  else
    # Regular file download
    echo "Downloading single file: $REMOTE_PATH => $LOCAL_PATH"
    if [ -n "$SSH_PASS" ]; then
      sshpass -e scp $SCP_OPTIONS -P "$SSH_PORT" $SSH_OPTIONS "$SSH_USER@$SSH_HOST:$REMOTE_PATH" "$LOCAL_PATH"
    else
      scp $SCP_OPTIONS -P "$SSH_PORT" $SSH_OPTIONS "$SSH_USER@$SSH_HOST:$REMOTE_PATH" "$LOCAL_PATH"
    fi

    if [ $? -eq 0 ]; then
      echo "✅ Download successful: $REMOTE_PATH => $LOCAL_PATH"
    else
      echo "❌ Download failed: $REMOTE_PATH => $LOCAL_PATH"
      exit 1
    fi
  fi
done

echo "SCP download operations completed successfully"
exit 0