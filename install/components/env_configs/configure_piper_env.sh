#!/bin/bash
# Configure piper.env file

# Source utils
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
source "$script_dir/utils.sh"

configure_piper_env() {
    local config_dir="$1"
    
    if [ ! -f "$config_dir/piper.env" ]; then
        log_warning "Creating piper.env file..."
        cp "$config_dir/piper.env.template" "$config_dir/piper.env"
        
        # Generate a random JWT secret
        jwt_secret=$(generate_random_hex 32)
        
        # Update the piper.env file
        sed -i "s/JWT_SECRET=xyzXYZ/JWT_SECRET=$jwt_secret/" "$config_dir/piper.env"
        
        # Set storage URL
        read -p "Enter storage base URL: " storage_url
        sed -i "s|STORAGE_BASE_URL=https://xyz.com/storage|STORAGE_BASE_URL=$storage_url|" "$config_dir/piper.env"
        
        log_info "piper.env configured. You may need to update OAuth credentials manually."
    else
        log_info "piper.env already exists."
    fi
}
