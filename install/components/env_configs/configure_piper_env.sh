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
        
        # Generate random secrets
        jwt_secret=$(generate_random_hex 32)
        redis_secret=$(generate_random_hex 16)
        s3_access_key=$(generate_random_hex 16)
        s3_secret_key=$(generate_random_hex 16)
        
        # Update the piper.env file with generated secrets
        sed -i "s/JWT_SECRET=<auto generate>/JWT_SECRET=$jwt_secret/" "$config_dir/piper.env"
        sed -i "s/REDIS_SECRET_KEY=<auto generate>/REDIS_SECRET_KEY=$redis_secret/" "$config_dir/piper.env"
        sed -i "s/S3_ACCESS_KEY_ID=<auto generate>/S3_ACCESS_KEY_ID=$s3_access_key/" "$config_dir/piper.env"
        sed -i "s/S3_SECRET_ACCESS_KEY=<auto generate>/S3_SECRET_ACCESS_KEY=$s3_secret_key/" "$config_dir/piper.env"
        
        # Get domain from swarm.env and format URLs
        if [ -f "$config_dir/swarm.env" ]; then
            domain=$(grep "^DOMAIN=" "$config_dir/swarm.env" | cut -d'=' -f2)
            if [ -n "$domain" ] && [ "$domain" != "?" ]; then
                base_url="https://$domain"
                s3_base_url="https://$domain/storage"
                log_info "Using domain from swarm.env: $domain"
            else
                # Fallback to manual input if domain not set in swarm.env
                log_warning "Domain not found in swarm.env, please enter URLs manually."
                read -p "Enter base URL (e.g., https://piper.example.com): " base_url
                read -p "Enter S3 base URL (e.g., https://piper.example.com/storage): " s3_base_url
            fi
        else
            # Fallback to manual input if swarm.env doesn't exist
            log_warning "swarm.env file not found, please enter URLs manually."
            read -p "Enter base URL (e.g., https://piper.example.com): " base_url
            read -p "Enter S3 base URL (e.g., https://piper.example.com/storage): " s3_base_url
        fi
        
        sed -i "s|^BASE_URL=.*$|BASE_URL=$base_url|" "$config_dir/piper.env"
        sed -i "s|^S3_BASE_URL=.*$|S3_BASE_URL=$s3_base_url|" "$config_dir/piper.env"
        log_info "URLs configured: BASE_URL=$base_url, S3_BASE_URL=$s3_base_url"
        
        log_info "piper.env configured successfully with random secrets and URLs."
    else
        log_info "piper.env already exists."
    fi
}
