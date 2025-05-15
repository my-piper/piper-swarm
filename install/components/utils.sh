#!/bin/bash
# Common utility functions for the installation scripts

# Color codes for better readability
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export RED='\033[0;31m'
export NC='\033[0m' # No Color

# Log messages with colors
log_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Generate a random string
generate_random_hex() {
    local length=${1:-16}
    openssl rand -hex $length
}

generate_random_password() {
    local length=${1:-16}
    openssl rand -base64 $length | tr -dc 'a-zA-Z0-9' | head -c $length
}

# Create a backup of a file
create_backup() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "${file}.backup"
        log_info "Created backup of ${file} as ${file}.backup"
    fi
}