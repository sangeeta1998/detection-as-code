#!/usr/bin/env python3
"""
Runs each attack simulation as a Kubernetes Job, then tails Falco's pod
logs looking for the matching lab rule to fire within a timeout.
 the CI gate: if a detection rule regresses, if a Helm
values change accidentally disables a rule, or if the Falco version bump
changes rule syntax, this script fails and so does the build. That is tthe
point of the whole pipeline, detection coverage becomes something CI
checks on every change instead of something someone finds out about
during an incident.

Usage:
    python3 tests/validate_alerts.py --namespace detection-lab \
        --target-namespace lab-target --timeout 90

Exit code is non-zero if any scenario's rule did not fire in time.
"""

import argparse
import json
import subprocess
import sys
import time

SCENARIOS = [
    {
        "name": "reverse-shell",
        "job_manifest": "attack-simulations/reverse-shell-job.yaml",
        "job_names": ["reverse-shell-sim"],
        "rule": "Lab - Unexpected Outbound Shell",
    },
    {
        "name": "ransomware",
        "job_manifest": "attack-simulations/ransomware-job.yaml",
        "job_names": ["ransomware-sim"],
        "rule": "Lab - Rapid File Rewrite Burst",
    },
]


def run(cmd, **kwargs):
    print(f"+ {' '.join(cmd)}")
    return subprocess.run(cmd, check=True, text=True, **kwargs)


def falco_pod_name(namespace: str) -> str:
    result = subprocess.run(
        [
            "kubectl", "get", "pods", "-n", namespace,
            "-l", "app.kubernetes.io/name=falco",
            "-o", "jsonpath={.items[0].metadata.name}",
        ],
        check=True, text=True, capture_output=True,
    )
    pod = result.stdout.strip()
    if not pod:
        raise RuntimeError(f"no Falco pod found in namespace {namespace}")
    return pod


def rule_fired_since(namespace: str, pod: str, rule: str, since_seconds: int) -> bool:
    result = subprocess.run(
        ["kubectl", "logs", "-n", namespace, pod, f"--since={since_seconds}s"],
        text=True, capture_output=True,
    )
    for line in result.stdout.splitlines():
        line = line.strip()
        if not line or not line.startswith("{"):
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if event.get("rule") == rule:
            print(f"  matched: {event.get('output', line)}")
            return True
    return False


def wait_for_job(namespace: str, job_name: str, timeout: int):
    run([
        "kubectl", "wait", f"job/{job_name}", "-n", namespace,
        "--for=condition=complete", f"--timeout={timeout}s",
    ])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--namespace", default="detection-lab", help="namespace running Falco")
    parser.add_argument("--target-namespace", default="lab-target", help="namespace the sim Jobs run in")
    parser.add_argument("--timeout", type=int, default=90, help="seconds to wait for each rule to fire")
    args = parser.parse_args()

    pod = falco_pod_name(args.namespace)
    print(f"watching Falco pod: {pod}")

    failures = []

    for scenario in SCENARIOS:
        print(f"\n=== scenario: {scenario['name']} ===")
        run(["kubectl", "apply", "-f", scenario["job_manifest"]])

        for job_name in scenario["job_names"]:
            try:
                wait_for_job(args.target_namespace, job_name, args.timeout)
            except subprocess.CalledProcessError:
                print(f"  job {job_name} did not complete in time")

        deadline = time.time() + args.timeout
        fired = False
        while time.time() < deadline:
            if rule_fired_since(args.namespace, pod, scenario["rule"], args.timeout + 30):
                fired = True
                break
            time.sleep(5)

        status = "PASS" if fired else "FAIL"
        print(f"  {scenario['name']}: {status} (rule: {scenario['rule']})")
        if not fired:
            failures.append(scenario["name"])

    print("\n=== summary ===")
    if failures:
        print(f"FAILED scenarios: {', '.join(failures)}")
        sys.exit(1)

    print("all detection scenarios fired as expected")
    sys.exit(0)


if __name__ == "__main__":
    main()
