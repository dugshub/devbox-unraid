#!/bin/bash

# DevBox SSH Client Setup Script
# This script configures your local SSH client to connect to DevBox easily

echo "DevBox SSH Client Setup"
echo "========================"

# Default values
DEFAULT_HOST="10.88.111.3"
DEFAULT_PORT="2222"
DEFAULT_USER="devbox"

# Get user input
read -p "Enter DevBox host IP [$DEFAULT_HOST]: " HOST
HOST=${HOST:-$DEFAULT_HOST}

read -p "Enter SSH port [$DEFAULT_PORT]: " PORT
PORT=${PORT:-$DEFAULT_PORT}

read -p "Enter username [$DEFAULT_USER]: " USER
USER=${USER:-$DEFAULT_USER}

# Create SSH config directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Check if SSH config exists
if [ ! -f ~/.ssh/config ]; then
    touch ~/.ssh/config
    chmod 600 ~/.ssh/config
fi

# Check if devbox entry already exists
if grep -q "Host devbox" ~/.ssh/config; then
    echo ""
    echo "⚠️  DevBox SSH config already exists in ~/.ssh/config"
    read -p "Do you want to update it? (y/n): " UPDATE
    if [ "$UPDATE" != "y" ]; then
        echo "Skipping SSH config update."
    else
        # Remove existing devbox config
        sed -i.bak '/^Host devbox/,/^$/d' ~/.ssh/config
        
        # Add new config
        cat >> ~/.ssh/config << EOF

Host devbox
    HostName $HOST
    Port $PORT
    User $USER
    StrictHostKeyChecking accept-new
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF
        echo "✅ SSH config updated"
    fi
else
    # Add devbox config
    cat >> ~/.ssh/config << EOF

Host devbox
    HostName $HOST
    Port $PORT
    User $USER
    StrictHostKeyChecking accept-new
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF
    echo "✅ SSH config added"
fi

# Option to set up SSH key authentication
echo ""
read -p "Do you want to set up SSH key authentication? (y/n): " SETUP_KEY

if [ "$SETUP_KEY" = "y" ]; then
    # Check for existing SSH key
    if [ ! -f ~/.ssh/id_ed25519 ] && [ ! -f ~/.ssh/id_rsa ]; then
        echo "No SSH key found. Generating new ED25519 key..."
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
    fi
    
    echo ""
    echo "Copying SSH key to DevBox..."
    echo "You'll be prompted for the DevBox password (default: devbox)"
    
    if [ -f ~/.ssh/id_ed25519.pub ]; then
        ssh-copy-id -p $PORT $USER@$HOST
    elif [ -f ~/.ssh/id_rsa.pub ]; then
        ssh-copy-id -p $PORT $USER@$HOST
    fi
    
    echo "✅ SSH key authentication configured"
fi

echo ""
echo "Setup complete! You can now connect to DevBox using:"
echo "  ssh devbox"
echo ""
echo "For VS Code/Windsurf Remote SSH:"
echo "  1. Install Remote-SSH extension"
echo "  2. Connect to host: devbox"
echo ""