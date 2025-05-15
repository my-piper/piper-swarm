#!/bin/bash
# Configure promtail configuration files

# Source utils
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
source "$script_dir/utils.sh"

configure_promtail_env() {
    local config_dir="$1"
    
    if [ ! -f "$config_dir/promtail/config.env" ]; then
        log_warning "Creating promtail/config.env file..."
        cp "$config_dir/promtail/config.env.template" "$config_dir/promtail/config.env"
        log_info "promtail/config.env configured."
    else
        log_info "promtail/config.env already exists."
    fi
}
