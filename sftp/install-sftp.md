# Install SFTP Server

## Installation

```bash
# Update and install OpenSSH server
sudo apt update
sudo apt install -y openssh-server

# Verify SSH is running
sudo systemctl status ssh

# Backup original config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
```

## Basic Configuration

```bash
# Create SFTP group
sudo groupadd sftpusers

# Create SFTP user
sudo useradd -m -G sftpusers -s /usr/sbin/nologin sftpuser
sudo passwd sftpuser

# Create upload directory
sudo mkdir -p /srv/sftp/uploads
sudo chown root:root /srv/sftp
sudo chmod 755 /srv/sftp
sudo chown sftpuser:sftpusers /srv/sftp/uploads
```
