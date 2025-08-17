# DevBox for Unraid - Claude Assistant Context

## Project Overview
DevBox is a containerized development environment designed for Unraid servers. It provides a fully-featured development setup with Python, Node.js, and Claude Code CLI pre-installed, accessible via SSH.

## Architecture
- **Base**: Ubuntu 22.04 LTS container
- **Access**: SSH on configurable port (default: 2222)
- **Languages**: Python 3.11/3.12, Node.js 20 LTS
- **Package Managers**: uv (Python), npm (Node.js)
- **AI Tools**: Claude Code CLI pre-installed

## File Structure
```
devbox-unraid/
├── Dockerfile           # Container definition
├── docker-compose.yml   # Service orchestration
├── launch.sh           # Startup script
├── stop.sh             # Stop/cleanup script
├── .env.example        # Environment configuration template
├── CLAUDE.md           # This file (assistant context)
├── devbox.xml          # Legacy Unraid template (not used)
├── projects/           # Mounted project directory
└── config/             # Persistent configurations
    ├── .ssh/           # SSH keys and config
    ├── .gitconfig      # Git configuration
    └── claude-code/    # Claude Code settings
```

## Key Commands

### Container Management
```bash
# Start DevBox
./launch.sh              # Normal start
./launch.sh --rebuild    # Force rebuild image

# Stop DevBox
./stop.sh               # Just stop (can restart)
./stop.sh --remove      # Stop and remove container
./stop.sh --clean       # Remove container and volumes
./stop.sh --purge       # Full cleanup (container, volumes, images)

# Direct Docker commands (if inside Unraid)
docker exec -it devbox-unraid bash
docker logs -f devbox-unraid
```

### SSH Access
```bash
# Default connection
ssh -p 2222 root@localhost
# Password: devbox
```

## Configuration (.env file)
Key environment variables:
- `CONTAINER_NAME`: Container name (default: devbox-unraid)
- `SSH_PORT`: SSH port mapping (default: 2222)
- `PROJECTS_DIR`: Host directory for projects
- `CONFIG_DIR`: Host directory for persistent configs
- `CLAUDE_API_KEY`: Optional Claude API key
- `GIT_AUTHOR_NAME/EMAIL`: Git configuration
- Resource limits: CPU and memory constraints

## Development Tools Available
- **Python**: 3.11, 3.12 with venv support
- **Node.js**: v20 LTS with npm
- **Package Managers**: uv (Python), npm/npx (Node)
- **AI Tools**: claude-code CLI (alias: cc)
- **Editors**: vim, nano
- **Terminal**: tmux, screen
- **Search**: ripgrep (rg), fd-find
- **Utils**: git, make, jq, tree, htop, bat, ncdu

## Common Tasks

### Python Development
```bash
# Create virtual environment with uv
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt

# Or use specific Python version
python3.12 -m venv myenv
```

### Node.js Development
```bash
npm install
npm run dev
npx create-react-app myapp
```

### Claude Code Usage
```bash
# Quick alias
cc "Help me with this code"

# Full command
claude-code "Analyze this project"
```

## Volumes and Persistence
- `/projects`: Main development directory (mounted from host)
- `/root/.ssh`: SSH keys persist across restarts
- `/root/.gitconfig`: Git config persists
- `/root/.config/claude-code`: Claude settings persist

## Network Configuration
- Container runs on bridge network `devbox-network`
- SSH exposed on configurable port (default: 2222)
- Additional ports can be exposed in docker-compose.yml

## Security Notes
- Default root password is "devbox" - change in production
- SSH root login is enabled for development convenience
- Consider using SSH keys instead of password authentication
- Don't expose SSH port to public internet without proper security

## Troubleshooting

### Container won't start
```bash
# Check logs
docker logs devbox-unraid

# Verify ports aren't in use
netstat -tulpn | grep 2222

# Clean restart
./stop.sh --purge
./launch.sh --rebuild
```

### SSH connection refused
```bash
# Check if container is running
docker ps | grep devbox

# Verify SSH service inside container
docker exec devbox-unraid service ssh status

# Check port mapping
docker port devbox-unraid
```

### Permission issues
```bash
# Fix SSH directory permissions
chmod 700 config/.ssh
chmod 600 config/.ssh/id_rsa  # if using keys
```

## Integration with Unraid
This DevBox is designed to run on Unraid but doesn't use the traditional XML template approach. Instead:
1. Place files in Unraid share (e.g., `/mnt/user/appdata/devbox/`)
2. Run `./launch.sh` from Unraid terminal or User Scripts plugin
3. Access via SSH from any network client

## Best Practices
1. Always use `.env` file for configuration (copy from `.env.example`)
2. Mount project directories to preserve work
3. Use config mounts for persistent settings
4. Regularly backup your config directory
5. Use SSH keys for better security
6. Set resource limits appropriate to your Unraid server

## Updates and Maintenance
```bash
# Update base image
docker pull ubuntu:22.04
./launch.sh --rebuild

# Update tools inside container
docker exec -it devbox-unraid bash
npm update -g
uv self update
```