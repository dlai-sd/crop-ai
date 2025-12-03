# Azure cleanup — delete resource groups safely

This repository includes `scripts/azure_cleanup.sh`, an interactive Bash script that helps you delete Azure resource groups safely. The script supports dry-run, prefix matching, backing up exported templates, and interactive confirmation.

Important: these operations are destructive. Run only if you have the required permissions and have verified backups.

Quick start

1. Ensure Azure CLI is installed and authenticated:

```bash
az login
# optionally set subscription
az account set --subscription <SUBSCRIPTION_ID_OR_NAME>
```

2. Dry-run groups with a prefix:

```bash
bash scripts/azure_cleanup.sh --prefix crop- --dry-run
```

3. Backup and delete two specific groups (interactive):

```bash
bash scripts/azure_cleanup.sh --groups crop-dev,crop-test --backup
# You will be prompted to type DELETE to confirm
```

4. Delete all groups in subscription (must pass `--yes` to skip prompt):

```bash
bash scripts/azure_cleanup.sh --all --subscription <SUBSCRIPTION_ID> --yes
```

Notes
- `--backup` uses `az group export` and saves JSON templates to `./backups/`. Some resource types may not export cleanly.
- `--no-wait` uses `az group delete --no-wait` to return immediately; otherwise the command waits for deletion to complete.
- The script requires `az` CLI installed and you must have appropriate RBAC permissions (Owner/Contributor) to delete resource groups.

Safety checklist before running
- Confirm the subscription you are operating in: `az account show -o table`.
- Run a dry-run with `--dry-run` or list groups manually: `az group list -o table`.
- If you rely on any resources, double-check dependencies before deleting.

If you want, I can also generate a PowerShell variant or a non-interactive automation script suitable for CI (requires extra caution). 
