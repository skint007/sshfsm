# SSHM - SSH File System Mount Manager

A simplified bash script for easily mounting remote servers using SSHFS with intelligent defaults, JSON configuration, and optional persistent mounts.

## Features

- **Simple syntax**: Just `sshm hostname` or `sshm user@hostname`
- **Intelligent defaults**: Automatically configures sensible SSHFS settings
- **Auto-configuration**: Saves server settings on first mount for reuse
- **JSON configuration**: Clean, readable config in `~/.config/sshm/sshm.json`
- **Persistent mounts**: Optionally add mounts to `/etc/fstab` to survive reboots
- **sftp-server auto-detection**: Automatically locates `sftp-server` during initialization
- **Bash completion**: Tab completion for commands and configured server names

## Installation

### From AUR (Arch Linux)

```bash
yay -S sshm
# or
makepkg -si
```

### Manual Install

```bash
./install.sh
```

This will:
- Check for and install dependencies (on Arch Linux)
- Copy `sshm` to `~/.local/bin/sshm`
- Install bash completion to `/etc/bash_completion.d/`

## Quick Start

```bash
# Mount a server with defaults (auto-detects and saves config)
sshm myserver

# Mount with specific user
sshm admin@fileserver.example.com

# Unmount when done
sshm umount myserver
```

The first time you mount a server, sshm will:
1. Use intelligent defaults (port 22, remote path `/`, mount to `~/mnt/<hostname>`)
2. Auto-save the configuration for next time
3. Mount the filesystem using SSHFS

## Usage

### Basic Mounting
```bash
sshm <hostname>                 # Mount with defaults, save config
sshm <user@hostname>            # Mount with specific user
sshm myserver                   # Use existing config or create new
```

### Commands
```bash
sshm mount <server>             # Same as just passing a hostname
sshm umount <server>            # Unmount a mounted server
sshm list                       # List all active SSHFS mounts
sshm status                     # Show config and active mounts
sshm add <server>               # Add/update server config interactively
sshm edit <server>              # Edit existing server config
sshm remove <server>            # Remove server config
sshm config                     # Show current configuration file
```

### Options
```
-i, --ignore        Ignore SSH host key checking (StrictHostKeyChecking=no)
-p, --persistent    Make mount persistent across reboots (adds to /etc/fstab)
-d, --debug         Enable debug output (also passes -d to sshfs)
-v, --verbose       Show verbose output (implies --debug)
-c, --clear         Clear mount history
--init              Initialize configuration directory and defaults
--version           Show version information
-?, -h, --help      Show help message
```

## Configuration

### Location

- **Config file**: `~/.config/sshm/sshm.json`
- **History file**: `~/.config/sshm/history`
- **Mount directory**: `~/mnt/<hostname>`

### Default Settings
- **Port**: 22
- **Remote path**: `/` (root)
- **Mount directory**: `~/mnt/<hostname>`
- **Options**: `sftp_server=sudo <detected-path>`, `idmap=user`, `reconnect`, `ServerAliveInterval=15`, `ServerAliveCountMax=3`

During `--init`, sshm automatically detects the location of `sftp-server` on your system (checking common paths like `/usr/lib/ssh/sftp-server`, `/usr/libexec/sftp-server`, etc.) and configures the default options accordingly.

### Example Configuration File
```json
{
  "version": "2.3.1",
  "defaults": {
    "port": 22,
    "remotePath": "/",
    "mountDir": "/home/user/mnt",
    "options": "-o 'sftp_server=sudo /usr/lib/ssh/sftp-server',idmap=user,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3"
  },
  "servers": {
    "webserver.example.com": {
      "user": "admin",
      "hostname": "webserver.example.com",
      "port": 22,
      "remotePath": "/",
      "localPath": "/home/user/mnt/webserver.example.com",
      "options": "-o 'sftp_server=sudo /usr/lib/ssh/sftp-server',idmap=user,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3"
    },
    "production": {
      "user": "deploy",
      "hostname": "prod.example.com",
      "port": 2222,
      "remotePath": "/var/www",
      "localPath": "/home/user/mnt/production",
      "options": "-o reconnect,ServerAliveInterval=30"
    }
  }
}
```

## Examples

### Quick Daily Usage
```bash
# Mount a server with defaults
sshm myserver
# → Mounts to ~/mnt/myserver

# Mount with specific user
sshm admin@fileserver.example.com
# → Uses user 'admin', saves config as 'fileserver.example.com'

# Remount later (uses saved config)
sshm myserver

# Unmount when done
sshm umount myserver
```

### Persistent Mounts
```bash
# Mount and add to /etc/fstab for reboot persistence
sshm -p myserver

# When unmounting, sshm will offer to remove the fstab entry
sshm umount myserver
```

**Note:** Persistent mounts require an SSH identity file at `~/.ssh/id_ed25519_<hostname>`.

### Configuration Management
```bash
# Add a server with custom settings
sshm add production
# → Prompts for user, hostname, port, paths, options

# Edit existing server
sshm edit production

# View what's configured and mounted
sshm status

# List active mounts only
sshm list

# Remove a server from config
sshm remove production
```

### Troubleshooting
```bash
# Verbose mounting for troubleshooting
sshm -v problematic-server

# Debug mode (passes -d to sshfs)
sshm -d myserver

# Mount with host key checking disabled
sshm -i new-server.example.com
```

## How It Works

1. **First Mount**: When you run `sshm hostname`, it:
   - Uses intelligent defaults for all settings
   - Mounts the filesystem via SSHFS
   - Auto-saves the configuration for future use

2. **Subsequent Mounts**: Uses the saved configuration automatically

3. **Persistent Mounts**: With `-p`, adds an entry to `/etc/fstab` (with backup) so the mount survives reboots. On unmount, offers to clean up the fstab entry.

4. **Configuration**: Stored in clean JSON format at `~/.config/sshm/sshm.json`, easy to read and edit manually if needed.

## Dependencies

- **bash** - shell interpreter
- **sshfs** - for mounting remote filesystems
- **jq** - for JSON configuration processing
- **fuse2** - FUSE support (provides `fusermount` for unmounting)
- **openssh** (optional) - for SSH connections

On Arch Linux:
```bash
sudo pacman -S sshfs jq fuse2
```

On Ubuntu/Debian:
```bash
sudo apt install sshfs jq
```

## Troubleshooting

### Common Issues

**"jq: command not found"**
```bash
sudo pacman -S jq              # Arch Linux
sudo apt install jq            # Ubuntu/Debian
```

**"Permission denied (publickey)"**
- Set up SSH key authentication for the target host
- Or use `sshm -i hostname` to skip host key verification (not recommended for production)

**"Mount point already mounted"**
```bash
sshm umount hostname           # Unmount first
sshm list                      # Check active mounts
```

**"sftp-server not found"**
- Run `sshm --init` to re-detect the sftp-server location
- Or install openssh-server on your system

**Configuration Issues**
```bash
sshm config                    # Show current config
sshm edit servername           # Fix server config
sshm --init                    # Re-initialize defaults
```

## License

MIT
