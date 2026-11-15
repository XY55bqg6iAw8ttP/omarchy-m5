#!/bin/bash
# fresh-cleanup.sh: remove the logo Omarchy (p3-p6) and the broken upstream install (p10-p12).
#   bash ~/fresh-cleanup.sh            dry run, changes nothing (asks for sudo to read the startup disk)
#   bash ~/fresh-cleanup.sh --delete   deletes, asking "yes" before each step; all 7 targets must be present
#   bash ~/fresh-cleanup.sh --resume   same, but allows targets that an earlier --delete already removed
set -u
DISK=disk0
LOGO_VG=44EF390C-16A3-4083-9AB8-5A72E15CAE3A
OLD_VG_PREFIX=A0D16C93
STUB="C3DB82BD-EF75-4060-911E-5C879C69AF51 731180457984 5999951872 logo-stub"
# Erased in this order (root, boot, ESP), like the engine.
PARTS="AC4D63E2-5DFA-4DD8-B5B2-40D593CD12D4 739852181504 128767229952 logo-root
3FABFCD9-7651-44CA-8793-D1F255F808AE 737704697856 2147483648 logo-boot
7196BCF0-8994-476A-A9EF-74D2847707F3 737180409856 524288000 logo-esp
9A1E651C-EBBF-4D9E-BED3-1D8E4EA01982 942216839168 52969865216 old-root
78842E13-D931-4764-A3FF-76DA0092F626 940069355520 2147483648 old-boot
595620DE-32DA-430B-8B2E-E1E0076BF045 939545067520 524288000 old-esp"
KEEP="81747D73-70F5-420F-92CB-5EEFAD5C0AF7 iboot-system-container
6C240721-970B-4C09-A6DA-D0DC00EE56B7 macos
32FB5A05-A8DB-4D56-BB12-27F8C48E2EF1 old-stub-LIFELINE
C3D4EBAC-31D4-47B2-BE5B-11D16E2F8715 dev-esp-LIFELINE
0079041F-0A05-48C7-9554-04E1B95AEC99 dev-root-LIFELINE
DFA55EC6-BDB6-4A33-9D30-EDA397E9C556 recovery"

T=$(mktemp -d)
pl()   { plutil -extract "$2" raw -o - "$1" 2>/dev/null; }
info() { diskutil info -plist "$1" > "$T/i.plist" 2>/dev/null && pl "$T/i.plist" "$2"; }
slices() {
  diskutil list -plist $DISK > "$T/l.plist" || return
  local i=0 id
  while id=$(pl "$T/l.plist" "AllDisksAndPartitions.0.Partitions.$i.DeviceIdentifier"); do
    echo "$id"; i=$((i+1)); done
}
by_uuid() {   # partition UUID -> disk0sN; empty if absent; DUP if more than one
  local s r= n=0
  for s in $(slices); do [ "$(info "$s" DiskUUID)" = "$1" ] && { r=$s; n=$((n+1)); }; done
  [ $n -le 1 ] && echo "$r" || echo DUP
}
container_of() {   # physical store disk0sN -> APFS container reference
  diskutil apfs list -plist > "$T/a.plist"; local i=0 ref
  while ref=$(pl "$T/a.plist" "Containers.$i.ContainerReference"); do
    [ "$(pl "$T/a.plist" "Containers.$i.PhysicalStores.0.DeviceIdentifier")" = "$1" ] && { echo "$ref"; return; }
    i=$((i+1)); done
}
groups_of() {   # volume group IDs of the volumes in container $1
  diskutil apfs list -plist > "$T/a.plist"; local i=0 ref j v
  while ref=$(pl "$T/a.plist" "Containers.$i.ContainerReference"); do
    if [ "$ref" = "$1" ]; then j=0
      while v=$(pl "$T/a.plist" "Containers.$i.Volumes.$j.DeviceIdentifier"); do
        info "$v" APFSVolumeGroupID; j=$((j+1)); done
    fi; i=$((i+1)); done
}
show() { printf '  %-9s %-14s offset %-13s size %-13s %-18s %s\n' "$1" "$2" \
  "$(info "$1" PartitionMapPartitionOffset)" "$(info "$1" Size)" "$(info "$1" Content)" "$(info "$1" VolumeName)"; }
same_place() { [ "$(info "$1" PartitionMapPartitionOffset)" = "$2" ] && [ "$(info "$1" Size)" = "$3" ]; }
confirm() { printf '%s\nType yes to go on: ' "$1"; read -r a </dev/tty; [ "$a" = yes ]; }
die() { echo "STOP: $*"; exit 1; }

check() {   # prints the plan; returns 1 if anything is off
  local bad=0 u off size name s c
  MISSING=0
  [ "$(info $DISK Content)" = GUID_partition_scheme ] && [ "$(info $DISK Internal)" = true ] || { echo "STOP: $DISK is not the internal GPT disk"; return 1; }
  echo "== Will DELETE"
  read -r u off size name <<<"$STUB"; s=$(by_uuid "$u")
  if [ -z "$s" ]; then echo "  $name: already gone"; MISSING=$((MISSING+1))
  elif [ "$s" = DUP ]; then echo "  $name: UUID found twice - STOP"; bad=1
  else
    show "$s" "$name"; same_place "$s" "$off" "$size" || { echo "    offset/size differ - STOP"; bad=1; }
    [ "$(info "$s" Content)" = Apple_APFS ] || { echo "    not Apple_APFS - STOP"; bad=1; }
    c=$(container_of "$s"); echo "    APFS container: ${c:-none}  groups: $(groups_of "$c" | sort -u | tr '\n' ' ')"
    groups_of "$c" | grep -qx "$LOGO_VG" || { echo "    volume group $LOGO_VG not in it - STOP"; bad=1; }
    groups_of "$c" | grep -q "^$OLD_VG_PREFIX" && { echo "    this is the OLD stub - STOP"; bad=1; }
  fi
  while read -r u off size name; do
    s=$(by_uuid "$u")
    if [ -z "$s" ]; then echo "  $name: already gone"; MISSING=$((MISSING+1))
    elif [ "$s" = DUP ]; then echo "  $name: UUID found twice - STOP"; bad=1
    else show "$s" "$name"; same_place "$s" "$off" "$size" || { echo "    offset/size differ - STOP"; bad=1; }; fi
  done <<<"$PARTS"
  echo "== Will KEEP"
  while read -r u name; do
    s=$(by_uuid "$u")
    case "$s" in ""|DUP) echo "  $name ($u): missing or duplicated - STOP"; bad=1;; *) show "$s" "$name";; esac
  done <<<"$KEEP"
  echo "== Startup disk"
  local b; b=$(sudo bless --getBoot 2>/dev/null)
  [ -n "$b" ] || { echo "  bless --getBoot printed nothing - STOP"; return 1; }
  echo "  $b  group $(info "$b" APFSVolumeGroupID)  name $(info "$b" VolumeName)"
  [ "$(info "$b" APFSVolumeGroupID)" = "$LOGO_VG" ] && { echo "  the startup disk is the logo stub - STOP (see 6.4)"; bad=1; }
  return $bad
}

diskutil list $DISK
check || die "the disk is not as expected; nothing was changed"
MODE=${1:-}
if [ "$MODE" != --delete ] && [ "$MODE" != --resume ]; then
  [ $MISSING -gt 0 ] && echo "NOTE: $MISSING target(s) are already gone. Use --resume only if an earlier --delete removed them."
  echo; echo "Dry run. Nothing was changed."; exit 0
fi
[ $MISSING -gt 0 ] && [ "$MODE" != --resume ] && die "$MISSING target(s) missing; refusing --delete (see --resume)"

# 1. The stub first: if diskutil refuses, the ESP and Linux partitions are still intact.
read -r u off size name <<<"$STUB"; s=$(by_uuid "$u")
if [ -n "$s" ]; then
  same_place "$s" "$off" "$size" || die "$name moved"
  c=$(container_of "$s"); groups_of "$c" | grep -qx "$LOGO_VG" || die "$name: wrong container"
  confirm "Delete APFS container $c (physical store $s, the logo Omarchy stub)?" || die "not confirmed"
  sudo diskutil apfs deleteContainer "$c" || die "deleteContainer failed"
  # Without a new name current macOS frees the store. Older macOS may leave an empty HFS partition.
  for x in $(slices); do
    if same_place "$x" "$off" "$size"; then
      case "$(info "$x" Content)" in
        Apple_HFS|Apple_HFSX) confirm "An empty $(info "$x" Content) partition $x was left where the stub was. Erase it to free space?" || die "not confirmed"
                              sudo diskutil eraseVolume free none "$x" || die "erase failed";;
        *) die "unexpected partition $x where the stub was";;
      esac
    fi
  done
fi
# 2. The ESP and Linux partitions, each found again by UUID right before it is erased.
while read -r u off size name; do
  s=$(by_uuid "$u"); [ -z "$s" ] && { echo "$name: already gone"; continue; }
  [ "$s" = DUP ] && die "$name found twice"
  same_place "$s" "$off" "$size" || die "$name moved"
  show "$s" "$name"
  confirm "Erase $s ($name) to free space?" || die "not confirmed"
  sudo diskutil eraseVolume free none "$s" || die "erase of $name failed"
done <<<"$PARTS"
echo; diskutil list $DISK; echo; check
