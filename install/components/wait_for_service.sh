#!/bin/bash
# Script to wait for a service to be running in Docker Swarm

# Source utils
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/utils.sh"

# Function to check if service is running
is_service_running() {
    local stack_name="$1"
    local service_name="$2"
    local full_service_name="${stack_name}_${service_name}"
    
    # Use a more precise approach to ensure exact name match
    # Get all services and filter with grep for exact service name
    running_replicas=$(docker service ls --format "{{.Name}} {{.Replicas}}" | grep "^${full_service_name} " | awk '{print $2}' | grep -E '[0-9]+/[0-9]+' | cut -d'/' -f1)

    echo "Running replicas: [$running_replicas]"
    
    if [ -z "$running_replicas" ]; then
        # Service doesn't exist or has no replicas defined
        return 1
    fi
    
    # Check if running replicas is greater than 0
    if [ "$running_replicas" -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

# Wait for a specific service to be running
wait_for_service() {
    local stack_name="$1"
    local service_name="$2"
    local timeout="${3:-300}"  # Default timeout 300 seconds (5 minutes)
    local interval="${4:-5}"   # Default check interval 5 seconds
    
    log_info "Waiting for service ${stack_name}_${service_name} to be running..."
    
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if is_service_running "$stack_name" "$service_name"; then
            log_info "Service ${stack_name}_${service_name} is now running!"
            return 0
        fi
        
        log_info "Service ${stack_name}_${service_name} is not ready yet. Waiting ${interval} seconds..."
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    log_error "Timeout reached. Service ${stack_name}_${service_name} did not start within ${timeout} seconds."
    return 1
}

# Wait for multiple services to be running
wait_for_services() {
    local stack_name="$1"
    local services=("${@:2}")
    local timeout="${services[-1]}"
    local interval="${services[-2]}"
    
    # Check if last arguments are numbers (timeout and interval)
    if [[ "$timeout" =~ ^[0-9]+$ ]] && [[ "$interval" =~ ^[0-9]+$ ]]; then
        # Remove timeout and interval from services array
        unset 'services[${#services[@]}-1]'
        unset 'services[${#services[@]}-1]'
    else
        # Use default values
        timeout=300
        interval=5
    fi
    
    log_info "Waiting for multiple services in stack ${stack_name} to be running..."
    
    for service in "${services[@]}"; do
        wait_for_service "$stack_name" "$service" "$timeout" "$interval" || return 1
    done
    
    log_info "All requested services are now running!"
    return 0
}

# Function to wait for health check to pass for a service
wait_for_service_health() {
    local stack_name="$1"
    local service_name="$2"
    local timeout="${3:-300}"  # Default timeout 300 seconds (5 minutes)
    local interval="${4:-5}"   # Default check interval 5 seconds
    local full_service_name="${stack_name}_${service_name}"
    
    log_info "Waiting for service ${full_service_name} to be healthy..."
    
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        # First check if service is running
        if ! is_service_running "$stack_name" "$service_name"; then
            log_info "Service ${full_service_name} is not running yet. Waiting ${interval} seconds..."
            sleep $interval
            elapsed=$((elapsed + interval))
            continue
        fi
        
        # Get container IDs for the service
        container_ids=$(docker ps --filter "name=${full_service_name}" --format "{{.ID}}")
        
        if [ -z "$container_ids" ]; then
            log_info "No containers found for service ${full_service_name}. Waiting ${interval} seconds..."
            sleep $interval
            elapsed=$((elapsed + interval))
            continue
        fi
        
        # Check if all containers are healthy
        all_healthy=true
        for container_id in $container_ids; do
            health_status=$(docker inspect --format "{{.State.Health.Status}}" "$container_id" 2>/dev/null)
            
            # If container doesn't have a health check, assume it's healthy
            if [ -z "$health_status" ]; then
                continue
            fi
            
            if [ "$health_status" != "healthy" ]; then
                all_healthy=false
                break
            fi
        done
        
        if [ "$all_healthy" = true ]; then
            log_info "Service ${full_service_name} is healthy!"
            return 0
        fi
        
        log_info "Service ${full_service_name} is running but not yet healthy. Waiting ${interval} seconds..."
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    log_error "Timeout reached. Service ${full_service_name} did not become healthy within ${timeout} seconds."
    return 1
}

# Check if script is being sourced or executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # If script is run directly, show usage
    if [ "$#" -lt 2 ]; then
        echo "Usage: $0 <stack_name> <service_name> [timeout_seconds] [interval_seconds]"
        echo "Example: $0 piper backend 300 5"
        exit 1
    fi
    
    # Execute the main function
    wait_for_service "$@"
fi
