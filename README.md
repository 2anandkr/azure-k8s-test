# Azure POC - AKS, Istio and VM monitoring from within the Cluster

This is POC is to:
- setup AKS cluster where micro-service applications will run.
- setup istio service mesh and other monitoring tools to manage cluster services (traffic, security, policy and observability). 
- run legacy apps. in on-off virtual machines.
- extend Istio to monitor apps running within the VMs centrally from the cluster itself. 

## POC Infrastructure high level overview
- create one network and subnets
- create one AKS cluster
- create one windows and one linux VM to test their connectivity with the cluster. Configure terraform to dynamically provision more VMs (if required to test) other cases.  


## Terraform task list(split file-wise)

**`Note:` We have stored a private ssh key here just for quick prototyping needs by users (will be a security breach if used in a production repo.)**

#### variables.tf
- define all configurable variables

#### terraform.tfvars
- configure values for all variables 

#### main.tf
- configure terraform remote backend for storing state remotely (than locally); good for collaborating
- create a resource group
- create a virtual network with 2 subnets configured on custom IP ranges.
- fetch the static IP to be used for load balancer

#### cluster.tf
- create the AKS cluster
  - configure node pools
  - place it in first subnet
  - configure AZs (if available for the region)
  - setup RBAC with Azure AD
  - configure networking with `calico` 

#### roles.tf
- create a role assignment for the Resource Group(RG) where the static IP is created, so that the cluster ingress has permission to use it.

`Note:` if Static IP if created within the same RG as the cluster, it will be deleted when the cluster is destroyed.

#### vm-win.tf and vm-linux.tf
Setup with the ability to dynamically create multiple VMs and its associated resources based on the `count` attribute. For each count:
- create a public IP 
- create a network interface
  - place it in 2nd subnet
  - attach the public IP
  - attach a static private IP (will be used in cluster to setup networking) 
- create security group with restrictive rules
- associate the network interface with security group.
- create the windows/linux VM attaching it to the above network interface.

#### outputs.tf
- output(to console) all required info. needed after resource creation; for reference to be used elsewhere or might be a local shell script can extract these to do something.



## Azure Infra Setup
[Follow this guide to setup all components](./setup.md)



## Test Networking between the cluster and 2 VMs (windows and Linux)

### Which app runs on which VM?

- `APP1` (IIS on port 80) runs on `VM1` (windows) 
- `APP2` (nginx on port 80) runs on `VM2` (linux) 

### Tests

#### **vm-test1** 
Just maps VMs via `ServiceEntry`. Since Istio is setup with DNS_CAPTURE, the host need not be defined. It is a hard one-one mapping between a VM and a host.
```sh
# test1 service endpoints
test1-app1.service
test1-app2.service
```

#### **vm-test2**
*Istio 1.6 introduced `WorkloadEntry`*

Makes use of a `WorkloadEntry` and a `ServiceEntry` to define VM relationships. You can create one entry for each `VM` and target loadbalancing between them in a `ServiceEntry` with `workloadSelector.labels`. If any kubernetes pod has these labels as well, then the traffic will be load-balanced between all targeting VMs and the pod(s).
```sh
# test2 service endpoints
test2-app1.service
test2-app2.service
test2-apps.service
```


#### **vm-test3**
*works with Istio 1.8 and above with addition of `WorkloadGroup` spec*

Makes use of a `WorkloadEntry` and native kubernetes `Service` to define VM relationships. You can create one entry for each `VM` with defined labels and target loadbalancing between them in a `Service` as normally via the `selector` attribute. If the selector targets a kubernetes pod, then the traffic will be load-balanced between all targeting VMs and the pod. 
We also define `WorkloadGroup` for each app (a template to create WorkloadEntries). It is used to generate files that will be used to configure Istio sidecar in a VM.
```sh
# test3 service endpoints
test3-app1.vm.svc
test3-app2.vm.svc
test3-apps.vm.svc
```

### Send traffic from cluster to VM endpoints
```sh
# curl any above test endpoint from inside a cluster pod
kubectl exec $(kubectl get pod -l app=helloworld -o jsonpath={.items..metadata.name} | cut -d' ' -f1) -c helloworld -- curl test3.vm.svc:80
```

### Send traffic from Linux VM cluster
```sh
# login to VM 
./scripts/login.sh
# curl a running service in cluster 
curl helloworld.default.svc:5000/hello

```

### Analyze traffic with Kiali
```
istioctl dashboard kiali
```
