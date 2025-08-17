#!/bin/bash

# GitHub CLI SSH Authentication Setup Script
# Sets up GitHub CLI with SSH authentication using mounted SSH keys

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Check if running inside container
check_environment() {
    if [ ! -f /.dockerenv ]; then
        print_warning "This script should be run inside the DevBox container"
        echo "Run: docker exec -it devbox-unraid ./setup-github.sh"
        exit 1
    fi
}

# Check SSH keys
check_ssh_keys() {
    print_info "Checking for SSH keys..."
    
    if [ ! -d "/root/.ssh" ]; then
        print_error "SSH directory not found. Ensure config/.ssh is mounted."
        exit 1
    fi
    
    # Look for existing SSH keys
    if [ -f "/root/.ssh/id_rsa" ]; then
        SSH_KEY="/root/.ssh/id_rsa"
        print_status "Found RSA key: $SSH_KEY"
    elif [ -f "/root/.ssh/id_ed25519" ]; then
        SSH_KEY="/root/.ssh/id_ed25519"
        print_status "Found Ed25519 key: $SSH_KEY"
    elif [ -f "/root/.ssh/id_ecdsa" ]; then
        SSH_KEY="/root/.ssh/id_ecdsa"
        print_status "Found ECDSA key: $SSH_KEY"
    else
        print_warning "No SSH keys found in /root/.ssh/"
        echo ""
        echo "To generate a new SSH key:"
        echo "  ssh-keygen -t ed25519 -C 'your-email@example.com'"
        echo ""
        echo "Or copy existing keys to the mounted config/.ssh/ directory"
        exit 1
    fi
    
    # Check key permissions
    chmod 600 "$SSH_KEY"
    chmod 644 "${SSH_KEY}.pub" 2>/dev/null || true
    chmod 700 /root/.ssh
}

# Configure SSH for GitHub
configure_ssh() {
    print_info "Configuring SSH for GitHub..."
    
    # Create SSH config if it doesn't exist
    if [ ! -f "/root/.ssh/config" ]; then
        cat > /root/.ssh/config << 'EOF'
Host github.com
    HostName github.com
    User git
    PreferredAuthentications publickey
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
EOF
        
        # Add identity file based on what we found
        echo "    IdentityFile $SSH_KEY" >> /root/.ssh/config
        
        chmod 600 /root/.ssh/config
        print_status "Created SSH config for GitHub"
    else
        print_status "SSH config already exists"
    fi
    
    # Add GitHub to known hosts if not already there
    if ! grep -q "github.com" /root/.ssh/known_hosts 2>/dev/null; then
        print_info "Adding GitHub to known hosts..."
        ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts 2>/dev/null
        print_status "Added GitHub to known hosts"
    fi
}

# Test SSH connection
test_ssh_connection() {
    print_info "Testing SSH connection to GitHub..."
    
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        print_status "SSH connection to GitHub successful!"
        return 0
    else
        print_warning "SSH connection test inconclusive. This might still work."
        echo "Run 'ssh -T git@github.com' to test manually"
        return 0
    fi
}

# Configure GitHub CLI
configure_gh_cli() {
    print_info "Configuring GitHub CLI..."
    
    # Check if gh is already authenticated
    if gh auth status &>/dev/null; then
        print_status "GitHub CLI is already authenticated"
        gh auth status
    else
        print_info "Setting up GitHub CLI with SSH..."
        
        # Configure git protocol for gh
        gh config set git_protocol ssh
        print_status "Set git protocol to SSH"
        
        echo ""
        print_info "To complete GitHub CLI setup, run:"
        echo "  gh auth login"
        echo ""
        echo "When prompted:"
        echo "  1. Choose 'GitHub.com'"
        echo "  2. Choose 'SSH' for preferred protocol"
        echo "  3. Choose your SSH key: $SSH_KEY"
        echo "  4. Authenticate via browser or paste token"
    fi
}

# Display SSH public key
show_public_key() {
    if [ -f "${SSH_KEY}.pub" ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  Your SSH Public Key"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        cat "${SSH_KEY}.pub"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        print_info "Add this key to GitHub at:"
        echo "  https://github.com/settings/keys"
        echo ""
    fi
}

# Main execution
main() {
    echo "GitHub SSH Authentication Setup"
    echo "================================"
    echo ""
    
    check_environment
    check_ssh_keys
    configure_ssh
    test_ssh_connection
    configure_gh_cli
    show_public_key
    
    print_status "GitHub SSH setup complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Ensure your SSH public key is added to GitHub"
    echo "  2. Run 'gh auth login' if not already authenticated"
    echo "  3. Test with: gh repo list"
}

# Run main function
main "$@"