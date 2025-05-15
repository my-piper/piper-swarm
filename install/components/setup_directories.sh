#!/bin/bash
# Set up directories for the Piper stack installation

# Source utils
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/utils.sh"

setup_directories() {
    log_info "Creating directories..."
    
    # Create main directory
    mkdir -p /opt/piper
    
    log_info "Directories created successfully."
}