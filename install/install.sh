#!/bin/bash
# Main installation script for Piper stack

set -e

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENTS_DIR="$SCRIPT_DIR/components"

# Source utility functions
source "$COMPONENTS_DIR/utils.sh"

# Source all component scripts
source "$COMPONENTS_DIR/check_prerequisites.sh"
source "$COMPONENTS_DIR/setup_directories.sh"
source "$COMPONENTS_DIR/clone_repository.sh"
source "$COMPONENTS_DIR/configure_env_files.sh"
source "$COMPONENTS_DIR/setup_node_labels.sh"
source "$COMPONENTS_DIR/post_installation.sh"

# Display banner
echo -e "${GREEN}=== Piper Stack Installation Script ===${NC}"
echo -e "${YELLOW}This script will install and configure the Piper stack${NC}"

# Execute installation steps
check_prerequisites
setup_directories
clone_repository

# Get the configuration directory path
CONFIG_DIR="/opt/piper/devops/config"

# Configure environment files
configure_env_files "$CONFIG_DIR"

# Set up Docker node labels
setup_node_labels

# Deploy the stack
log_info "Deploying the stack..."
cd /opt/piper/devops && make up

# Check stack status
log_info "Checking stack status..."
cd /opt/piper/devops && make status

# Run post-installation tasks
post_installation "$CONFIG_DIR"

log_info "=== Installation Complete ==="
log_info "The Piper stack has been deployed."