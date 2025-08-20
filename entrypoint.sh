#!/bin/bash

# DevBox Entrypoint Script
# Performs initialization tasks before starting SSH server

# SSH Host Keys Management
SSH_HOST_KEYS_DIR="/etc/ssh/host_keys"

# Create directory if it doesn't exist
mkdir -p "$SSH_HOST_KEYS_DIR"

# Generate or restore SSH host keys
if [ ! -f "$SSH_HOST_KEYS_DIR/ssh_host_rsa_key" ]; then
    echo "Generating new SSH host keys..."
    ssh-keygen -t rsa -f "$SSH_HOST_KEYS_DIR/ssh_host_rsa_key" -N ''
    ssh-keygen -t ecdsa -f "$SSH_HOST_KEYS_DIR/ssh_host_ecdsa_key" -N ''
    ssh-keygen -t ed25519 -f "$SSH_HOST_KEYS_DIR/ssh_host_ed25519_key" -N ''
else
    echo "Using existing SSH host keys..."
fi

# Link or copy host keys to SSH directory
for key_type in rsa ecdsa ed25519; do
    if [ -f "$SSH_HOST_KEYS_DIR/ssh_host_${key_type}_key" ]; then
        cp -f "$SSH_HOST_KEYS_DIR/ssh_host_${key_type}_key" "/etc/ssh/ssh_host_${key_type}_key"
        cp -f "$SSH_HOST_KEYS_DIR/ssh_host_${key_type}_key.pub" "/etc/ssh/ssh_host_${key_type}_key.pub"
        chmod 600 "/etc/ssh/ssh_host_${key_type}_key"
        chmod 644 "/etc/ssh/ssh_host_${key_type}_key.pub"
    fi
done

# Auto-configure GitHub SSH if keys are present
if [ -f "/root/.ssh/id_rsa" ] || [ -f "/root/.ssh/id_ed25519" ] || [ -f "/root/.ssh/id_ecdsa" ]; then
    # Configure SSH for GitHub
    if [ ! -f "/root/.ssh/config" ]; then
        cat > /root/.ssh/config << 'EOF'
Host github.com
    HostName github.com
    User git
    PreferredAuthentications publickey
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
EOF
        
        # Add the first key we find
        if [ -f "/root/.ssh/id_ed25519" ]; then
            echo "    IdentityFile /root/.ssh/id_ed25519" >> /root/.ssh/config
        elif [ -f "/root/.ssh/id_rsa" ]; then
            echo "    IdentityFile /root/.ssh/id_rsa" >> /root/.ssh/config
        elif [ -f "/root/.ssh/id_ecdsa" ]; then
            echo "    IdentityFile /root/.ssh/id_ecdsa" >> /root/.ssh/config
        fi
        
        chmod 600 /root/.ssh/config
    fi
    
    # Fix SSH permissions
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/id_* 2>/dev/null || true
    chmod 644 /root/.ssh/*.pub 2>/dev/null || true
    
    # Add GitHub to known hosts
    if [ ! -f "/root/.ssh/known_hosts" ] || ! grep -q "github.com" /root/.ssh/known_hosts 2>/dev/null; then
        ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts 2>/dev/null
    fi
    
    # Configure gh CLI to use SSH
    gh config set git_protocol ssh 2>/dev/null || true
fi

# Configure git if environment variables are set
if [ -n "$GIT_AUTHOR_NAME" ]; then
    git config --global user.name "$GIT_AUTHOR_NAME"
fi

if [ -n "$GIT_AUTHOR_EMAIL" ]; then
    git config --global user.email "$GIT_AUTHOR_EMAIL"
fi

# Execute the main command
exec "$@"