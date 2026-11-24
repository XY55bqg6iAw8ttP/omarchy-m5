# Release 10 plan (work notes, kept in the repo so they survive)

Started 2026-11-24. Builds and packages live on ush (`~/m5/work`, `~/m5/pkgs`), never only on the work PC.

## Contents

| Piece | Version | State |
| --- | --- | --- |
| Kernel | v272-19: patches/j714s-27.2/linux rebased from 677be395b9d2 onto aurora-silicon/linux main 93e92d293a25; drops what upstream merged (0020 = #1721 at least); adds 0022 (N1 WPA/WPA2 mixed, ja-818) and 0023-0026 (J716s camera and sound) | **built and booted on the J714s 2026-11-24** (pin 0c1f7e707784, 11 patches; draft release build-linux-v272-19). Tests 1-3 and 6 pass; 4-5 need the owner |
| Firmware | omarchy-aurora-firmware j714s15 (VRR off by default, #25) | rebuilt on ush 2026-11-24, byte-identical to the Mac's; draft release build-fw-j714s15 |
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
