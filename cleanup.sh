#!/usr/bin/env bash

# Check if both test_bed_id and namespace are provided as command-line arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <TAP test_bed_id> <namespace>"
    exit 1
fi

test_bed_id="$1"
namespace="$2"

# Function to get Shepherd Kubernetes config and export it
get_shepherd_kubeconfig() {
    echo "Getting Shepherd Kubernetes config and exporting it..."
    
    # Shepherd command to get Kubernetes config
    shepherd get lease "$test_bed_id" -n "$namespace" --json | jq -r .output.kubeconfig > kubeconfig.yml
    export KUBECONFIG=kubeconfig.yml
    
    echo "KUBECONFIG environment variable set to kubeconfig.yml"
}

# Function to clean up resources
cleanup() {
    echo "Cleaning up resources..."
    
    # Delete workload
    tanzu apps workload delete tanzu-java-web-app -n my-apps -y
    
    # Delete registry secret
    tanzu secret registry delete registry-credentials -n my-apps -y 
    
    # Unset KUBECONFIG
    unset KUBECONFIG
    
    # Remove kubeconfig file
    rm kubeconfig.yml
    
    echo "Cleanup complete."
}

# Main script starts here; no need to read test_bed_id and namespace from users
# They are provided as command-line arguments

# Get Shepherd Kubernetes config and export it
get_shepherd_kubeconfig

# Perform cleanup
cleanup
