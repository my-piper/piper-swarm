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
        nocodb_jwt_secret=$(generate_random_hex 16)
        
        # Update JWT secret in nocodb.env
        sed -i "s/NC_AUTH_JWT_SECRET=xyzXYZ/NC_AUTH_JWT_SECRET=$nocodb_jwt_secret/" "$config_dir/nocodb.env"
        
        # Generate dedicated PostgreSQL user for NocoDB
        pg_nocodb_user="nocodb_user_$(generate_random_hex 4)"
        pg_nocodb_password=$(generate_random_password 16)
        
        log_info "Generated dedicated PostgreSQL user for NocoDB: $pg_nocodb_user"
        
        # Update the database connection string in nocodb.env
        sed -i "s|NC_DB=pg://postgres:5432?u=postgres&p=xyzXYZ&d=nocodb|NC_DB=pg://postgres:5432?u=$pg_nocodb_user&p=$pg_nocodb_password&d=nocodb|" "$config_dir/nocodb.env"
        
        log_info "nocodb.env configured with dedicated database user."
        
        # Save PostgreSQL credentials for later use
        echo "PG_NOCODB_USER=$pg_nocodb_user" > "$config_dir/.pg_nocodb_credentials"
        echo "PG_NOCODB_PASSWORD=$pg_nocodb_password" >> "$config_dir/.pg_nocodb_credentials"
        chmod 600 "$config_dir/.pg_nocodb_credentials"
    else
        log_info "nocodb.env already exists."
    fi
}
