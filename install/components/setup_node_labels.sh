#!/bin/bash
# Set up Docker node labels

# Source utils
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/utils.sh"

setup_node_labels() {
    log_info "Setting up Docker node labels..."
    
    # Get the first node name
    node_name=$(docker node ls --format '{{.Hostname}}' | head -n 1)
    
    # Add the piper-worker label
    docker node update --label-add piper-worker=true $node_name
    
    log_info "Added 'piper-worker=true' label to node $node_name"
}