#!/usr/bin/env bash
set -euo pipefail

# delete_crop_ai_rg.sh
# One-shot script to backup and delete the `crop-ai-rg` resource group.
# WARNING: destructive. Review and run only when ready.

RG_NAME=${1:-crop-ai-rg}
AUTO_YES="false"
NO_WAIT="false"

usage(){
  cat <<EOF
Usage: $0 [<resource-group>] [--yes] [--no-wait]

Defaults to resource group: 'crop-ai-rg'
Options:
  --yes      Skip interactive confirmation (dangerous)
  --no-wait  Start deletion and return immediately

Example:
  $0 crop-ai-rg --yes
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage; exit 0
fi

for arg in "$@"; do
  case "$arg" in
    --yes) AUTO_YES="true"; shift;;
    --no-wait) NO_WAIT="true"; shift;;
    *) ;;
  esac
done

command -v az >/dev/null 2>&1 || { echo "az CLI not found. Install Azure CLI and login first."; exit 1; }

echo "Resource group to delete: $RG_NAME"

exists=$(az group exists -n "$RG_NAME")
if [[ "$exists" != "true" ]]; then
  echo "Resource group '$RG_NAME' does not exist or is not visible in current subscription.";
  exit 1
fi

echo "Preparing backup directory: ./backups"
mkdir -p backups

echo "Exporting ARM template for resource group '$RG_NAME' -> backups/${RG_NAME}.json"
if az group export -n "$RG_NAME" -o json > "backups/${RG_NAME}.json" 2> "backups/${RG_NAME}.export.err"; then
  echo "Export saved to backups/${RG_NAME}.json"
else
  echo "Export completed with warnings. Check backups/${RG_NAME}.export.err for details"
fi

echo
echo "Resources inside '$RG_NAME':"
az resource list -g "$RG_NAME" -o table || true

echo
echo "ACR registries in the group (if any):"
az acr list -g "$RG_NAME" -o table || true

echo
echo "Web Apps in the group (if any):"
az webapp list -g "$RG_NAME" -o table || true

if [[ "$AUTO_YES" != "true" ]]; then
  echo
  echo "This will delete resource group '$RG_NAME' and ALL resources in it."
  echo "Type DELETE (uppercase) to confirm:"; read -r CONFIRM
  if [[ "$CONFIRM" != "DELETE" ]]; then
    echo "Confirmation did not match 'DELETE'. Aborting."; exit 1
  fi
fi

echo "Deleting resource group '$RG_NAME'..."
if [[ "$NO_WAIT" == "true" ]]; then
  az group delete -n "$RG_NAME" --yes --no-wait
  echo "Deletion started (no-wait). Use 'az group show -n $RG_NAME' to check status.";
else
  az group delete -n "$RG_NAME" --yes
  echo "Deletion completed (or started and returned)."
fi

echo "Done. Verify with 'az group list -o table' or 'az group show -n $RG_NAME'"
