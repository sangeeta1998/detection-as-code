# aws environment ( not wired into CI)

The Terraform in `terraform/` deploys workloads onto whatever cluster
`kubeconfig_path`/`kube_context` point at it does not care whether that
cluster is `kind` or EKS. CI intentionally targets `kind` only, so the
pipeline stays free and fast to run on every push but the same module
applies unchanged against a real cluster.

To point it at EKS instead of `kind`:

```bash
aws eks update-kubeconfig --name <your-cluster-name> --region <region>
cd terraform
terraform apply -var kube_context=<the-context-eks-just-wrote>
```

If you also want Terraform to own the cluster itself rather then add a separate root module here using the upstream
`terraform-aws-modules/eks/aws` module, something along these lines:

```hcl
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.0"
  cluster_name    = "detection-lab"
  cluster_version = "1.30"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }
}
```