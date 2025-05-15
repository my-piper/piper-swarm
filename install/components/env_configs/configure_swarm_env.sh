#!/bin/bash
# Configure swarm.env file

# Source utils
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
source "$script_dir/utils.sh"

configure_swarm_env() {
    local config_dir="$1"
    
    if [ ! -f "$config_dir/swarm.env" ]; then
        log_warning "Creating swarm.env file..."
        cp "$config_dir/swarm.env.template" "$config_dir/swarm.env"
        
        # Prompt for Piper image tag
        read -p "Enter Piper image tag (default: latest): " piper_tag
        piper_tag=${piper_tag:-latest}
        
        # Update the swarm.env file
        sed -i "s/PIPER_IMAGE_TAG=?/PIPER_IMAGE_TAG=$piper_tag/" "$config_dir/swarm.env"
        log_info "swarm.env configured."
    else
        log_info "swarm.env already exists."
    fi
}