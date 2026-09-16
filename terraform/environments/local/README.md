# local environment

This is the environment CI runs against and the one to use for local
development: a `kind` cluster
```bash
kind create cluster --name detection-lab
kubectl cluster-info --context kind-detection-lab

cd terraform
terraform init
terraform apply -var kube_context=kind-detection-lab
```

Bring it down with `terraform destroy` followed by `kind delete cluster
--name detection`.
