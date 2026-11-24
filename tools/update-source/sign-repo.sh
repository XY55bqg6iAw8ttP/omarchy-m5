#!/bin/bash
set -e
cd /r
export GNUPGHOME=/g
for p in *.pkg.tar.zst; do rm -f "$p.sig"; gpg --batch --yes --detach-sign --no-armor -u E86FAF980FDC450871B7EA99FCA533429F69AE22 "$p"; done
rm -f omarchy-m5.db* omarchy-m5.files*
repo-add -q -s -k E86FAF980FDC450871B7EA99FCA533429F69AE22 omarchy-m5.db.tar.zst *.pkg.tar.zst
