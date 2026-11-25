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

- `installer/patches-j714s-r2` 0013 (kernel v272-19, firmware j714s16, set `j714s-dev-runtime-07717f8c82db`) and 0014 (new developer signer `547AF6CC…BC5DF9F6`): TREE `01350e1a` (1fc56a3).
- Inputs: [`installer-build-inputs-j714s-be1d4b253d13`](https://github.com/betizzel/omarchy-m5/releases/tag/installer-build-inputs-j714s-be1d4b253d13), signed with the new key.
- Image: run 45486430336 → [`j714s-developer-image-omarchy-j714s-10`](https://github.com/betizzel/omarchy-m5/releases/tag/j714s-developer-image-omarchy-j714s-10), zip sha256 `fb1974d5…`, every inspection check passed, `boot-ctxr.bin` 10389172 bytes.
- update-check: run 45490197032, pacman exit 0, every pinned J714s package kept. **To decide:** `alsa-ucm-conf-aurora` and `aurora-audio` (signed set, speaker path) are not in `IgnorePkg` and update from omacom's repo (10.aurora3-2, 4.1.aurora3-6), with `speakersafetyd` 2.0.1-2. Pin them, or check the new versions with speakerguardd-v2 on the Mac.
- Left: the owner's G9 test (#22), then `installer-app.yml` and the `omarchy-j714s-10` prerelease, then close #25 and #34.

## Watching for the next kernel (open upstream, 2026-11-24)

- aurora-silicon/linux #3023, #3025, #3036 (DjDeveloperr): G17 (M5 GPU) idle housekeeping, sync-input chains, event worker placement.
- aurora-silicon/linux #2201 (K116s deep sleep), #2007 (PMIC RTC alarm: unattended s2idle tests); #2190 (idle power) merged 2026-11-25, in the v272-20 candidate.
- aurora-silicon/aura #506: PMP values onto aliasless PMP nodes, handoff hardening.
- #33 here: the camera light on top of upstream's indicator.
- Merged since v272-19's base (take at the next re-pin): aurora-silicon/linux #3110 (N1 Wi-Fi: gate commands during host sleep, 2026-11-25), #3120 (centauri Wi-Fi/Bluetooth: scan lock stalls, abort sync, BT ring, 2026-11-25).

## Results on our J714s (2026-11-24)

- Tests 1-3 and 6 pass on v272-19 (see the v272-19 section of patches/j714s-27.2/README.md).
- Test 4, s2idle with the owner: suspended 15:44, woken by a key 15:51 in the same boot; eDP-1 back at 120 Hz,
  Wi-Fi reconnected with internet, Bluetooth on, 5 sound cards, no failed units, no kernel errors after the wake.
  The HDMI re-setup ran on wake ("HDMI: setting up the output again (after system sleep)"); no G9 attached.
- Test 5 (G9 picture across a sleep, #22): still to do with the owner.
- The owner removed the auto-unlock key (2026-11-24): every boot now needs the disk passphrase, so kernel tests
  need the owner at the Mac.

## Next kernel candidate: v272-20 (rebuilt 2026-11-25, not booted)

aurora-silicon/linux main `7a4afed5b4d1` (2026-11-25; adds #2190 idle power from the watch list, #3110 and
#3120, and about 100 other upstream commits) plus the same 11 patches. 0006 (HDMI hold presents) needed a
context-only fix: upstream now sets `WRITE_ONCE(dcp->pipe_off, false)` on the line where 0006 adds
`dcp_hdmi_hold_presents(dcp, "power on")`; both lines kept. The other ten applied clean. Built on ush
(`~/m5/work/k20b`, series in `~/m5/work/v272-20b-patches`), sha256 `a79ce90c…`, draft release
build-linux-v272-20. It replaces the first v272-20 build (`4d8a19b2e415`, `dc9cde66…`, `~/m5/work/k20`),
which was never booted. Boot test needs the owner at the Mac (the disk passphrase); then commit the recipe
(pin `7a4afed5b4d1df7489c4be316d05e3b6c98b23dc`, pkgrel 20, the regenerated patches and sums) and publish to
[omarchy-m5] if it passes tests 1-4.
