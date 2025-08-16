# DevBox for Unraid

A complete development environment container for Unraid with Python, Node.js, and essential dev tools.

## Features

- **Python**: 3.11 and 3.12 with uv package manager
- **Node.js**: 20 LTS with npm
- **Claude Code**: Pre-installed CLI
- **Dev Tools**: git, make, tmux, vim, ripgrep, and more
- **SSH Server**: Remote access on port 2222
- **Persistent Config**: SSH keys, git config, bash history

## Quick Start

### 1. Build the Image

```bash
cd /mnt/user/appdata/devbox-unraid
docker build -t devbox:latest .
```

### 2. Install in Unraid

#### Option A: Via Unraid UI
1. Go to Docker tab → Add Container
2. Switch to Advanced View
3. Template → Select template file
4. Browse to `/mnt/user/appdata/devbox-unraid/devbox.xml`
5. Apply

#### Option B: Copy Template
```bash
cp devbox.xml /boot/config/plugins/dockerMan/templates-user/
```

### 3. First Time Setup

```bash
# SSH into container
ssh root@unraid.local -p 2222
# Password: devbox

# Configure git
git config --global user.name "Your Name"
git config --global user.email "your@email.com"

# Authenticate Claude Code
claude-code login

# Generate SSH key for GitHub
ssh-keygen -t ed25519 -C "your@email.com"
cat ~/.ssh/id_ed25519.pub  # Copy this to GitHub
```

## Usage

### Connect from IDE

**VS Code:**
1. Install "Remote - SSH" extension
2. Add host: `ssh root@unraid.local -p 2222`
3. Connect and open `/projects`

**JetBrains:**
1. Tools → Deployment → Configuration
2. Add SFTP connection to unraid.local:2222
3. Map local to `/projects`

### Running Projects

```bash
# Python projects
cd /projects/my-python-app
uv sync
uv run python main.py

# Node projects  
cd /projects/my-node-app
npm install
npm run dev
```

## Persistent Data

The following directories are persisted on Unraid:
- `/mnt/user/projects` - Your code
- `/mnt/user/appdata/devbox/ssh` - SSH keys
- `/mnt/user/appdata/devbox/gitconfig` - Git configuration
- `/mnt/user/appdata/devbox/claude-code` - Claude Code auth
- `/mnt/user/appdata/devbox/bash_history` - Command history

## Customization

Edit the `Dockerfile` to add more tools, then rebuild:

```bash
docker build -t devbox:latest .
docker restart devbox
```

## License

MIT