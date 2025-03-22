# SSH Sync Action

[![GitHub release](https://img.shields.io/github/v/release/lexty/ssh-sync-action?style=flat-square)](https://github.com/lexty/ssh-sync-action/releases/latest)
[![GitHub marketplace](https://img.shields.io/badge/marketplace-ssh--sync--action-blue?logo=github-actions&style=flat-square)](https://github.com/marketplace/actions/ssh-sync-action)
[![Tests](https://github.com/lexty/ssh-sync-action/actions/workflows/test.yml/badge.svg)](https://github.com/lexty/ssh-sync-action/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Execute SSH commands and bidirectional file transfers via rsync and scp.

## Features

- Execute SSH commands before and after data synchronization
- Bidirectional file transfer (upload and download)
- Support for both rsync and scp transfer methods
- Fine-grained control over each transfer method
- Secure authentication using password or SSH key
- Compatible with existing SSH/SCP actions interface
- Built on top of the well-tested `appleboy/ssh-action` for SSH execution

## Usage

```yaml
- name: Deploy and sync files
  uses: lexty/ssh-sync-action@v1
  with:
    host: ${{ secrets.REMOTE_HOST }}
    user: ${{ secrets.REMOTE_USER }}
    key: ${{ secrets.SSH_PRIVATE_KEY }}
    
    # Initial setup commands
    first_ssh: |
      mkdir -p /app/public
      systemctl stop myapp
    
    # Upload app code with rsync
    rsync_upload: |
      './dist/*' => /app/public/
      ./assets/ => /app/public/assets/
    
    # Download logs from the server
    scp_download: |
      /var/log/myapp/* => ./logs/
    
    # Finalize deployment
    last_ssh: |
      chown -R www-data:www-data /app
      systemctl start myapp
```

## Inputs

| Input             | Description                               | Required | Default         |
|-------------------|-------------------------------------------|----------|-----------------|
| `host`            | SSH remote host                           | Yes      |                 |
| `port`            | SSH remote port                           | No       | `22`            |
| `user`            | SSH remote user                           | Yes      |                 |
| `pass`            | SSH remote password                       | No       |                 |
| `key`             | SSH private key as string                 | No       |                 |
| `connect_timeout` | Connection timeout to remote host         | No       | `30s`           |
| `first_ssh`       | Execute commands before syncing data      | No       |                 |
| `scp_upload`      | Upload from local to remote using scp     | No       |                 |
| `scp_download`    | Download from remote to local using scp   | No       |                 |
| `rsync_upload`    | Upload from local to remote using rsync   | No       |                 |
| `rsync_download`  | Download from remote to local using rsync | No       |                 |
| `last_ssh`        | Execute commands after syncing data       | No       |                 |
| `scp_options`     | Additional scp command options            | No       | ``              |
| `rsync_options`   | Additional rsync command options          | No       | `-avz --delete` |
| `ssh_options`     | Additional SSH options                    | No       | ``              |

## Path Syntax

All upload and download parameters use the following syntax:

```
source_path => destination_path
```

For multiple transfers, specify multiple lines:

```
path1 => destination1
path2 => destination2
```

## rsync vs scp

Choose the best tool for your specific use case:

### rsync advantages:
- Delta transfers (only transfers changed parts of files)
- Resume capability for interrupted transfers
- Preserves file attributes (permissions, timestamps, etc.)
- Efficient directory handling
- Powerful filtering options

### scp advantages:
- More widely available on systems
- Simpler for basic use cases
- No need for rsync to be installed on the remote server

## Examples

### Using rsync for deployment

```yaml
- name: Deploy with rsync
  uses: lexty/ssh-sync-action@v1
  with:
    host: ${{ secrets.REMOTE_HOST }}
    user: ${{ secrets.REMOTE_USER }}
    key: ${{ secrets.SSH_PRIVATE_KEY }}
    first_ssh: |
      mkdir -p /var/www/app
      systemctl stop myapp
    rsync_upload: |
      './dist/*' => /var/www/app/
      ./config/prod.conf => /var/www/app/config/
    rsync_options: '-avz --checksum --delete'
    last_ssh: |
      chown -R www-data:www-data /var/www/app
      systemctl start myapp
```

### Using SCP for sensitive files

```yaml
- name: Transfer sensitive files
  uses: lexty/ssh-sync-action@v1
  with:
    host: ${{ secrets.REMOTE_HOST }}
    user: ${{ secrets.REMOTE_USER }}
    key: ${{ secrets.SSH_PRIVATE_KEY }}
    scp_upload: |
      './config/secrets.json' => /app/config/
    scp_options: '-r -q'
```

### Collecting logs and reports

```yaml
- name: Collect logs
  uses: lexty/ssh-sync-action@v1
  with:
    host: ${{ secrets.REMOTE_HOST }}
    user: ${{ secrets.REMOTE_USER }}
    key: ${{ secrets.SSH_PRIVATE_KEY }}
    scp_download: |
      /var/log/myapp/error.log => ./logs/
      /var/log/myapp/access.log => ./logs/
      /var/www/app/reports/* => ./reports/
```

## Requirements

- For rsync: The remote server must have rsync installed
- For SSH key authentication: The private key must be provided via the `key` input
- For password authentication: The password must be provided via the `pass` input

## Security

For sensitive information like SSH passwords or private keys, always use GitHub Secrets. Never commit these values directly in your workflow files.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Changelog

All notable changes to this project will be documented in the [CHANGELOG.md](CHANGELOG.md) file.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
