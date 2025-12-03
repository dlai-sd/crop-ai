#!/usr/bin/env bash
set -euo pipefail

# azure_cleanup.sh
# Safely delete Azure resource groups (interactive, with optional backup/export).
# WARNING: This script performs destructive operations. Review before running.

usage() {
  cat <<EOF
Usage: $0 [--groups grp1,grp2] [--prefix PREFIX] [--subscription SUB] [--backup] [--dry-run] [--yes] [--no-wait]

Options:
  --groups G1,G2        Comma-separated resource group names to delete
  --prefix PREFIX       Delete all resource groups whose name starts with PREFIX
  --subscription SUB    Azure subscription id or name to use (optional)
  --backup              Attempt to export each resource group's template to ./backups before deletion
  --dry-run             Show the groups that would be deleted and exit
  --yes                 Skip interactive confirmation (dangerous)
  --no-wait             Use `az group delete --no-wait` (returns immediately)
  --all                 Delete ALL resource groups in the subscription (VERY DANGEROUS)
  --help                Show this help

Examples:
  # Dry-run groups with prefix 'crop-'
  $0 --prefix crop- --dry-run

  # Backup and delete two specific groups (interactive)
  $0 --groups crop-dev,crop-test --backup

  # Delete all groups in a subscription (must pass --yes)
  $0 --all --subscription my-sub-id --yes

EOF
}

GROUPS=""
PREFIX=""
SUBSCRIPTION=""
BACKUP="false"
DRY_RUN="false"
AUTO_YES="false"
NO_WAIT="false"
DELETE_ALL="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --groups)
      GROUPS="$2"; shift 2;;
    --prefix)
      PREFIX="$2"; shift 2;;
    --subscription)
      SUBSCRIPTION="$2"; shift 2;;
    --backup)
      BACKUP="true"; shift;;
    --dry-run)
      DRY_RUN="true"; shift;;
    --yes)
      AUTO_YES="true"; shift;;
    --no-wait)
      NO_WAIT="true"; shift;;
    --all)
      DELETE_ALL="true"; shift;;
    --help)
      usage; exit 0;;
    *)
      echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

command -v az >/dev/null 2>&1 || { echo "az CLI not found. Install Azure CLI and login first."; exit 1; }

if [[ -n "$SUBSCRIPTION" ]]; then
  echo "Setting subscription to: $SUBSCRIPTION"
  az account set --subscription "$SUBSCRIPTION"
fi

declare -a TO_DELETE

if [[ "$DELETE_ALL" == "true" ]]; then
  echo "Fetching all resource groups in subscription..."
  mapfile -t TO_DELETE < <(az group list --query "[].name" -o tsv)
fi

if [[ -n "$GROUPS" ]]; then
  IFS=',' read -r -a arr <<< "$GROUPS"
  for g in "${arr[@]}"; do
    TO_DELETE+=("$g")
  done
fi

if [[ -n "$PREFIX" ]]; then
  echo "Searching for groups with prefix: $PREFIX"
  mapfile -t match < <(az group list --query "[?starts_with(name, '${PREFIX}')].name" -o tsv)
  for g in "${match[@]}"; do
    TO_DELETE+=("$g")
  done
fi

# dedupe
if [[ ${#TO_DELETE[@]} -gt 0 ]]; then
  readarray -t uniqs < <(printf "%s\n" "${TO_DELETE[@]}" | awk '!x[$0]++')
  TO_DELETE=("${uniqs[@]}")
fi

if [[ ${#TO_DELETE[@]} -eq 0 ]]; then
  echo "No resource groups selected for deletion. Use --groups, --prefix or --all. Exiting."; exit 0
fi

echo "The following resource groups will be affected:"
for g in "${TO_DELETE[@]}"; do echo " - $g"; done

if [[ "$DRY_RUN" == "true" ]]; then
  echo "Dry-run mode; no changes will be made."; exit 0
fi

if [[ "$AUTO_YES" != "true" ]]; then
  echo
  echo "This operation is destructive and irreversible."
  echo "Type DELETE (uppercase) to confirm and proceed:" 
  read -r CONFIRM
  if [[ "$CONFIRM" != "DELETE" ]]; then
    echo "Confirmation did not match 'DELETE'. Aborting."; exit 1
  fi
fi

if [[ "$BACKUP" == "true" ]]; then
  mkdir -p backups
fi

for rg in "${TO_DELETE[@]}"; do
  echo
  echo "Processing resource group: $rg"
  if [[ "$BACKUP" == "true" ]]; then
    echo " - Exporting template to backups/${rg}.json (may fail for some resources)"
    if az group export -g "$rg" -o json > "backups/${rg}.json" 2> "backups/${rg}.export.err"; then
      echo " - Export saved"
    else
      echo " - Export had errors; see backups/${rg}.export.err"
    fi
  fi

  echo " - Deleting resource group $rg"
  if [[ "$NO_WAIT" == "true" ]]; then
    az group delete -n "$rg" --yes --no-wait || echo "Failed to start deletion for $rg"
  else
    az group delete -n "$rg" --yes || echo "Failed to delete $rg"
  fi
done

echo
echo "Requested deletions submitted. Verify in the portal or via 'az group list' to confirm removal." 
