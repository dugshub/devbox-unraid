#!/bin/bash

# DevBox Launcher Script
# Easy startup script for DevBox development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"

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

# Check Docker installation
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    print_status "Docker found"
}

# Check docker-compose installation
check_compose() {
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    elif docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        print_error "Docker Compose is not installed"
        exit 1
    fi
    print_status "Docker Compose found: ${COMPOSE_CMD}"
}

# Create config directories
setup_directories() {
    print_status "Setting up directories..."
    
    # Use environment variables if set, otherwise use defaults
    PROJECTS_DIR=${PROJECTS_DIR:-"${SCRIPT_DIR}/projects"}
    APPDATA_DIR=${APPDATA_DIR:-"${SCRIPT_DIR}/config"}
    
    # Create project directory
    mkdir -p "$PROJECTS_DIR"
    
    # Create config directories
    mkdir -p "${APPDATA_DIR}/ssh"
    mkdir -p "${APPDATA_DIR}/claude-code"
    
    # Create gitconfig file if it doesn't exist
    if [ ! -f "${APPDATA_DIR}/gitconfig" ]; then
        touch "${APPDATA_DIR}/gitconfig"
    fi
    
    # Set proper permissions for SSH
    chmod 700 "${APPDATA_DIR}/ssh"
}

# Load environment file
load_env() {
    if [ -f "$ENV_FILE" ]; then
        print_status "Loading environment from .env"
        export $(grep -v '^#' "$ENV_FILE" | xargs)
    else
        print_warning ".env file not found, using defaults"
    fi
}

# Build image
build_image() {
    local rebuild=${1:-false}
    
    if [ "$rebuild" = true ] || [ "$1" = "--rebuild" ]; then
        print_status "Building DevBox image (forced rebuild)..."
        ${COMPOSE_CMD} -f "$COMPOSE_FILE" build --no-cache
    else
        print_status "Building DevBox image..."
        ${COMPOSE_CMD} -f "$COMPOSE_FILE" build
    fi
}

# Start container
start_container() {
    print_status "Starting DevBox container..."
    ${COMPOSE_CMD} -f "$COMPOSE_FILE" up -d
    
    # Wait for SSH to be ready
    print_status "Waiting for SSH service..."
    sleep 3
    
    # Get container info
    CONTAINER_NAME=${CONTAINER_NAME:-devbox-unraid}
    
    if docker ps | grep -q "$CONTAINER_NAME"; then
        print_status "DevBox is running!"
        
        # Get actual exposed ports from running container
        PORTS_INFO=$(docker port "$CONTAINER_NAME" 2>/dev/null)
        
        # Get actual volume mounts from running container
        VOLUMES_INFO=$(docker inspect "$CONTAINER_NAME" --format='{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' 2>/dev/null)
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  DevBox Development Environment"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "  Container: $CONTAINER_NAME"
        echo ""
        echo "  Exposed Ports:"
        if [ -n "$PORTS_INFO" ]; then
            echo "$PORTS_INFO" | while IFS= read -r line; do
                echo "    $line"
            done
        else
            echo "    No ports exposed"
        fi
        echo ""
        echo "  Mounted Volumes:"
        if [ -n "$VOLUMES_INFO" ]; then
            echo "$VOLUMES_INFO" | while IFS= read -r line; do
                if [ -n "$line" ]; then
                    echo "    $line"
                fi
            done
        else
            echo "    No volumes mounted"
        fi
        echo ""
        echo "  Connect via SSH:"
        # Extract SSH port dynamically from port mapping
        SSH_PORT=$(docker port "$CONTAINER_NAME" 22 2>/dev/null | cut -d':' -f2)
        if [ -n "$SSH_PORT" ]; then
            echo "    ssh -p $SSH_PORT root@localhost"
        else
            echo "    SSH port not exposed"
        fi
        echo ""
        echo "  Default password: devbox"
        echo ""
        echo "  Execute commands:"
        echo "    docker exec -it $CONTAINER_NAME bash"
        echo ""
        echo "  View logs:"
        echo "    docker logs -f $CONTAINER_NAME"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    else
        print_error "Container failed to start"
        docker logs "$CONTAINER_NAME"
        exit 1
    fi
}

# Main execution
main() {
    echo "DevBox Launcher v1.0"
    echo "===================="
    echo ""
    
    # Parse arguments
    case "${1:-}" in
        --rebuild)
            REBUILD=true
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --rebuild    Force rebuild of Docker image"
            echo "  --help       Show this help message"
            exit 0
            ;;
    esac
    
    # Run setup
    check_docker
    check_compose
    setup_directories
    load_env
    build_image ${REBUILD:-false}
    start_container
}

# Run main function
main "$@"