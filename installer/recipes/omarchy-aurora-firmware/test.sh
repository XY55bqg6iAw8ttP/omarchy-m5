#!/bin/bash
set -euo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root=$(cd -- "$here/../.." && pwd)
# the initramfs ordering test, where the tree carries it
if [[ -f $root/tests/aurora-firmware-ordering.py ]]; then
  python "$root/tests/aurora-firmware-ordering.py"
else
  echo "skip tests/aurora-firmware-ordering.py (not in this tree)"
fi
bash "$here/test-boot-guard.sh"
