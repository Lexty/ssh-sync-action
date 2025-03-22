# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-03-22

### Added
- Initial release of SSH Sync Action
- Core functionality for executing SSH commands using `appleboy/ssh-action`
- Bidirectional file transfer support:
    - Upload files using rsync (`rsync_upload`)
    - Download files using rsync (`rsync_download`)
    - Upload files using scp (`scp_upload`)
    - Download files using scp (`scp_download`)
- Support for both password and SSH key authentication
- Ability to execute commands before (`first_ssh`) and after (`last_ssh`) file transfers
- Comprehensive test suite with GitHub Actions workflow
- Detailed documentation with examples for various use cases
- Customizable options for rsync and scp commands
- Automatic handling of wildcards in file paths
- Directory creation for download operations
- Proper error handling and reporting
- Support for SSH connection options and timeouts