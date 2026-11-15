#!/bin/bash
# SPDX-License-Identifier: MIT
# Tests m5-boot-guard in a scratch root with a fake pacman: no root, nothing installed. The guard
# runs as a child of a process named "pacman" (a symlink to bash), as pacman runs a hook.
# Do not run this (or test.sh) as root: one case below deliberately reads the real /etc.
set -u
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
guard=$here/m5-boot-guard
d=$(mktemp -d)
trap 'rm -rf "$d"' EXIT
mkdir -p "$d/bin" "$d/parent" "$d/root/etc/omarchy-j714s" "$d/root/etc/omarchy-k114s" "$d/root/boot/efi/m1n1" \
  "$d/root/usr/local/lib/omarchy-j714s" "$d/root/installed" "$d/root/repo"
ln -s "$(command -v bash)" "$d/parent/pacman"
# fake pacman: -Q reads installed/NAME, -Si reads repo/NAME; -Qp fails (the file name is parsed)
cat > "$d/bin/pacman" <<'FAKE'
#!/bin/bash
r=$M5_ROOT
case $1 in
  -Q) [[ -f $r/installed/$2 ]] && echo "$2 $(cat "$r/installed/$2")" ;;
  -Si) echo "$2" >> "$r/si-args"; n=${2#*/}; [[ -f $r/repo/$n ]] && echo "Version         : $(cat "$r/repo/$n")" ;;
  *) exit 1 ;;
esac
FAKE
chmod +x "$d/bin/pacman"
root=$d/root
for p in linux-aurora m1n1-aurora uboot-aurora omarchy-aurora-firmware; do echo 7.3.0.aurora17.v272-11 > "$root/installed/$p"; done
printf 'apple,j714s\0apple,t6050\0apple,arm-platform\0' > "$d/j714s.compat"
printf 'apple,k114s\0apple,t6050\0apple,arm-platform\0' > "$d/k114s.compat"

fail=0 out=
# run COMPAT MODE PACMAN-ARGS...: package names on stdin come from $names; sets $out and $rc
run() {
  local compat=$1 mode=$2; shift 2
  out=$(env PATH="$d/bin:$PATH" M5_GUARD_TEST=1 M5_ROOT=$root M5_DT_COMPATIBLE=$compat M5_NO_MOUNTCHECK=${nomount-1} \
    M5_ESP_MIN_FREE=${min:-1} "$d/parent/pacman" -c 'printf "%s\n" $NAMES | "$GUARD" '"$mode"'; rc=$?; exit $rc' x "$@" 2>&1)
  rc=$?
}
export NAMES="linux-aurora m1n1-aurora" GUARD=$guard
check() { # check NAME WANT_RC [GREP]
  local ok=1
  [[ $rc == "$2" ]] || ok=0
  [[ -z ${3:-} ]] || grep -q -- "$3" <<<"$out" || ok=0
  if ((ok)); then echo "ok   $1"; else echo "FAIL $1 (rc=$rc, want $2, grep '${3:-}')"; echo "$out" | sed 's/^/     | /'; fail=1; fi
}
edge() { for p in linux-aurora m1n1-aurora; do echo "$1" > "$root/repo/$p"; done; }
nomount=1 min=1

echo "-- J714s"
edge 7.4.0.aurora18-1;               run "$d/j714s.compat" packages -Su;    check "generic build is stopped" 1 "STOPPED by the J714s boot guard"
grep -q "this MacBook Pro's (J714s) boot packages" <<<"$out" && echo "ok   J714s wording" || { echo "FAIL J714s wording"; fail=1; }
edge 7.3.0.aurora18.v272-12;         run "$d/j714s.compat" packages -Su;    check "J714s build goes through" 0
edge 1.6.1.aurora24.up273-1;         run "$d/j714s.compat" packages -Su;    check "up273 build goes through" 0
edge 20261014.j714s13-1;             run "$d/j714s.compat" packages -Su;    check "j714s build goes through" 0
rm -f "$root/repo/m1n1-aurora";      run "$d/j714s.compat" packages -Su;    check "unknown build is refused" 1 "cannot tell which build"
edge 7.4.0.aurora18-1;               run "$d/nonexistent" packages -Su;     check "unreadable device tree is a J714s" 1 "J714s boot guard"
                                     run "$d/j714s.compat" packages -Rns;   check "removal is stopped" 1 "removed"
touch "$root/etc/omarchy-j714s/allow-boot-package-change"
                                     run "$d/j714s.compat" packages -Su;    check "override allows once" 0 "omarchy-j714s boot guard: /etc/omarchy-j714s/allow-boot-package-change was set"
[[ ! -e $root/etc/omarchy-j714s/allow-boot-package-change ]] && echo "ok   override file removed" || { echo "FAIL override file kept"; fail=1; }
                                     run "$d/j714s.compat" packages -Su;    check "override is single use" 1
echo 'IgnorePkg = linux-aurora' > "$root/etc/pacman.conf.bak"; : > "$root/etc/pacman.conf"
                                     run "$d/j714s.compat" packages -Su;    check "lost pin: backup saved, restore advised" 1 "cp /etc/pacman.conf.j714s-pinned /etc/pacman.conf"
[[ -f $root/etc/pacman.conf.j714s-pinned ]] && echo "ok   pin kept under the J714s name" || { echo "FAIL pin not kept"; fail=1; }
# nothing K114s-specific runs on a J714s
nomount= min=999999999999;           run "$d/j714s.compat" esp;             check "ESP check is a no-op on a J714s" 0
nomount=1 min=1
edge 7.3.0.aurora18.v272-12;         run "$d/j714s.compat" packages -Su;    check "no Stage 2 check on a J714s (no boot-ctxr.bin)" 0
echo "-- shim"
out=$(printf 'linux-aurora\n' | env PATH="$d/bin:$PATH" M5_GUARD_TEST=1 M5_ROOT=$root M5_DT_COMPATIBLE=$d/j714s.compat "$here/j714s-boot-guard" 2>&1); rc=$?
check "j714s-boot-guard still runs the guard" 0
edge 7.4.0.aurora18-1
out=$(printf 'linux-aurora\n' | env PATH="$d/bin:$PATH" M5_GUARD_TEST=1 M5_ROOT=$root M5_DT_COMPATIBLE=$d/j714s.compat "$here/j714s-boot-guard" 2>&1); rc=$?
check "shim passes a stop through" 1 "STOPPED by the J714s boot guard"
edge 7.3.0.aurora18.v272-12
echo "-- pacman command line"
edge 7.4.0.aurora18-1; NAMES=linux-aurora
run "$d/j714s.compat" packages -U "https://x/linux-aurora-7.3.0.aurora18.v272-12-aarch64.pkg.tar.zst"; check "-U URL with an M5 build goes through" 0
run "$d/j714s.compat" packages -U "https://x/linux-aurora-7.4.0.aurora18-1-aarch64.pkg.tar.zst";       check "-U URL with a generic build is stopped" 1 "7.4.0.aurora18-1"
run "$d/j714s.compat" packages -U ./linux-aurora-7.3.0.aurora18.v272-12-aarch64.pkg.tar.zst;            check "-U relative file name is parsed" 0
NAMES=m1n1-aurora
run "$d/j714s.compat" packages -S extra/m1n1-aurora;           check "repo/name is looked up by name" 1 "7.4.0"
grep -qxF extra/m1n1-aurora "$root/si-args" && echo "ok   pacman -Si got the repo prefix" || { echo "FAIL pacman -Si lost the repo prefix"; fail=1; }
NAMES="linux-aurora m1n1-aurora"
echo "-- environment overrides"
# this case reads the real /etc and /boot/efi, so it is skipped as root or where an override file exists
if ((EUID == 0)) || compgen -G '/etc/omarchy-*/allow-boot-package-change' > /dev/null; then
  echo "skip environment overrides (root, or a real allow-boot-package-change file exists)"
else
  out=$(printf 'linux-aurora\n' | env PATH="$d/bin:$PATH" M5_ROOT=$d/nonexistent M5_DT_COMPATIBLE=$d/k114s.compat "$d/parent/pacman" -c 'printf "linux-aurora\n" | "$GUARD" packages' x -Su 2>&1); rc=$?
  check "M5_* overrides are ignored without M5_GUARD_TEST (real /etc, not the scratch root)" 1 "mkdir -p /etc/omarchy-"
fi
echo "-- hooks"
if grep -q '^Target = \*$' "$here/01-omarchy-m5-esp-space.hook"; then echo "FAIL ESP hook triggers on every transaction"; fail=1; else echo "ok   ESP hook is not Target = *"; fi
grep -q '^Type = Path' "$here/01-omarchy-m5-esp-space.hook" && echo "ok   ESP hook is a Path trigger" || { echo "FAIL ESP hook is not a Path trigger"; fail=1; }

echo "-- hook files"
# Target values of the hook's Type = $2 trigger(s), or its [Action] value for key $2 (Exec, When, ...)
targets() { awk -v t="$2" '/^\[/ { sec = $0; type = "" } sec == "[Trigger]" && $1 == "Type" { type = $3 } sec == "[Trigger]" && type == t && $1 == "Target" { print $3 }' "$1" | sort; }
action() { awk -v k="$2" '/^\[/ { sec = $0 } sec == "[Action]" && $1 == k { sub(/^[^=]*= */, ""); print }' "$1"; }
has() { grep -qxF -- "$2" "$1"; }
same() { # same NAME GOT WANT
  [[ $2 == "$3" ]] && echo "ok   $1" || { echo "FAIL $1"; diff <(echo "$3") <(echo "$2") | sed 's/^/     | /'; fail=1; }
}
h0=$here/00-omarchy-m5-boot-guard.hook h1=$here/01-omarchy-m5-esp-space.hook
same "00 hook: When = PreTransaction"       "$(action "$h0" When)"        PreTransaction
same "01 hook: When = PreTransaction"       "$(action "$h1" When)"        PreTransaction
has "$h0" AbortOnFail && echo "ok   00 hook: AbortOnFail" || { echo "FAIL 00 hook: AbortOnFail"; fail=1; }
has "$h1" AbortOnFail && echo "ok   01 hook: AbortOnFail" || { echo "FAIL 01 hook: AbortOnFail"; fail=1; }
has "$h0" NeedsTargets && echo "ok   00 hook: NeedsTargets" || { echo "FAIL 00 hook: NeedsTargets"; fail=1; }
has "$h1" NeedsTargets && { echo "FAIL 01 hook: NeedsTargets (not wanted)"; fail=1; } || echo "ok   01 hook: no NeedsTargets"
same "00 hook: Exec"                        "$(action "$h0" Exec)"        "/usr/lib/omarchy-aurora/m5-boot-guard packages"
same "01 hook: Exec"                        "$(action "$h1" Exec)"        "/usr/lib/omarchy-aurora/m5-boot-guard esp"
same "00 hook: Package targets"             "$(targets "$h0" Package)"    "$(sort <<'T'
linux-aurora
m1n1-aurora
uboot-aurora
omarchy-aurora-firmware
T
)"
same "01 hook: Package targets"             "$(targets "$h1" Package)"    "$(sort <<'T'
mkinitcpio
mkinitcpio-git
limine
limine-git
limine-dev
limine-mkinitcpio-hook
limine-mkinitcpio-hook-git
linux-aurora
m1n1-aurora
uboot-aurora
omarchy-mac-boot
omarchy-aurora-firmware
asahi-scripts
T
)"
same "01 hook: Path targets"                "$(targets "$h1" Path)"       "$(sort <<'T'
usr/lib/modules/*/vmlinuz
usr/lib/modules/*/modules.builtin
usr/lib/modules/*/pkgbase
usr/lib/modules/*/extramodules/
usr/lib/modules/*/dtbs/*
usr/lib/asahi-boot/*
usr/lib/asahi-boot-*/*
usr/lib/omarchy-mac-boot/dtb-overlays/*/*.dtbo
usr/lib/initcpio/*
usr/lib/initcpio/install/*
etc/initcpio/install/*
usr/lib/omarchy/initcpio/*
etc/mkinitcpio.conf
etc/mkinitcpio.conf.d/*
etc/mkinitcpio.conf.d/90-omarchy-mac.conf
etc/mkinitcpio.conf.d/91-omarchy-mac-encrypt.conf
etc/mkinitcpio.conf.d/92-omarchy-mac-hid.conf
etc/mkinitcpio.conf.d/92-omarchy-mac-kbd-backlight.conf
etc/mkinitcpio.conf.d/92-omarchy-mac-pmp.conf
etc/mkinitcpio.conf.d/93-omarchy-mac-plymouth.conf
etc/mkinitcpio.conf.d/94-omarchy-mac-vconsole.conf
etc/mkinitcpio.d/*
usr/lib/udev/rules.d/90-omarchy-mac-kbd-backlight.rules
usr/lib/firmware/*
boot/dtbs/*
usr/lib/systemd/boot/hwids/*
usr/lib/systemd/boot/efi/*
usr/src/*/dkms.conf
usr/lib/systemd/systemd
usr/lib/systemd/systemd-udevd
usr/bin/cryptsetup
usr/bin/lvm
usr/bin/mdadm
usr/bin/pdata_tools
usr/lib/libcryptsetup.so
usr/lib/libp11-kit.so
usr/lib/libpcsclite.so
usr/lib/modprobe.d/
usr/share/limine/*
usr/share/limine/BOOTAA64.EFI
T
)"
# PKGBUILD package() installs every hook and script, the guard executable
for f in 00-omarchy-m5-boot-guard.hook 01-omarchy-m5-esp-space.hook; do
  grep -qF "install -Dm644 $f \"\$pkgdir/usr/share/libalpm/hooks/$f\"" "$here/PKGBUILD" && echo "ok   PKGBUILD installs $f (644)" || { echo "FAIL PKGBUILD does not install $f with mode 644"; fail=1; }
done
for f in m5-boot-guard j714s-boot-guard; do
  grep -qF "install -Dm755 $f \"\$pkgdir/usr/lib/omarchy-aurora/$f\"" "$here/PKGBUILD" && echo "ok   PKGBUILD installs $f (755)" || { echo "FAIL PKGBUILD does not install $f with mode 755"; fail=1; }
done
# every Path target of the stock hooks that rewrite boot files must be in the ESP hook (a lone * is ignored)
for name in 90-mkinitcpio-install 90-mkinitcpio-apple-install 91-omarchy-mac-boot-initramfs 95-m1n1-install 95-omarchy-mac-dtb-overlays; do
  HOOK=/usr/share/libalpm/hooks/$name.hook
  if [[ -r $HOOK ]]; then
    miss=$(sed -n 's/^Target = //p' "$HOOK" | grep -vxF '*' | sort -u | while read -r t; do
      grep -qxF "Target = $t" "$here/01-omarchy-m5-esp-space.hook" || echo "$t"; done)
    [[ -z $miss ]] && echo "ok   ESP hook lists every Target of $name.hook" || { echo "FAIL ESP hook misses $name.hook Targets: $miss"; fail=1; }
  else
    echo "skip $name.hook Targets ($HOOK not present)"
  fi
done
# every local source in the PKGBUILD matches its sha256sums entry (by position)
(
  # shellcheck disable=SC1091
  . "$here/PKGBUILD"
  bad=0
  for i in "${!source[@]}"; do
    f=${source[i]}; [[ $f == *://* || $f == *::* || ! -f $here/$f ]] && continue
    [[ $(sha256sum "$here/$f" | cut -d' ' -f1) == "${sha256sums[i]}" ]] || { echo "FAIL PKGBUILD sha256 for $f"; bad=1; }
  done
  exit $bad
) && echo "ok   PKGBUILD sha256sums match the local sources" || fail=1

echo "-- K114s"
printf 'aura stage2 .. apple,k114s ..' > "$root/boot/efi/m1n1/boot-ctxr.bin"
printf '#!/bin/sh\nexec /usr/local/lib/omarchy-k114s/update-boot-ctxr "$@"\n' > "$root/usr/local/lib/omarchy-j714s/update-boot-ctxr"
edge 7.3.0.aurora18.v272-12;         run "$d/k114s.compat" packages -Su;    check "K114s: M5 build, Stage 2 kept" 0
edge 7.4.0.aurora18-1;               run "$d/k114s.compat" packages -Su;    check "K114s: generic build is stopped" 1 "STOPPED by the K114s boot guard"
edge 7.3.0.aurora18.v272-12
printf 'aura stage2 .. apple,j714s ..' > "$root/boot/efi/m1n1/boot-ctxr.bin"
                                     run "$d/k114s.compat" packages -Su;    check "K114s: Stage 2 without a K114s tree is stopped" 1 "Stage 2: m1n1/boot-ctxr.bin has no apple,k114s"
printf 'aura stage2 .. apple,k114s ..' > "$root/boot/efi/m1n1/boot-ctxr.bin"; cp "$root/boot/efi/m1n1/boot-ctxr.bin" "$root/boot/efi/m1n1/boot.bin"
                                     run "$d/k114s.compat" packages -Su;    check "K114s: Stage 2 that is a copy of boot.bin is stopped" 1 "copy of m1n1/boot.bin"
rm "$root/boot/efi/m1n1/boot.bin"; : > "$root/boot/efi/m1n1/boot-ctxr.bin"
                                     run "$d/k114s.compat" packages -Su;    check "K114s: empty Stage 2 is stopped" 1 "missing or empty"
printf 'aura stage2 .. apple,k114s ..' > "$root/boot/efi/m1n1/boot-ctxr.bin"
printf '#!/bin/sh\ncp /boot/efi/m1n1/boot.bin /boot/efi/m1n1/boot-ctxr.bin\n' > "$root/usr/local/lib/omarchy-j714s/update-boot-ctxr"
                                     run "$d/k114s.compat" packages -Su;    check "K114s: image hook that copies boot.bin is stopped" 1 "would copy boot.bin over it"
rm "$root/usr/local/lib/omarchy-j714s/update-boot-ctxr"
                                     run "$d/k114s.compat" packages -Su;    check "K114s: no image hook, Stage 2 kept" 0
nomount=;                            run "$d/k114s.compat" packages -Su;    check "K114s: ESP not mounted is stopped" 1 "not mounted"
nomount=1
printf 'aura stage2 .. apple,j714s ..' > "$root/boot/efi/m1n1/boot-ctxr.bin"
touch "$root/etc/omarchy-k114s/allow-boot-package-change"
                                     run "$d/k114s.compat" packages -Su;    check "K114s: override allows once" 0 "omarchy-k114s boot guard"
                                     run "$d/k114s.compat" packages -Su;    check "K114s: override is single use" 1

echo "-- K114s ESP space"
min=999999999999;                    run "$d/k114s.compat" esp;             check "too little free: stopped" 1 "K114s space guard: stopped. The EFI partition"
min=1;                               run "$d/k114s.compat" esp;             check "enough free: goes through" 0
nomount=; min=1;                     run "$d/k114s.compat" esp;             check "ESP not mounted: stopped first" 1 "not mounted"
touch "$root/etc/omarchy-k114s/allow-low-esp"
nomount=1 min=999999999999;          run "$d/k114s.compat" esp;             check "allow-low-esp skips the space check" 0
nomount=;                            run "$d/k114s.compat" esp;             check "allow-low-esp never skips the mount check" 1 "not mounted"

# the default minimum (no M5_ESP_MIN_FREE) is 100 MiB; a fake df reports the free bytes, or fails
df_esp() { # df_esp FREE_BYTES|fail
  printf '#!/bin/sh\n[ "$FAKE_DF" = fail ] && exit 1\necho Avail; echo "$FAKE_DF"\n' > "$d/bin/df"; chmod +x "$d/bin/df"
  out=$(env PATH="$d/bin:$PATH" FAKE_DF="$1" M5_GUARD_TEST=1 M5_ROOT=$root M5_DT_COMPATIBLE=$d/k114s.compat M5_NO_MOUNTCHECK=1 "$guard" esp 2>&1); rc=$?
  rm -f "$d/bin/df"
}
rm -f "$root/etc/omarchy-k114s/allow-low-esp"
df_esp 104857599;                    check "default minimum: 100 MiB - 1 byte is stopped" 1 "needs at least 100 MiB"
df_esp 104857600;                    check "default minimum: exactly 100 MiB goes through" 0
df_esp fail;                         check "df failure fails closed" 1 "could not be read"

((fail)) && { echo "FAILED"; exit 1; }
echo "all passed"
