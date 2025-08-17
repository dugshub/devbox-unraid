#!/bin/bash

# DevBox Stop/Cleanup Script
# Gracefully stop and optionally clean up DevBox environment

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
CONTAINER_NAME=${CONTAINER_NAME:-devbox-unraid}

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

# Check for docker-compose command
get_compose_cmd() {
    if command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    elif docker compose version &> /dev/null; then
        echo "docker compose"
    else
        print_error "Docker Compose not found"
        exit 1
    fi
}

# Stop container
stop_container() {
    COMPOSE_CMD=$(get_compose_cmd)
    
    print_status "Stopping DevBox container..."
    ${COMPOSE_CMD} -f "$COMPOSE_FILE" stop
    print_status "DevBox stopped"
}

# Remove container
remove_container() {
    COMPOSE_CMD=$(get_compose_cmd)
    
    print_status "Removing DevBox container..."
    ${COMPOSE_CMD} -f "$COMPOSE_FILE" down
    print_status "Container removed"
}

# Clean volumes
clean_volumes() {
    COMPOSE_CMD=$(get_compose_cmd)
    
    print_warning "Removing volumes (this will delete container data)..."
    ${COMPOSE_CMD} -f "$COMPOSE_FILE" down -v
    print_status "Volumes removed"
}

# Clean images
clean_images() {
    print_warning "Removing DevBox Docker image..."
    docker rmi -f $(docker images -q devbox-unraid_devbox) 2>/dev/null || true
    docker rmi -f $(docker images -q *devbox*) 2>/dev/null || true
    print_status "Images removed"
}

# Full cleanup
full_cleanup() {
    print_warning "Performing full cleanup..."
    remove_container
    clean_volumes
    clean_images
    print_status "Full cleanup completed"
}

# Show usage
show_usage() {
    echo "DevBox Stop/Cleanup Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  (no args)    Stop the container (can be restarted)"
    echo "  --remove     Stop and remove the container"
    echo "  --clean      Stop, remove container and volumes"
    echo "  --purge      Full cleanup (container, volumes, images)"
    echo "  --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0           # Just stop the container"
    echo "  $0 --remove  # Stop and remove container"
    echo "  $0 --purge   # Complete cleanup"
}

# Main execution
main() {
    case "${1:-stop}" in
        stop)
            stop_container
            ;;
        --remove)
            remove_container
            ;;
        --clean)
            remove_container
            clean_volumes
            ;;
        --purge)
            full_cleanup
            ;;
        --help)
            show_usage
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"