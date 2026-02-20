#!/usr/bin/env python3
"""
Check PBS/SGE job status for Snakemake cluster profile.
Returns: 'running' | 'success' | 'failed'
"""
import subprocess
import sys


def check_pbs(job_id: str) -> str:
    try:
        result = subprocess.run(
            ["qstat", "-f", job_id],
            capture_output=True,
            text=True,
            timeout=30,
        )
        for line in result.stdout.splitlines():
            if "job_state" in line:
                state = line.strip().split("=")[-1].strip()
                if state in ("R", "Q", "H", "W", "T", "E"):
                    return "running"
                elif state == "C":
                    return "success"
                else:
                    return "failed"
        # qstat returned but no job_state line — job finished
        return "success"
    except subprocess.TimeoutExpired:
        return "running"
    except subprocess.CalledProcessError:
        # Job not in queue — completed
        return "success"


if __name__ == "__main__":
    print(check_pbs(sys.argv[1]))
