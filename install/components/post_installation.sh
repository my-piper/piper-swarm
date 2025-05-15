#!/bin/bash
# Post-installation tasks

# Source utils
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/utils.sh"

create_postgres_user() {
    local config_dir="$1"
    
    if [ -f "$config_dir/.pg_nocodb_credentials" ]; then
        log_warning "Setting up dedicated PostgreSQL user for NocoDB..."
        # Source the credentials
        source "$config_dir/.pg_nocodb_credentials"
        
        # Wait a moment for PostgreSQL to initialize
        log_warning "Waiting for PostgreSQL to initialize..."
        sleep 10
        
        # Find the PostgreSQL container
        PG_CONTAINER=$(docker ps --filter name=piper_postgres --format "{{.ID}}")
        
        if [ -n "$PG_CONTAINER" ]; then
            log_info "Found PostgreSQL container: $PG_CONTAINER"
            
            # Try to create the user with retries
            max_retries=5
            retry_count=0
            
            while [ $retry_count -lt $max_retries ]; do
                log_warning "Attempting to create PostgreSQL user (attempt $(($retry_count+1))/${max_retries})..."
                
                if docker exec -i $PG_CONTAINER psql -U postgres -d nocodb << EOF
CREATE USER $PG_NOCODB_USER WITH PASSWORD '$PG_NOCODB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE nocodb TO $PG_NOCODB_USER;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $PG_NOCODB_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $PG_NOCODB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO $PG_NOCODB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO $PG_NOCODB_USER;
EOF
                then
                    log_info "PostgreSQL user created successfully."
                    
                    # Update the NocoDB service to apply the new configuration
                    log_warning "Updating NocoDB service to apply new database configuration..."
                    docker service update --force piper_nocodb
                    
                    # Remove credentials file
                    rm "$config_dir/.pg_nocodb_credentials"
                    
                    break
                else
                    retry_count=$((retry_count+1))
                    if [ $retry_count -lt $max_retries ]; then
                        log_warning "Failed to create user. Retrying in 10 seconds..."
                        sleep 10
                    else
                        log_warning "Failed to create PostgreSQL user after ${max_retries} attempts."
                        log_warning "You may need to manually create the user with these credentials:"
                        log_info "Username: $PG_NOCODB_USER"
                        log_info "Password: $PG_NOCODB_PASSWORD"
                    fi
                fi
            done
        else
            log_warning "PostgreSQL container not found. You may need to manually create the database user."
            log_info "Username: $PG_NOCODB_USER"
            log_info "Password: $PG_NOCODB_PASSWORD"
        fi
    fi
}

setup_seaweedfs() {
    log_warning "Configuring SeaweedFS buckets and S3 access..."
    # Find the SeaweedFS container
    SEAWEED_CONTAINER=$(docker ps --filter name=piper_seaweedfs --format "{{.ID}}")
    if [ -z "$SEAWEED_CONTAINER" ]; then
        log_warning "SeaweedFS container not found. Skipping automatic configuration."
        return
    fi
    # Run configuration commands inside the container
    docker exec -i $SEAWEED_CONTAINER weed shell << EOF
fs.configure -locationPrefix=/buckets/artefacts/ -ttl=1d -volumeGrowthCount=1 -replication=000 -apply
fs.configure -locationPrefix=/buckets/launches/ -ttl=14d -volumeGrowthCount=1 -replication=000 -apply
fs.configure -locationPrefix=/buckets/assets/ -volumeGrowthCount=1 -replication=000 -apply
s3.configure -user=anonymous -actions=Read:artefacts,Read:launches,Read:assets -apply
EOF
    # Optionally, you can set up a secure S3 user here if you have access/secret keys
    # Example (replace with real values or generate securely):
    # docker exec -i $SEAWEED_CONTAINER weed shell << EOF
    # s3.configure -access_key=YOUR_ACCESS_KEY -secret_key=YOUR_SECRET_KEY -user=piper -actions=Read,Write -apply
    # EOF
    log_info "SeaweedFS buckets and S3 access configured."
}


post_installation() {
    local config_dir="$1"
    # Create PostgreSQL user for NocoDB
    create_postgres_user "$config_dir"
    # Automatically configure SeaweedFS (now in components/installation)
    setup_seaweedfs
}