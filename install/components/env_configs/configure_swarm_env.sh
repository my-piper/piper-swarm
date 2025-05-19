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
        
        # Prompt for domain
        read -p "Enter domain name for deployment: " domain
        
        # Update the swarm.env file
        sed -i "s/PIPER_IMAGE_TAG=?/PIPER_IMAGE_TAG=$piper_tag/" "$config_dir/swarm.env"
        sed -i "s/DOMAIN=?/DOMAIN=$domain/" "$config_dir/swarm.env"
        
        # Ask if user wants to customize SeaweedFS volume locations
        read -p "Do you want to customize SeaweedFS volume locations? (y/N): " customize_volumes
        if [[ "$customize_volumes" =~ ^[Yy]$ ]]; then
            log_warning "You will be prompted for SeaweedFS volume locations."
            
            # Prompt for volume locations with defaults
            read -p "Enter path for SeaweedFS volume 1 (default: use Docker volume): " volume_1_path
            read -p "Enter path for SeaweedFS volume 2 (default: use Docker volume): " volume_2_path
            read -p "Enter path for SeaweedFS volume 3 (default: use Docker volume): " volume_3_path
            
            # Add a blank line before adding custom configurations
            echo "" >> "$config_dir/swarm.env"
            
            # Add the volume paths to swarm.env if provided
            if [ -n "$volume_1_path" ]; then
                echo "SEAWEEDFS_VOLUME_1_DATA_DIR=$volume_1_path" >> "$config_dir/swarm.env"
            fi
            
            if [ -n "$volume_2_path" ]; then
                echo "SEAWEEDFS_VOLUME_2_DATA_DIR=$volume_2_path" >> "$config_dir/swarm.env"
            fi
            
            if [ -n "$volume_3_path" ]; then
                echo "SEAWEEDFS_VOLUME_3_DATA_DIR=$volume_3_path" >> "$config_dir/swarm.env"
            fi
            
            log_info "SeaweedFS volume locations configured."
        else
            log_info "Using default Docker volumes for SeaweedFS."
        fi
        
        log_info "swarm.env configured with image tag, domain, and volume settings."
    else
        log_info "swarm.env already exists."
    fi
}