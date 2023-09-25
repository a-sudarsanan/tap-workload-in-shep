#!/usr/local/bin/bash
set -e
set -o pipefail
# Check if both test_bed_id and namespace are provided as command-line arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <TAP test_bed_id> <namespace>"
    exit 1
fi

test_bed_id="$1"
namespace="$2"

# Define a function to perform prechecks (Shepherd and Tanzu version checks)
precheck() {
    echo "Performing prechecks..."
    
    # Shepherd version check
    shepherd version

    # Tanzu version check
    tanzu version
}

# Define a function to get Shepherd config
get_shepherd_config() {
    echo "Getting Shepherd config..."
    shepherd get lease $1 -n $2 --json | jq -r .output.kubeconfig > kubeconfig.yml
}

# Define a function to export variables
export_variables() {
    echo "Validating shepherd outputs..."
    export KUBECONFIG=kubeconfig.yml
    export registry_server=$(shepherd get lease $1 -n $2 --json | jq -r .output.registry.url | cut -d'/' -f1)
    export registry_username=$(shepherd get lease $1 -n $2 --json | jq -r .output.registry.user.username)
    export registry_password=$(shepherd get lease $1 -n $2 --json | jq -r .output.registry.user.password)
    export tap_gui_url=$(shepherd get lease $1 -n $2 --json | jq -r .output.tap_gui_url)
    export registry_ca_cert=$(shepherd get lease $1 -n $2 --json | jq -r .output.registry.ca_certificate)

    # Check if registry_ca_cert is not equal to JSON null
    if [ "$registry_ca_cert" != "null" ]; then
        # If it's not equal to null, set apply_workaround to true
        export apply_workaround=true
    else
        # If it's equal to null, set apply_workaround to false (optional)
        export apply_workaround=false
    fi

    echo "Variables exported:"
    echo "KUBECONFIG: $KUBECONFIG"
    echo "registry_server: $registry_server"
    echo "registry_username: $registry_username"
    echo "registry_password: $registry_password"
    echo "tap_gui_url: $tap_gui_url"
    echo "registry_ca_cert: $registry_ca_cert"
    echo "apply_workaround: $apply_workaround"
}

# Define a function to prepare Tanzu CLI
prepare_tanzu_cli() {
    echo "Preparing Tanzu CLI..."
    tanzu version
    tanzu config set env.TANZU_CLI_SUPERCOLLIDER_ENVIRONMENT staging
    tanzu config set env.TANZU_CLI_ADDITIONAL_PLUGIN_DISCOVERY_IMAGES_TEST_ONLY harbor-repo.vmware.com/tanzu_cli/plugins/sandbox/tap/plugin-inventory:latest,projects.registry.vmware.com/tanzu_cli_stage/plugins/plugin-inventory:latest,projects.registry.vmware.com/tanzu_cli/plugins/plugin-inventory:latest
    tanzu config set env.TANZU_CLI_ADDITIONAL_PLUGIN_DISCOVERY_IMAGES_TEST_ONLY harbor-repo.vmware.com/tanzu_cli/plugins/sandbox/tap/plugin-inventory:latest,projects.registry.vmware.com/tanzu_cli_stage/plugins/plugin-inventory:latest,projects.registry.vmware.com/tanzu_cli/plugins/plugin-inventory:latest
    tanzu plugin group search --show-details
    tanzu plugin install --group vmware-tap/default:v1.7.0-build.19
    tanzu plugin list
}

# Define a function to add secrets
add_secrets() {
    echo "Adding secrets..."
    tanzu package installed list -A
    tanzu secret registry add registry-credentials -n my-apps --server $1 --username $2 --password $3
    tanzu secret registry list -n my-apps
}

# Define a function to apply prerequisites (will move to a GitHub repo)
apply_prerequisites() {
    echo "Applying prerequisites..."
    kubectl apply -f https://raw.githubusercontent.com/a-sudarsanan/tap-workload-in-shep/main/ScanPolicy.yml -n my-apps
    kubectl apply -f https://raw.githubusercontent.com/a-sudarsanan/tap-workload-in-shep/main/Pipeline.yml -n my-apps
    kubectl apply -f https://raw.githubusercontent.com/a-sudarsanan/tap-workload-in-shep/main/dev-namespace.yml -n my-apps

    if [[ $apply_workaround = true ]]; then
        echo "Applying workaround..."
        cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: registry-ca
  namespace: kube-system
type: Opaque
data:
  registry-ca: $(echo -n "$registry_ca_cert" | base64)
EOF
        kubectl apply -f https://raw.githubusercontent.com/a-sudarsanan/tap-workload-in-shep/main/eks-workaround/daemon-set.yml
    else
        echo "No workaround needed, not applying anything."
    fi
}

# Define a function to create the workload
create_workload() {
    echo "Creating workload..."
    tanzu apps workload apply tanzu-java-web-app --git-branch main --git-repo https://github.com/mdc81/tanzu-java-web-app --type web --yes -n my-apps  --label app.kubernetes.io/part-of=tanzu-java-web-app --label apps.tanzu.vmware.com/has-tests=true
}

# Define a function to validate the workload
validate_workload() {
    echo "Validating workload..."
    sleep 60
    until=true
    while $until; do
        sleep 5
        output=$(tanzu apps workload get tanzu-java-web-app --namespace my-apps)
        tanzu apps workload get tanzu-java-web-app --namespace my-apps
        if ! echo "$output" | grep -Eq "False|Unknown"; then
            until=false
        fi
    done
    sleep 20
    echo "Trying to access the workloads.."
    curl -k https://$(kubectl get httpproxy -n my-apps | grep my-apps/route | awk '{print $2}')
    echo "Workload can be accessed thorugh: https://$(kubectl get httpproxy -n my-apps | grep my-apps/route | awk '{print $2}')"
    echo "TAP GUI can be accessed through: $tap_gui_url"
}

#invoke precheck
precheck
echo 
# Get Shepherd config
get_shepherd_config $test_bed_id $namespace
echo
# Export variables
export_variables $test_bed_id $namespace
echo
# Prepare Tanzu CLI
prepare_tanzu_cli
echo
# Add secrets
add_secrets $registry_server $registry_username $registry_password
echo
# Apply prerequisites
apply_prerequisites
echo
# Create workload
create_workload
echo
validate_workload
