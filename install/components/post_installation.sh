#!/bin/bash
# Post-installation tasks

# Source utils
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/utils.sh"
source "$script_dir/wait_for_service.sh"

setup_seaweedfs() {
    log_warning "Configuring SeaweedFS buckets and S3 access..."
    
    # Get configuration directory path
    CONFIG_DIR="$(dirname "$(dirname "$script_dir")")/config"
    
    # Get stack name from swarm.env if available
    STACK_NAME="piper"
    if [ -f "$CONFIG_DIR/swarm.env" ]; then
        TEMP_STACK_NAME=$(grep "^SWARM_STACK_NAME=" "$CONFIG_DIR/swarm.env" | cut -d'=' -f2)
        if [ -n "$TEMP_STACK_NAME" ]; then
            STACK_NAME=$TEMP_STACK_NAME
        fi
    fi
    
    # Wait for SeaweedFS master service to be running
    log_info "Waiting for SeaweedFS master service to be running..."
    wait_for_service "$STACK_NAME" "seaweedfs-master" 300 5 || {
        log_error "SeaweedFS master service failed to start. Exiting."
        return 1
    }
    log_info "SeaweedFS master service is now running!"
    
    # Extract S3 keys from piper.env if it exists
    if [ -f "$CONFIG_DIR/piper.env" ]; then
        # Extract S3 keys from piper.env
        S3_ACCESS_KEY=$(grep "S3_ACCESS_KEY_ID" "$CONFIG_DIR/piper.env" | cut -d'=' -f2)
        S3_SECRET_KEY=$(grep "S3_SECRET_ACCESS_KEY" "$CONFIG_DIR/piper.env" | cut -d'=' -f2)
        
        if [ -n "$S3_ACCESS_KEY" ] && [ -n "$S3_SECRET_KEY" ]; then
            log_info "Found S3 credentials in piper.env, deploying configuration job..."
            
            # Deploy the configuration job with environment variables
            export S3_ACCESS_KEY=$S3_ACCESS_KEY
            export S3_SECRET_KEY=$S3_SECRET_KEY
            
            # Get stack name from swarm.env if available
            STACK_NAME="piper"
            if [ -f "$CONFIG_DIR/swarm.env" ]; then
                TEMP_STACK_NAME=$(grep "^SWARM_STACK_NAME=" "$CONFIG_DIR/swarm.env" | cut -d'=' -f2)
                if [ -n "$TEMP_STACK_NAME" ]; then
                    STACK_NAME=$TEMP_STACK_NAME
                fi
            fi
            
            COMPONENTS_DIR="$(dirname "$(dirname "$script_dir")")/components"
            docker stack deploy -c "$COMPONENTS_DIR/jobs/seaweedfs-config-job.yaml" ${STACK_NAME}
            
            # Wait a bit for the job to start
            log_info "SeaweedFS configuration job is running..."
            sleep 20 
        else
            log_warning "S3 credentials not found in piper.env, skipping S3 user configuration"
        fi
    else
        log_warning "piper.env file not found at $CONFIG_DIR/piper.env, skipping S3 user configuration"
    fi
    
    log_info "SeaweedFS buckets and S3 access configuration completed."
}

setup_mongodb() {
    log_warning "Initializing MongoDB collections for Piper..."
    
    # Get stack name from swarm.env if available
    CONFIG_DIR="$(dirname "$(dirname "$script_dir")")/config"
    STACK_NAME="piper"
    if [ -f "$CONFIG_DIR/swarm.env" ]; then
        TEMP_STACK_NAME=$(grep "^SWARM_STACK_NAME=" "$CONFIG_DIR/swarm.env" | cut -d'=' -f2)
        if [ -n "$TEMP_STACK_NAME" ]; then
            STACK_NAME=$TEMP_STACK_NAME
        fi
    fi
    
    # Wait for MongoDB service to be running
    log_info "Waiting for MongoDB service to be running..."
    wait_for_service "$STACK_NAME" "mongodb" 300 5 || {
        log_error "MongoDB service failed to start. Exiting."
        return 1
    }
    log_info "MongoDB service is now running!"
    
    COMPONENTS_DIR="$(dirname "$(dirname "$script_dir")")/components"
    log_info "Deploying MongoDB initialization job..."
    docker stack deploy -c "$COMPONENTS_DIR/jobs/mongo-init-job.yaml" ${STACK_NAME}
    
    # Wait a bit for the job to start
    log_info "MongoDB initialization job is running..."
    sleep 20
    
    log_info "MongoDB initialization completed."
}

create_admin() {
    log_warning "Creating admin user for Piper..."
    
    # Get configuration directory path
    CONFIG_DIR="$(dirname "$(dirname "$script_dir")")/config"
    
    # Check if piper.env exists and contains admin credentials
    if [ -f "$CONFIG_DIR/piper.env" ]; then
        ADMIN_EMAIL=$(grep "ADMIN_EMAIL" "$CONFIG_DIR/piper.env" | cut -d'=' -f2)
        ADMIN_PASSWORD=$(grep "ADMIN_PASSWORD" "$CONFIG_DIR/piper.env" | cut -d'=' -f2)
        
        if [ -n "$ADMIN_EMAIL" ] && [ -n "$ADMIN_PASSWORD" ]; then
            log_info "Found admin credentials in piper.env, deploying admin creation job..."
            
            # Get stack name from swarm.env if available
            STACK_NAME="piper"
            if [ -f "$CONFIG_DIR/swarm.env" ]; then
                TEMP_STACK_NAME=$(grep "^SWARM_STACK_NAME=" "$CONFIG_DIR/swarm.env" | cut -d'=' -f2)
                if [ -n "$TEMP_STACK_NAME" ]; then
                    STACK_NAME=$TEMP_STACK_NAME
                fi
            fi
            
            COMPONENTS_DIR="$(dirname "$(dirname "$script_dir")")/components"
            log_info "Deploying admin user creation job..."
            docker stack deploy -c "$COMPONENTS_DIR/jobs/admin-init-job.yaml" ${STACK_NAME}
            
            # Wait a bit for the job to start
            log_info "Admin user creation job is running..."
            sleep 20
            
            log_info "Admin user creation completed with email: $ADMIN_EMAIL"
        else
            log_warning "Admin credentials not found in piper.env, skipping admin user creation"
        fi
    else
        log_warning "piper.env file not found at $CONFIG_DIR/piper.env, skipping admin user creation"
    fi
    
    log_info "Admin user setup completed."
}

import_packages() {
    log_warning "Importing packages for Piper..."
    
    # Get configuration directory path
    CONFIG_DIR="$(dirname "$(dirname "$script_dir")")/config"
    
    # Get stack name from swarm.env if available
    STACK_NAME="piper"
    if [ -f "$CONFIG_DIR/swarm.env" ]; then
        TEMP_STACK_NAME=$(grep "^SWARM_STACK_NAME=" "$CONFIG_DIR/swarm.env" | cut -d'=' -f2)
        if [ -n "$TEMP_STACK_NAME" ]; then
            STACK_NAME=$TEMP_STACK_NAME
        fi
    fi
    
    COMPONENTS_DIR="$(dirname "$(dirname "$script_dir")")/components"
    log_info "Deploying package import job..."
    docker stack deploy -c "$COMPONENTS_DIR/jobs/package-import-job.yaml" ${STACK_NAME}
    
    # Wait a bit for the job to start
    log_info "Package import job is running..."
    sleep 20
    
    log_info "Package import completed."
}

import_pipelines() {
    log_warning "Importing pipelines for Piper..."
    
    # Get configuration directory path
    CONFIG_DIR="$(dirname "$(dirname "$script_dir")")/config"
    
    # Get stack name from swarm.env if available
    STACK_NAME="piper"
    if [ -f "$CONFIG_DIR/swarm.env" ]; then
        TEMP_STACK_NAME=$(grep "^SWARM_STACK_NAME=" "$CONFIG_DIR/swarm.env" | cut -d'=' -f2)
        if [ -n "$TEMP_STACK_NAME" ]; then
            STACK_NAME=$TEMP_STACK_NAME
        fi
    fi
    
    COMPONENTS_DIR="$(dirname "$(dirname "$script_dir")")/components"
    log_info "Deploying pipeline import job..."
    docker stack deploy -c "$COMPONENTS_DIR/jobs/pipeline-import-job.yaml" ${STACK_NAME}
    
    # Wait a bit for the job to start
    log_info "Pipeline import job is running..."
    sleep 20
    
    log_info "Pipeline import completed."
}

wait_for_piper_backend() {
    log_warning "Waiting for Piper backend service..."
    
    # Get configuration directory path
    CONFIG_DIR="$(dirname "$(dirname "$script_dir")")/config"
    
    # Get stack name from swarm.env if available
    STACK_NAME="piper"
    if [ -f "$CONFIG_DIR/swarm.env" ]; then
        TEMP_STACK_NAME=$(grep "^SWARM_STACK_NAME=" "$CONFIG_DIR/swarm.env" | cut -d'=' -f2)
        if [ -n "$TEMP_STACK_NAME" ]; then
            STACK_NAME=$TEMP_STACK_NAME
        fi
    fi
    
    # Wait for Piper backend service to be running
    log_info "Waiting for Piper backend service to be running..."
    wait_for_service "$STACK_NAME" "backend" 300 5 || {
        log_error "Piper backend service failed to start. Exiting."
        return 1
    }
    log_info "Piper backend service is now running!"
}

post_installation() {
    setup_seaweedfs
    setup_mongodb

    wait_for_piper_backend
    create_admin
    import_packages
    import_pipelines
}