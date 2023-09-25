## Who is this script for?
You can use this script to test if the basic tanzu-java-web-app workloads can be created on the shepherd TAP test-bed that you have created.
Workload repo:  https://github.com/mdc81/tanzu-java-web-app

## Requirements

### Shepehrd TAP test-beds
https://gitlab.eng.vmware.com/shepherd/shepherd2/-/wikis/TAP-Bug-Bash#shepherd-v2-cli-installation

### shepherd-v2
latest shepherd cli that can be installed from here: https://gitlab.eng.vmware.com/shepherd/shepherd2/-/blob/main/documentation/public-docs/how-tos/quickstart.md#update

### tanzu-cli (linux)

```bash
mkdir -p /etc/apt/keyrings/
apt-get update
apt-get install -y ca-certificates curl gpg
curl -fsSL https://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub | gpg --dearmor -o /etc/apt/keyrings/tanzu-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/tanzu-archive-keyring.gpg] https://storage.googleapis.com/tanzu-cli-os-packages/apt tanzu-cli-jessie main" | tee /etc/apt/sources.list.d/tanzu.list
apt-get update
apt-get install -y tanzu-cli
tanzu version
```

## How to use this script?
```bash
curl -sSL https://raw.githubusercontent.com/a-sudarsanan/tap-workload-in-shep/main/workload-validate.sh | bash -s <tap sheperd test-bed-id> <namespace>
```

`Example`
```bash
curl -sSL https://raw.githubusercontent.com/a-sudarsanan/tap-workload-in-shep/main/workload-validate.sh | bash -s 101c8c41-bc0f-4c25-a2b8-c30443bc0770 asudarsanan
```

or 

```sh
git clone https://github.com/a-sudarsanan/tap-workload-in-shep.git

cd tap-worload-in-shep

chmod +x workload-validate.sh

./workload-validate.sh <test-bed-name> <namespace>
```