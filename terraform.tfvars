location = "uaenorth"
prefix   = "index-poc"

secondary_resource_group = "book-keeping"

cluster_azure_ad_groups    = ["f5519392-20c6-46e8-b8cf-17e5429416f1"]
cluster_azure_ad_tenant_id = "da264bdd-872b-4789-ae87-52d5cc7f747b"

cluster_vm_size      = "Standard_D4s_v4"
cluster_vm_min_count = 2
cluster_vm_max_count = 3

win_vm_count = 1
win_vm_size  = "Standard_B4ms"
win_vm_private_ip = [
  "10.1.4.4",
  # "10.1.4.5",
]

linux_vm_count = 1
linux_vm_size  = "Standard_D2s_v3"
linux_vm_private_ip = [
  "10.1.4.100",
  # "10.1.4.101",
]


