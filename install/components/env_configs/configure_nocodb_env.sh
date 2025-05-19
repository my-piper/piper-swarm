#!/bin/bash
# Configure nocodb.env file

# Source utils
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
source "$script_dir/utils.sh"

configure_nocodb_env() {
    local config_dir="$1"
    
    if [ ! -f "$config_dir/nocodb.env" ]; then
        log_warning "Creating nocodb.env file..."
        cp "$config_dir/nocodb.env.template" "$config_dir/nocodb.env"
        
        # Generate a random JWT secret for NocoDB
        nocodb_jwt_secret=$(generate_random_hex 32)
        
        # Update JWT secret in nocodb.env
        sed -i "s|NC_AUTH_JWT_SECRET=<auto generate>|NC_AUTH_JWT_SECRET=$nocodb_jwt_secret|" "$config_dir/nocodb.env"
        
        # Get domain from swarm.env
        if [ -f "$config_dir/swarm.env" ]; then
            domain=$(grep "^DOMAIN=" "$config_dir/swarm.env" | cut -d'=' -f2)
            if [ -n "$domain" ] && [ "$domain" != "?" ]; then
                # Update public URL using domain
                public_url="https://$domain/nocodb"
                sed -i "s|^NC_PUBLIC_URL=.*$|NC_PUBLIC_URL=$public_url|" "$config_dir/nocodb.env"
                log_info "NocoDB public URL set to: $public_url"
            else
                log_warning "Domain not found in swarm.env, NocoDB public URL not set properly."
                # Fallback to manual input if needed
                read -p "Enter NocoDB public URL (e.g., https://example.com/nocodb): " public_url
                sed -i "s|^NC_PUBLIC_URL=.*$|NC_PUBLIC_URL=$public_url|" "$config_dir/nocodb.env"
            fi
        else
            log_warning "swarm.env file not found, NocoDB public URL not set properly."
            # Fallback to manual input
            read -p "Enter NocoDB public URL (e.g., https://example.com/nocodb): " public_url
            sed -i "s|^NC_PUBLIC_URL=.*$|NC_PUBLIC_URL=$public_url|" "$config_dir/nocodb.env"
        fi
        
        # Read postgres password from postgres.env
        if [ -f "$config_dir/postgres.env" ]; then
            pg_password=$(grep "^POSTGRES_PASSWORD=" "$config_dir/postgres.env" | cut -d'=' -f2)
            if [ -n "$pg_password" ]; then
                # First reset the NC_DB value to ensure we're starting with a clean state
                sed -i "s|^NC_DB=.*$|NC_DB=pg://postgres:5432?u=postgres\&p=$pg_password\&d=nocodb|" "$config_dir/nocodb.env"
                log_info "NocoDB configured to use the PostgreSQL database."
            else
                log_warning "Postgres password not found in postgres.env, using default configuration."
            fi
        else
            log_warning "postgres.env file not found, using default configuration."
        fi
        
        log_info "nocodb.env configured successfully."
    else
        log_info "nocodb.env already exists."
    fi
}
