# Release 10 plan (work notes, kept in the repo so they survive)

Started 2026-11-24. Builds and packages live on ush (`~/m5/work`, `~/m5/pkgs`), never only on the work PC.

## Contents

| Piece | Version | State |
| --- | --- | --- |
| Kernel | v272-19: patches/j714s-27.2/linux rebased from 677be395b9d2 onto aurora-silicon/linux main 93e92d293a25; drops what upstream merged (0020 = #1721 at least); adds 0022 (N1 WPA/WPA2 mixed, ja-818) and 0023-0026 (J716s camera and sound) | **built and booted on the J714s 2026-11-24** (pin 0c1f7e707784, 11 patches; draft release build-linux-v272-19). Tests 1-3 and 6 pass; 4-5 need the owner |
| Firmware | omarchy-aurora-firmware **j714s16** (VRR off, #25; no own aurora_drv_video.so, depends on libva-v4l2_request-avd -2, #34). Installer 0013 still names j714s15: re-pin it to j714s16 (2c4d90d5…, release firmware-j714s16) before building | rebuilt on ush 2026-11-24, byte-identical to the Mac's; draft release build-fw-j714s15 |
| Hyprland | hyprland-m5 0.57.2-4 | in release 9 already |
| m1n1-aurora | v272-4 (Aura 0008) | stays v272-4: Aura b15-b17 have nothing for the T6050 |

Upstream gained this week (in the new base): T6050 deep-sleep series (#2657, #2698, #2739, #2718, #2606, #2611),
DP pin D beside a running USB 3 link (#2681), PCIe Clock PM mask (#1618), CPU caches (#2654), #2117, #2113, #2085, #1721.

## Tests on the J714s (unattended where possible; v272-18 stays the Limine fallback)

1. Boots unattended (auto-unlock key), no failed units, `uname -r` is v272-19.
2. Wi-Fi joins (and 0022 does not break the CCMP-only network); Bluetooth; USB-C on all three ports.
3. Internal display, brightness, GPU (`glxinfo -B` aurora); camera streams (J714s keeps setfile 2226_02 with 0023).
4. s2idle: `systemctl suspend`, owner presses a key, Wi-Fi and displays back. Watch the new deep-sleep code: `journalctl -k -b | grep -i sleep`.
5. With the owner: G9 on HDMI across a sleep; the log line "HDMI: setting up the output again (after system sleep)" (#22).
6. Speakers still gated by the safety service; jack works.

Release when 1-4 and 6 pass; 5 is reported on #22 when the owner has time.

## After the release

Close #25 (VRR off ships). Post the 0022 J714s result on #28. Update README, docs/maintenance.md, docs/upstream.md.

## Release pipeline state (2026-11-24)

- Done: `installer/patches-j714s-r2/0013` (53e1b5c): set `j714s-dev-runtime-1438d54ecdd3`, TREE `ec7ae12a`; `rebuild-installer-tree.sh DEST upstream-27.3 j714s j714s-r2` reproduces it. The two changed packages (`.zst`) are on ush in `~/m5/pkgs/r10/`.
- **Blocked: the inputs bundle can't be signed.** `finish-inputs.py --signing-home` needs the private half of the developer signer `0DA040FF…B6D116B1`, kept in the work PC's `~/m5/private/installer-dev-signing`, which was deleted with `~/m5` on 2026-11-24. There is no other copy on the work PC or ush. Options: find a backup of that directory, or make a new developer signer and change the profile's trust (`image-builder/builder/profiles/j714s/candidate-trust/{policy.json,public.asc}`) in a new patch, as 0007 of `installer/patches` did when the fork's key was lost. That changes which key the image trusts, so it's the owner's call.
- Not started (wait for the bundle): inputs release, `installer-image.yml` image-version 10, update-check. `installer-app.yml` and the `omarchy-j714s-10` prerelease wait for the owner's sleep test anyway.
- PR #29 changed only `installer-app.yml`, `installer/app/*` and `installer/patches-j716s`; none of them feeds `installer-image.yml`, so the J714s image is unaffected.

## Watching for the next kernel (open upstream, 2026-11-24)

- aurora-silicon/linux #3023, #3025, #3036 (DjDeveloperr): G17 (M5 GPU) idle housekeeping, sync-input chains, event worker placement.
- aurora-silicon/linux #2201 (K116s deep sleep), #2007 (PMIC RTC alarm: unattended s2idle tests), #2190 (idle power).
- aurora-silicon/aura #506: PMP values onto aliasless PMP nodes, handoff hardening.
- #33 here: the camera light on top of upstream's indicator.
