#!/bin/bash
# Main installation script for Piper stack

set -e

# Determine script directory
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all component scripts
source "$INSTALL_DIR/components/check_prerequisites.sh"
source "$INSTALL_DIR/components/setup_directories.sh"
source "$INSTALL_DIR/components/clone_repository.sh"
source "$INSTALL_DIR/components/configure_env_files.sh"
source "$INSTALL_DIR/components/setup_node_labels.sh"
source "$INSTALL_DIR/components/post_installation.sh"


# Display banner
echo -e "${GREEN}=== Piper Stack Installation Script ===${NC}"
echo -e "${YELLOW}This script will install and configure the Piper stack${NC}"

# Execute installation steps
check_prerequisites
# setup_directories
# clone_repository

# Get the configuration directory path
CONFIG_DIR="$(dirname "$INSTALL_DIR")/config"

# # Configure environment files
# configure_env_files "$CONFIG_DIR"

# # Set up Docker node labels
# setup_node_labels

# # Deploy the stack
# log_info "Deploying the stack..."
# make up

# # Check stack status
# log_info "Checking stack status..."
# make status

# Run post-installation tasks
post_installation

log_info "=== Installation Complete ==="
log_info "The Piper stack has been deployed."