#!/bin/bash
# Configure metrics configuration files

# Source utils
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
source "$script_dir/utils.sh"

configure_metrics_env() {
    local config_dir="$1"
    
    if [ ! -f "$config_dir/metrics/config.env" ]; then
        log_warning "Creating metrics/config.env file..."
        cp "$config_dir/metrics/config.env.template" "$config_dir/metrics/config.env"
        log_info "metrics/config.env configured."
    else
        log_info "metrics/config.env already exists."
    fi
}
