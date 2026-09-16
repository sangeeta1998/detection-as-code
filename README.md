# detection-as-code

A smal  runnable example of gating a Kubernetes runtime security stack
behind CI: infrastructure and detection rules are defined as code,
deployed automatically and exercised against synthetic attack behaviour and
the build fails if a detection regresses.

```
                 ┌────────────────────────┐
   push / PR ───▶│   GitHub Actions CI     │
                 └───────────┬────────────┘
                              │
                 1. terraform fmt / validate
                              │
                 2. kind cluster spun up
                              │
                 3. terraform apply
                    (namespace + Falco via Helm,
                     custom rules loaded)
                              │
                 4. attack simulations run as Jobs
                    ┌─────────┴─────────┐
                    │                    │
           reverse-shell-sim      ransomware-sim
           (outbound conn from     (rapid file
            a shell process)        rewrite burst)
                    │                    │
                    └─────────┬─────────┘
                              ▼
                 5. tests/validate_alerts.py
                    greps Falco's output for the
                    matching rule within a timeout
                              │
                 6. pass ⇒ merge allowed
                    fail ⇒ build fails, PR blocked
                              │
                 7. terraform destroy (always)
```

#

Runtime detection rules rot quietly. A chart bump or a values change or a
kernel rule syntax difference between Falco versions.. any of these can
silently disable a detection with no error adn no warning, nothing until an
incident makes the gap obvious. I am trying to treat detection coverage the
same way we would treat test coverage ..so if something CI actually checks on
every change

## repo struc

| Path | What it is |
|---|---|
| `terraform/` | Infra as code. Deploys a namespace and Falco (via the upstream Helm chart) onto whatever cluster the current kube context points at. Same module works against `kind` locally/in CI or a real cluster, see `terraform/environments/`. |
| `detection-rules/custom_rules.yaml` | Two rules layered on top of Falco's default rule set, mapped to specific MITRE ATT&CK techniques, written to be short enough to read in one pass. |
| `attack-simulations/` | Synthetic technique reproductions (Atomic-Red-Team style) run as Kubernetes Jobs not executed on the CI runner itself. No real malware and no destructive payload. |
| `tests/validate_alerts.py` | Runs each simulation, tails Falco's logs, asserts the matching rule fired within a timeout. This is our CI gate. |
| `.github/workflows/ci.yml` | Wires all of the above into a pipeline: validate → deploy → attack → assert → tear down on every push and PR. |

## Running it 

```bash
kind create cluster --name detection-lab

cd terraform
terraform init
terraform apply -var kube_context=kind-detection-lab
cd ..

kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=falco -n detection-lab --timeout=120s
kubectl apply -f attack-simulations/namespace.yaml

python3 tests/validate_alerts.py
```

Expect two `PASS` lines. Break one of the rules in
`detection-rules/custom_rules.yaml`(rename the rule, for instance) and
re-run it to see the gate actually fail.

Tear down with `terraform -chdir=terraform destroy -var
kube_context=kind-detection-lab` and `kind delete cluster --name
detection-lab`.

## Extending it

- `var.enable_tetragon` in `terraform/variables.tf` deploys Tetragon
  alongside Falco for process/network eBPF visibility from a second angle.
  Off by default so the CI pipeline stays runnable on constrained
  runners; the README in `terraform/environments/local/` covers the
  kernel requirements for turning it on.
- `terraform/environments/aws/README.md` covers pointing the same module
  at a real EKS cluster instead of `kind`, without changing anything
  about the Terraform itself.
- Adding a third scenario is three pieces: a rule in
  `detection-rules/custom_rules.yaml`, a Job manifest in
  `attack-simulations/` and an entry in the `SCENARIOS` list in
  `tests/validate_alerts.py`.

## Scope

This is a reference implementation with 2 detection scenarios.. one
detection engine by default  and one cluster provider exercised in CI. The
patterns (rules as code, synthetic attack simulation as a CI step,
detection coverage as a merge gate)are the part meant to generalize(not
the specific rule count.)
