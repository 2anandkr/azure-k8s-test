# nginx ingress with AWS NLB
kubectl create ns nginx
helm install nginx-ingress ingress-nginx/ingress-nginx -n nginx -f ./helm-charts/nginx-ingress.yaml

# cert manager
# Kubernetes 1.16+
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml

# create issuer
kubectl apply -f ./certificate-issuer/letsencrypt-prod.yaml


# istio
istioctl operator init
istioctl install -f istio-config.yaml 

istioctl install -f istio-config.yaml --set values.pilot.env.PILOT_ENABLE_WORKLOAD_ENTRY_AUTOREGISTRATION=true --set values.pilot.env.PILOT_ENABLE_WORKLOAD_ENTRY_HEALTHCHECKS=true


ISTIO_FOLDER=../istio-1.9.4


# SINGLE NETWORK
# ========================
# Deploy the east-west gateway
$ISTIO_FOLDER/samples/multicluster/gen-eastwest-gateway.sh --single-cluster | istioctl install -y -f -
# Expose services inside the cluster via the east-west gateway:
kubectl apply -f $ISTIO_FOLDER/samples/multicluster/expose-istiod.yaml
# ----

# Configure the VM namespace
kubectl create namespace vm
kubectl create serviceaccount vm-access -n vm

# experimental
kubectl --namespace vm apply -f workloadgroup.yaml
istioctl x workload entry configure -f workloadgroup.yaml -o "vm-files" --clusterID "Kubernetes" --autoregister

# generally available
istioctl x workload entry configure -f workloadgroup.yaml -o "vm-files" --clusterID "Kubernetes"


# in vm
ssh adminuser@20.74.155.117
sudo apt-get update
sudo apt-get install rsync nginx

# Install the root certificate at /etc/certs
sudo mkdir -p /etc/certs
sudo cp ${HOME}/vm-files/root-cert.pem /etc/certs/root-cert.pem

# Install the token at /var/run/secrets/tokens
sudo  mkdir -p /var/run/secrets/tokens
sudo cp ${HOME}/vm-files/istio-token /var/run/secrets/tokens/istio-token

# install istio packare
curl -LO https://storage.googleapis.com/istio-release/releases/1.9.4/deb/istio-sidecar.deb
sudo dpkg -i istio-sidecar.deb

sudo cp ${HOME}/vm-files/cluster.env /var/lib/istio/envoy/cluster.env
sudo cp ${HOME}/vm-files/mesh.yaml /etc/istio/config/mesh

sudo sh -c 'cat $(eval echo ~$SUDO_USER)/vm-files/hosts >> /etc/hosts'

sudo mkdir -p /etc/istio/proxy

sudo chown -R istio-proxy /var/lib/istio /etc/certs /etc/istio/proxy /etc/istio/config /var/run/secrets /etc/certs/root-cert.pem

sudo systemctl start istio

# test apps
# in the cluster
kubectl create namespace sample

kubectl label namespace default istio-injection=enabled
kubectl apply -f apps/helloworld.yaml

# from vm
curl helloworld.sample.svc:5000/hello

kubectl exec $(kubectl get pod -l app=helloworld -o jsonpath={.items..metadata.name} | cut -d' ' -f1) -c helloworld -- curl mysql.vm.svc.cluster.local:3306

# remove istio in cluster
kubectl delete -f $ISTIO_FOLDER/samples/multicluster/expose-istiod.yaml
istioctl manifest generate | kubectl delete -f -
kubectl delete namespace istio-system