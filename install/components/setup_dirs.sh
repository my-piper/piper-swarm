#!/bin/bash
# Create required host directories before deploying the stack

setup_dirs() {
    log_info "Setting up required host directories..."

    local dirs=(
        "/var/backups/piper/clickhouse"
    )

    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_info "Created directory: $dir"
        else
            log_info "Directory already exists: $dir"
        fi
    done
}
