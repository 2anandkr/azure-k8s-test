#!/usr/bin/env bash

# capture arg. to select a particular VM to boot
if [ -z "$1" ]; then
  VM=0
else
  VM=$1
fi

# Get Relative Path
THIS_DIR=$(dirname "$0")
# load reusabe functions
source $THIS_DIR/scripts/utility_functions.sh

ISTIO_SETUP=$THIS_DIR/istio-setup

echo ""
echo "authorize cluster access..."
az aks get-credentials --resource-group index-poc --name index-poc-aks

echo "install istio operator..."
istioctl operator init

echo ""
echo "install istio..."
istioctl install -y -f $ISTIO_SETUP/istio-config.yaml

echo ""
echo "boot eastwest gateway..."
$ISTIO_SETUP/gen-eastwest-gateway.sh --single-cluster | istioctl install -y -f -

echo ""
echo "Expose services inside the cluster via the east-west gateway..."
kubectl apply -f $ISTIO_SETUP/expose-istiod.yaml

echo ""
echo "Configure the VM namespace and service account..."
kubectl create namespace vm
kubectl create serviceaccount vm-access -n vm

echo ""
echo "generate files for vm..."
istioctl x workload entry configure -f $THIS_DIR/vm-test3/app2-workloadgroup.yaml -o "vm-files" --clusterID "Kubernetes"

echo ""
echo "install tools in vm..."

ssh $(get_vm_ssh_args $VM) "$( cat << EOF
sudo apt-get update && sudo apt-get install -y rsync nginx

EOF
)"

echo ""
echo "transfer files to vm..."
rsync --verbose  --archive --checksum -e "ssh $(ssh_options)" $THIS_DIR/vm-files/ $(get_vm_ssh_args $VM):~/vm-files

echo ""
echo "setup Istio in VM..."
ssh $(get_vm_ssh_args $VM) "$( cat << EOF

echo "Install the root certificate at /etc/certs..."
sudo mkdir -p /etc/certs
sudo cp \${HOME}/vm-files/root-cert.pem /etc/certs/root-cert.pem

echo ""
echo "Install the token at /var/run/secrets/tokens..."
sudo  mkdir -p /var/run/secrets/tokens
sudo cp \${HOME}/vm-files/istio-token /var/run/secrets/tokens/istio-token

echo ""
echo "install istio package..."
curl -LO https://storage.googleapis.com/istio-release/releases/1.9.4/deb/istio-sidecar.deb
sudo dpkg -i istio-sidecar.deb

echo ""
echo "copy cluster and mesh config for isto..."
sudo cp \${HOME}/vm-files/cluster.env /var/lib/istio/envoy/cluster.env
sudo cp \${HOME}/vm-files/mesh.yaml /etc/istio/config/mesh

echo ""
echo "add DNS entry for cluster host..."
sudo sh -c 'cat \$(eval echo ~\$SUDO_USER)/vm-files/hosts >> /etc/hosts'

echo ""
echo "grant access permissions to istio user..."
sudo mkdir -p /etc/istio/proxy
sudo chown -R istio-proxy /var/lib/istio /etc/certs /etc/istio/proxy /etc/istio/config /var/run/secrets /etc/certs/root-cert.pem

echo ""
echo "start istio..."
sudo systemctl start istio

EOF
)"

# echo ""
# echo "setup nginx ingress..."
# kubectl create ns nginx
# helm install nginx-ingress ingress-nginx/ingress-nginx -n nginx -f $THIS_DIR/helm-charts/nginx-ingress.yaml

# echo ""
# echo "setup cert-manager..."
# kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml
# echo "create certificate issuer..."
# kubectl apply -f $THIS_DIR/certificate-issuer/letsencrypt-prod.yaml

echo ""
echo "setup observability..."
echo ""

echo "install kiali..."
helm install \
  --namespace istio-system \
  --set auth.strategy="anonymous" \
  --repo https://kiali.org/helm-charts \
  kiali-server \
  kiali-server
  
echo "install prometheus..."
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.9/samples/addons/prometheus.yaml

# echo ""
# echo "install a test app over nginx ingress (with auto certificate generation) " 
# kubectl apply -f $THIS_DIR/apps/hello.yaml

echo ""
echo "test1: create service entry for VMs..."
kubectl apply -f $THIS_DIR/vm-test1
echo ""

echo "test2: create VM workload binding and service entry association..."
kubectl apply -f $THIS_DIR/vm-test2
echo ""

echo "test3: create VM workload binding and service association..."
kubectl apply -f $THIS_DIR/vm-test3/app1-vm1.yaml
kubectl apply -f $THIS_DIR/vm-test3/app2-vm2.yaml
kubectl apply -f $THIS_DIR/vm-test3/apps-loadbalance.yaml

echo ""
echo "setup test app in cluster..."
kubectl label namespace default istio-injection=enabled
kubectl apply -f $THIS_DIR/apps/helloworld.yaml
