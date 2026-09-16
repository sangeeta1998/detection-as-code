# attack simulations
 same spirit as [Atomic Red
Team](https://github.com/redcanaryco/atomic-red-team)..small scripts that
reproduce the observable *behaviour* MITRE ATT&CK describes. exist purely to
give the detection rules in `detection-rules/custom_rules.yaml` something
real to fire on.

| Script | Simulates | MITRE technique |
|---|---|---|
| `reverse_shell_sim.sh` | A shell opening an outbound connection, the behavioural core of a reverse shell | T1059, T1071 |
| `ransomware_sim.sh` | A process rapidly rewriting many files in a watched directory | T1486 |

Each is deployed into the cluster as a short-lived Kubernetes `Job` in the
`lab-target` namespace (kept separate from `detection`, which runs the
detection stack itself and from anything else on the cluster) so the
behaviour is observed the same way a real workload's would be: through the
Falco eBPF probe, not by running the script directly on the CI runner.

Run one manually against a running cluster:

```bash
kubectl apply -f attack-simulations/namespace.yaml
kubectl apply -f attack-simulations/reverse-shell-job.yaml
kubectl logs -n detection-lab -l app.kubernetes.io/name=falco -f
```

`tests/validate_alerts.py` does this same thing for both scenarios and
asserts the matching Falco rule fired within a timeout..
