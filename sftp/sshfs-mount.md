# Mount SFTP with SSHFS

## Prerequisites

```bash
# Install sshfs
sudo apt install -y sshfs
```

## Mount Remote Directory

```bash
# Create mount point
mkdir -p ~/mnt/remote

# Mount via SSHFS
sshfs user@hostname:/remote/path ~/mnt/remote

# Mount with specific port and options
sshfs user@hostname:/remote/path ~/mnt/remote \
  -p 2222 \
  -o IdentityFile=~/.ssh/id_rsa \
  -o allow_other \
  -o reconnect

# Unmount
fusermount -u ~/mnt/remote
```

## Automount with /etc/fstab

```
user@hostname:/remote/path /local/mount fuse.sshfs defaults,_netdev,IdentityFile=~/.ssh/id_rsa,allow_other,reconnect 0 0
```
