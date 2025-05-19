#!/bin/bash
# Post-installation tasks

# Source utils
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/utils.sh"

setup_seaweedfs() {
    log_warning "Configuring SeaweedFS buckets and S3 access..."
    
    # Get configuration directory path
    CONFIG_DIR="$(dirname "$(dirname "$script_dir")")/config"
    
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


post_installation() {
    setup_seaweedfs
}