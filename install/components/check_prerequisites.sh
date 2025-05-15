#!/bin/bash
# Check prerequisites for the Piper stack installation

# Source utils
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/utils.sh"

check_prerequisites() {
    log_info "Checking prerequisites for installation..."

    # Check if Docker is installed
    if ! command_exists docker; then
        log_error "Docker is not installed. Please install Docker and Docker Swarm before running this script."
        exit 1
    else
        log_info "Docker is installed."
    fi

    # Check if Docker Swarm is initialized
    if ! docker info | grep -q "Swarm: active"; then
        log_warning "Docker Swarm is not initialized. Initializing now..."
        docker swarm init
        log_info "Docker Swarm initialized successfully."
    else
        log_info "Docker Swarm is already initialized."
    fi

    # Check if make is installed
    if ! command_exists make; then
        log_warning "make is not installed. Installing now..."
        if command_exists apt-get; then
            apt-get update && apt-get install -y make
        elif command_exists yum; then
            yum install -y make
        elif command_exists apk; then
            apk add make
        else
            log_error "Could not install make. Please install it manually."
            exit 1
        fi
        log_info "make installed successfully."
    else
        log_info "make is installed."
    fi

    # Check if git is installed
    if ! command_exists git; then
        log_error "git is not installed. Please install git before running this script."
        exit 1
    else
        log_info "git is installed."
    fi

    # Check if openssl is installed
    if ! command_exists openssl; then
        log_error "openssl is not installed. Please install openssl before running this script."
        exit 1
    else
        log_info "openssl is installed."
    fi

    log_info "All prerequisites checked."
}