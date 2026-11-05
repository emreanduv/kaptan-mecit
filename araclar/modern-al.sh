#!/bin/bash
# Kaptan Mecit Modern'i (Kaptan Mecit 3 web derlemesi) www/modern/ içine koyar.
# Tek kaynak: emreanduv.github.io deposundaki kaptan-mecit-3/ (km3'ün her web derlemesi oraya gönderilir).
set -euo pipefail
cd "$(dirname "$0")/.."
T=$(mktemp -d)
git clone -q --depth 1 --filter=blob:none --sparse https://github.com/emreanduv/emreanduv.github.io "$T/site"
git -C "$T/site" sparse-checkout set kaptan-mecit-3
rm -rf www/modern && mkdir -p www/modern
cp "$T/site/kaptan-mecit-3/"index.* www/modern/
rm -rf "$T"
ls -la www/modern
test -s www/modern/index.wasm && test -s www/modern/index.pck
