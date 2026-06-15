#!/bin/bash
# Install DevOps tooling

set -euo pipefail

TOOLS=(
  "kubectl"
  "helm"
  "kind"
  "istioctl"
  "terraform"
  "azure-cli"
  "trivy"
  "velero"
)

echo "Checking installed tools..."
for tool in "${TOOLS[@]}"; do
  if command -v "$tool" &> /dev/null; then
    echo "  [OK] $tool: $(command -v "$tool")"
  else
    echo "  [MISSING] $tool"
  fi
done

echo ""
echo "To install missing tools, refer to:"
echo "  - .skills/kubernetes/install-kind.md"
echo "  - .skills/kubernetes/install-istio.md"
echo "  - .skills/azure/create-vm.md"
