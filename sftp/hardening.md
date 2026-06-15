# SFTP Server Hardening

## sshd_config Hardening

```bash
# Edit /etc/ssh/sshd_config
# Disable root login
PermitRootLogin no

# Use key-based authentication only
PasswordAuthentication no
PubkeyAuthentication yes

# SFTP chroot jail
Subsystem sftp internal-sftp
Match Group sftpusers
  ChrootDirectory /srv/sftp/%u
  ForceCommand internal-sftp
  X11Forwarding no
  AllowTcpForwarding no
  PermitTTY no

# Restart SSH
sudo systemctl restart ssh
```

## Additional Hardening
- Use ed25519 keys instead of RSA
- Enable fail2ban for brute force protection
- Configure auditd for SFTP access logging
- Set up firewall rules (UFW) to restrict SFTP access
