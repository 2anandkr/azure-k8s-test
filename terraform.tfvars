location = "uaenorth"
prefix   = "index-poc"

cluster_azure_ad_groups    = ["d66d7163-d507-4edf-878c-a2d82ff8f532"]
cluster_azure_ad_tenant_id = "936b1714-3a18-4c25-a00a-ad146eea1cd0"

cluster_vm_size      = "Standard_D2s_v3"
cluster_vm_min_count = 2
cluster_vm_max_count = 3

win_vm_count = 1
win_vm_size  = "Standard_D2s_v3"
win_vm_private_ip = [
  "10.1.4.4",
  "10.1.4.5",
]

linux_vm_count = 1
linux_vm_size  = "Standard_D2s_v3"
linux_vm_private_ip = [
  "10.1.4.100",
  "10.1.4.101",
]
