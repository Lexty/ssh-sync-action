#!/bin/bash
set -e

# Parse and execute scp uploads
echo "Starting scp upload operations"

# Initialize a counter for reporting
COUNT=0
TOTAL=$(echo "$SCP_UPLOAD_CONFIG" | grep -c "=>")

IFS=$'\n'
for LINE in $(echo "$SCP_UPLOAD_CONFIG" | grep "=>"); do
  # Extract source and destination paths
  LOCAL_PATH=$(echo "$LINE" | sed -E 's/^(.+) =>.+$/\1/' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed "s/'//g")
  REMOTE_PATH=$(echo "$LINE" | sed -E 's/^.+=> (.+)$/\1/' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed "s/'//g")

  # Increment counter
  COUNT=$((COUNT+1))

  echo "[$COUNT/$TOTAL] Uploading via scp: $LOCAL_PATH => $REMOTE_PATH"

  # Create the remote directory (the full path)
  if [ -n "$SSH_PASS" ]; then
    export SSHPASS="$SSH_PASS"
    # For regular files, create parent directory
    if [[ "$LOCAL_PATH" != *"*"* ]]; then
      REMOTE_DIR=$(dirname "$REMOTE_PATH")
      echo "Creating remote directory structure for: $REMOTE_DIR"
      sshpass -e ssh -p "$SSH_PORT" $SSH_OPTIONS "$SSH_USER@$SSH_HOST" "mkdir -p $REMOTE_DIR"
    else
      # For wildcards, create the full directory
      echo "Creating remote directory structure for: $REMOTE_PATH"
      sshpass -e ssh -p "$SSH_PORT" $SSH_OPTIONS "$SSH_USER@$SSH_HOST" "mkdir -p $REMOTE_PATH"
    fi
  else
    if [[ "$LOCAL_PATH" != *"*"* ]]; then
      REMOTE_DIR=$(dirname "$REMOTE_PATH")
      echo "Creating remote directory structure for: $REMOTE_DIR"
      ssh -p "$SSH_PORT" $SSH_OPTIONS "$SSH_USER@$SSH_HOST" "mkdir -p $REMOTE_DIR"
    else
      echo "Creating remote directory structure for: $REMOTE_PATH"
      ssh -p "$SSH_PORT" $SSH_OPTIONS "$SSH_USER@$SSH_HOST" "mkdir -p $REMOTE_PATH"
    fi
  fi

  # Handle wildcards in local path
  if [[ "$LOCAL_PATH" == *"*"* ]]; then
    echo "Detected wildcard in path: $LOCAL_PATH"

    # Get the directory part of the path
    DIR_PATH=$(dirname "$LOCAL_PATH")
    PATTERN=$(basename "$LOCAL_PATH")

    # Find files matching the pattern
    FOUND_FILES=$(find "$DIR_PATH" -name "$PATTERN" -type f 2>/dev/null)

    if [ -z "$FOUND_FILES" ]; then
      echo "Warning: No files found matching pattern $LOCAL_PATH"
      continue
    fi

    # Upload each file individually
    for FILE in $FOUND_FILES; do
      FILENAME=$(basename "$FILE")
      DEST_PATH="$REMOTE_PATH/$FILENAME"

      echo "Uploading file: $FILE => $DEST_PATH"

      # Use the full command directly to avoid variable expansion issues
      if [ -n "$SSH_PASS" ]; then
        export SSHPASS="$SSH_PASS"
        sshpass -e scp $SCP_OPTIONS -P "$SSH_PORT" $SSH_OPTIONS "$FILE" "$SSH_USER@$SSH_HOST:$DEST_PATH"
      else
        scp $SCP_OPTIONS -P "$SSH_PORT" $SSH_OPTIONS "$FILE" "$SSH_USER@$SSH_HOST:$DEST_PATH"
      fi

      if [ $? -eq 0 ]; then
        echo "✅ Upload successful: $FILE => $DEST_PATH"
      else
        echo "❌ Upload failed: $FILE => $DEST_PATH"
        exit 1
      fi
    done
  else
    # Regular file upload
    if [ ! -e "$LOCAL_PATH" ]; then
      echo "Warning: File or directory does not exist: $LOCAL_PATH"
      continue
    fi

    # Use the full command directly to avoid variable expansion issues
    if [ -n "$SSH_PASS" ]; then
      export SSHPASS="$SSH_PASS"
      sshpass -e scp $SCP_OPTIONS -P "$SSH_PORT" $SSH_OPTIONS "$LOCAL_PATH" "$SSH_USER@$SSH_HOST:$REMOTE_PATH"
    else
      scp $SCP_OPTIONS -P "$SSH_PORT" $SSH_OPTIONS "$LOCAL_PATH" "$SSH_USER@$SSH_HOST:$REMOTE_PATH"
    fi

    if [ $? -eq 0 ]; then
      echo "✅ Upload successful: $LOCAL_PATH => $REMOTE_PATH"
    else
      echo "❌ Upload failed: $LOCAL_PATH => $REMOTE_PATH"
      exit 1
    fi
  fi
done

echo "SCP upload operations completed successfully"
exit 0