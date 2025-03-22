#!/bin/bash
set -e

# Setup SSH key if provided
if [ -n "$SSH_KEY" ]; then
  echo "Setting up SSH key"
  mkdir -p ~/.ssh
  echo "$SSH_KEY" > ~/.ssh/id_rsa
  chmod 600 ~/.ssh/id_rsa

  # Add host to known_hosts
  ssh-keyscan -p "$SSH_PORT" -H "$SSH_HOST" >> ~/.ssh/known_hosts 2>/dev/null

  echo "SSH key setup completed"
else
  echo "No SSH key provided, skipping SSH key setup"

  # Even without a key, we need to add the host to known_hosts for password auth
  mkdir -p ~/.ssh
  ssh-keyscan -p "$SSH_PORT" -H "$SSH_HOST" >> ~/.ssh/known_hosts 2>/dev/null
  echo "Added $SSH_HOST to known_hosts for password authentication"
fi

# Install sshpass if password authentication is needed
if [ -n "$SSH_PASS" ]; then
  echo "Password authentication will be used"

  # Check if sshpass is already installed
  if ! command -v sshpass &> /dev/null; then
    echo "Installing sshpass for password authentication"
    if command -v apt-get &> /dev/null; then
      sudo apt-get update -qq
      sudo apt-get install -qq -y sshpass
    elif command -v brew &> /dev/null; then
      brew install hudochenkov/sshpass/sshpass
    elif command -v yum &> /dev/null; then
      sudo yum install -y sshpass
    else
      echo "Error: Package manager not found. Cannot install sshpass."
      exit 1
    fi
  fi

  # Verify sshpass was installed correctly
  if ! command -v sshpass &> /dev/null; then
    echo "Error: Failed to install sshpass. Password authentication will not work."
    exit 1
  else
    echo "sshpass is available: $(which sshpass)"
  fi
fi

# Check for rsync
if ! command -v rsync &> /dev/null; then
  echo "Warning: rsync is not installed. The rsync operations will fail."
  echo "Please install rsync or avoid using rsync_upload/rsync_download options."
fi

exit 0