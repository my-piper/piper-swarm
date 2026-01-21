#!/bin/bash
# Configure all environment files

# Source utils
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/utils.sh"

# Source individual env config scripts
source "$script_dir/env_configs/configure_swarm_env.sh"
source "$script_dir/env_configs/configure_piper_env.sh"
source "$script_dir/env_configs/configure_metrics_env.sh"
source "$script_dir/env_configs/configure_promtail_env.sh"

configure_env_files() {
    local config_dir="$1"
    
    log_info "Setting up environment configurations..."
    
    # Configure each environment file
    configure_swarm_env "$config_dir"
    configure_piper_env "$config_dir"
    configure_metrics_env "$config_dir"
    configure_promtail_env "$config_dir"
    
    log_info "All environment configurations completed."
}