#!/bin/bash
# Clone the Piper repository

# Source utils
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/utils.sh"

clone_repository() {
    # Check if we're already in the devops directory
    if [ "$(basename $(pwd))" != "devops" ] || [ "$(dirname $(pwd))" != "/opt/piper" ]; then
        log_warning "Changing to /opt/piper directory..."
        cd /opt/piper
        
        # Check if the devops directory already exists
        if [ -d "./devops" ]; then
            log_warning "Devops directory already exists. Pulling latest changes..."
            cd devops
            git pull
        else
            log_info "Cloning repository..."
            git config --global credential.helper store
            git clone https://github.com/my-piper/piper-swarm.git ./devops
            cd devops
        fi
    else
        log_info "Already in the devops directory."
    fi
}