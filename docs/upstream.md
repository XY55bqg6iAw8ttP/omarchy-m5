# Upstream tracker

One table for everything from this repo that should land upstream. Each row moves left to right:
**found → proven here → sent → merged**. A row is sent only when its evidence column is filled in
from a real J714s. Rows that need more testing stay in "Waiting on a test" until that test is done.

Rules for sending:

- One small change per pull request, from a TripleU613 fork, with a sign-off where the project asks for one.
- Technical description only: the problem, the cause, the change, how it was tested.
- Other people's work is theirs to send. From us they get a test report on their pull request.
- Check the target project for an existing fix or pull request first.

## Sent

| Change | Where | Status |
| --- | --- | --- |
| T6050 PCIe: let the auto-PM storage domain gate itself | [aurora-silicon/aura#203](https://github.com/aurora-silicon/aura/pull/203) | merged 2026-11-13 |
| drm/apple: soft-depend on the T6050 combo PHY module | [aurora-silicon/linux#1745](https://github.com/aurora-silicon/linux/pull/1745) | merged 2026-11-13 |
| AVE: T6050 encoder on the 27.3 firmware | [aurora-silicon/linux#1747](https://github.com/aurora-silicon/linux/pull/1747) | merged 2026-11-13 |
| ANE: T6050 on the 27.3 firmware | [aurora-silicon/linux#1746](https://github.com/aurora-silicon/linux/pull/1746) | open |

## Ready to send (proven on the J714s)

| # | Change | Evidence | Target | Status |
| --- | --- | --- | --- | --- |
| R1 | Mount `/boot` and `/boot/efi` from the partitions the system booted from (two Omarchy installs on one disk share filesystem IDs) | [`duplicate-boot-ids.md`](duplicate-boot-ids.md); reproduced, fixed, confirmed across two restarts (v272-4, v272-7) | to find: installer (fstab) or packages repo (generator) | to send |
| R2 | Kernel config: the IPv6 hop-limit and routing-header matches `ufw`'s IPv6 rules need | commit `53d930d`; `ufw.service` failed on every boot before, starts by itself on v272-7 | to find: upstream kernel config, if it has the same gap | to check, then send |
| R3 | J714s: load the `aop` module at boot after vendor firmware | firmware j714s9; sound cards at boot on v272-4 and v272-7 | to find: packages repo, if upstream has the same blacklist + skip | to check, then send |

## Test reports for other people's work

| # | Whose | What we saw on the J714s | Where to report | Status |
| --- | --- | --- | --- | --- |
| T1 | FatBoy721: T6050 HDMI (v2) | Samsung Odyssey G9 (G91SD), 27.2, kernel v272-7: 5120x1440 at 60/120/144 Hz and 3840x2160 at 60 Hz. With v1: 5120x1440 at 60 Hz worked, 3840x2160 at 60 Hz stayed blank | his pull request or branch, if one is open | to send |
| T2 | Jens Axboe: 27.2 AOP endpoints (#1645, merged) | sound cards, sensors, speakerguardd v2 gate passes, speakers heard | owners' thread [omacom/linux-aurora#293](https://github.com/omacom/linux-aurora/issues/293) | to send |
| T3 | Isaac-Duarte: #1921 dock third display | applied on v272-7 together with the HDMI device tree; boots; USB-C DisplayPort on the left non-DFU port works. No dock tried. With HDMI and #1921 together no display engine is left as a merged-mode peer | nothing to report until a dock is tried | waiting on a test |

## Waiting on a test

| # | Change | The test it waits for |
| --- | --- | --- |
| W1 | J714s in the installer: 27.2 Mach-O Stage 1, "Finish setup" text, the 15 s Stage 1 window | a fresh install with our installer on a J714s |
| W2 | J714s camera and DCP rows for 27.2 (Aura tables) | compare with what upstream has now; a camera capture on v272-7 |
| W3 | ANE 27.2 pin (retarget #1746 from 27.3 to 27.2) | an ANE workload on 27.2, not just the device coming up |
| W4 | AVE 27.2 layout | an encode on 27.2 (today: probe only) |

## Open problems found here (no fix yet)

| # | Problem | Notes |
| --- | --- | --- |
| P1 | DisplayPort on the right USB-C port never trains (twelve `link fault 22`, 640x480 fallback) | same on v272-4 and v272-7; left non-DFU port works |
| P2 | The left DFU port shows no plug event and no display in Linux | the port is device-only in our build; check upstream's device tree |
| P3 | A DisplayPort cable plugged in at boot was not detected once (replug fixed it) | seen once on v272-7 |
| P4 | Every installer image writes the same filesystem IDs | R1 works around it for the boot partitions; the root ID is still shared |
