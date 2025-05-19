#!/bin/bash
# Configure postgres.env file

# Source utils
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
source "$script_dir/utils.sh"

configure_postgres_env() {
    local config_dir="$1"
    
    if [ ! -f "$config_dir/postgres.env" ]; then
        log_warning "Creating postgres.env file..."
        cp "$config_dir/postgres.env.template" "$config_dir/postgres.env"
        
        # Generate a random Postgres password
        pg_password=$(generate_random_password 16)
        
        # Update the postgres.env file
        sed -i "s/<auto generate>/$pg_password/" "$config_dir/postgres.env"
        log_info "postgres.env configured with secure password."
    else
        log_info "postgres.env already exists."
    fi
}
