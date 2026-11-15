# Repo maintenance

Pull requests and issues on this repo: what came in, what we did, where it stands. Newest first.

## 2026-11-15: #16, one boot guard for every M5 board (chrisohearn)

[#16](https://github.com/betizzel/omarchy-m5/pull/16) from chrisohearn generalises the #11 guard:
`j714s-boot-guard` becomes `m5-boot-guard` (the old name stays as a shim), the board comes from the
device tree's `compatible`, and a K114s gets a Stage 2 check and an ESP free-space hook
(`01-omarchy-m5-esp-space.hook`). It bumps the firmware package to j714s13 with matching sums. Merged
as merge commit 82d914e, his commit 6a49471 kept, on the owner's call before testing: main doesn't
reach any Mac, because images pin packages by manifest hash. The tests below are the gate for the
next release. [Merge note](https://github.com/betizzel/omarchy-m5/pull/16#issuecomment-6900732145).

Tested after merging (work dir `~/m5/work/pr16`):

- Build: `omarchy-aurora-firmware-20261014.j714s13-1-aarch64.pkg.tar.zst`, sha256 `af8a8d00…3bc7`,
  55533 bytes, from 82d914e in `alarm-builder:20261112` on ush (same `fw-build.sh` as j714s12;
  copy in `~/m5/work/pkgs-fw-j714s13`). Against j714s12, the file list loses
  `00-omarchy-j714s-boot-guard.hook` and gains `00-omarchy-m5-boot-guard.hook`,
  `01-omarchy-m5-esp-space.hook` (644) and `m5-boot-guard` (755). `j714s-boot-guard` is the shim, and
  the four files are byte-identical to the recipe. Nothing else changed. `test.sh` isn't packaged
  and makepkg doesn't run it.
- `test.sh` (his tests, normal user, x86 PC): all passed. That is 60 `ok`; the 4 checks against
  stock boot hooks skip because those hooks aren't on the PC. The same check run by hand against the
  J714s's own hooks (read over SSH: 90-mkinitcpio-install in /usr/share and /etc/pacman.d,
  90-mkinitcpio-apple-install, 91-omarchy-mac-boot-initramfs, 95-m1n1-install,
  95-omarchy-mac-dtb-overlays, 96-omarchy-j714s-boot-ctxr, 81-omarchy-mac-limine-deploy) found every
  Path target in the ESP hook.
- The #11 container test (`guard-test16.sh`, the 21 cases above plus a case 0 and four ESP cases),
  in privileged throwaway containers: j714s12 baseline with the J714s `compatible`; j714s13 (installed
  as an upgrade from j714s12) with the J714s's exact `compatible` (`apple,j714s apple,t6050
  apple,arm-platform`, served at `/sys/firmware/devicetree/base`); j714s13 with no readable device
  tree. All three: 0 FAIL, and every case's full pacman output is identical to the baseline. The only
  differences are the renamed 00 hook line and the extra 01 hook line on transactions that pass.
  The upgrade from j714s12 runs the old hook and removes the old hook file.
  ESP cases on the J714s contexts: with a 60 MiB `/boot/efi`, a J714s kernel upgrade and a firmware
  reinstall go through (the 01 hook runs and does nothing), and a generic kernel is still stopped by
  the package guard. With `/boot/efi` not mounted, a J714s kernel rollback goes through. A
  `compatible` of `apple,k114s` as a control: the K114s checks fire (`/boot/efi is not mounted`), so
  the containers really read the device tree.
- On the J714s (release 6 fresh install with j714s12, no reboot): `pacman -U` j714s13 over j714s12
  went through, running the old hook. (a) Reinstalling j714s13 went through, exit 0. The 01 hook
  printed its line ("Checking free space on the EFI partition (K114s)...") and nothing else, and
  `m5-boot-guard esp` run directly exits 0. (b) A fake generic `linux-aurora 7.2.11.aurora16-1` was
  **stopped** ("STOPPED by the J714s boot guard", message as in j714s12), exit 1, "no packages were
  upgraded". Before the install, after it, after (a) and after (b), these were all unchanged:
  `linux-aurora 7.3.0.aurora17.v272-11`, `m1n1-aurora 1.6.1.aurora24.v272-3`,
  `uboot-aurora 2026.07.aurora6.j714s3-1`; sha256 of vmlinuz `0779a659…`, initramfs `b160b621…`,
  `m1n1/boot-ctxr.bin` `bf702326…`, UKI `0f728ed7…`, `limine.conf` `263d2f33…`, `/etc/pacman.conf`
  `4fb09042…`. The rebuilds came out byte-identical. ESP free stayed at 146882560 bytes (140 MiB).
  `pacman -Qk` found 0 missing files, and no unit failed.

The ESP space check can't block a J714s update: `m5-boot-guard esp` returns before any check unless
the `compatible` has `apple,k114s`. Not seen yet: j714s13 through a reboot, and the K114s checks on a
real K114s transaction (his report covers a direct run only).

## 2026-11-15: #15, the engine's firmware rebuild path picks this device's row (chrisohearn)

[#15](https://github.com/betizzel/omarchy-m5/pull/15) from chrisohearn: `installer/patches-j714s-r2/0010`.
`action_rebuild_vendorfw` now calls `omarchy_firmware.installed_ipsw`, which skips rows restricted
to other device classes, where before it took the first row with the installed version. This
follows up the note on #13: a K114s would have got 26B123. TREE is `764b1ee1`, engine
`v0.9.2-omarchy.20261115.d33f2cef00c4`, plus a row in `installer/README.md`. Merged as merge
commit 37ce4ab with his commit a672454 kept. There was no conflict, because the PR was based on
c1b8137. [Comment](https://github.com/betizzel/omarchy-m5/pull/15#issuecomment-6900028479).

Checked before merging, with the same method as #13 (work dir `~/m5/work/pr15`):

- Tree: 0001-0010 rebuilds to `764b1ee1`. Against `fdd3eb0e` only four files under `Engine/` differ
  (overlay `omarchy_firmware.py` and its test, the runtime patch, `source-lock.json`). Applying 0010
  prints `1 line adds whitespace errors`, a context line of the nested patch, which is harmless.
- Engine: `Engine/prepare-engine.py` run twice reproduced `eac6cf71…`, 17914686 bytes. Against
  `c979ebe82723` only `version.tag`, `omarchy_firmware.py` (the new helper) and the one call in
  `main.py` differ. `IPSW_VERSIONS` and `DEVICES` are identical.
- Rebuild path, old loop vs. helper on the shipped rows (`scripts/rebuild-row-check.py`): for
  `j714sap`, 27.2 still gives 26B123 (`26.2.123.0.0,0`) and 12.3, 12.3.1 and 13.5 are unchanged.
  The rows restricted to other boards (14.8.3, 26.6, 26.6.2) now give "unsupported" where they used
  to give another board's row. A J714s can't reach them: its device minimum is 27.2 and its only
  stub row is 26B123.
- Tests (`test/all`): Engine tooling 77, engine overlay 449 (with `FirmwareRebuildTests` 3/3),
  scripts 306, Packaging 36, all passing.
- App: `make-release-inputs.py` locally against release 7's image, offline and online. Compared
  with main's tree and engine, only `engineVersion`, `engineDigest`, the engine file name and size
  and `downstreamRevision` differ (`trust_root_fingerprint` differs too, only because each run uses
  a throwaway key). The catalog lists `apple,j714s` only and `installer_data.json` is the same.
  `installer/app`, `image-builder/`, `Integration/` and the Recovery sources are unchanged, so the
  default board and the image are too. Unlike #13, there was no CI app run and no test releases.

Engine published for the next J714s build, replacing `c979ebe82723`: release
[`engine-v0.9.2-omarchy.20261115.d33f2cef00c4`](https://github.com/betizzel/omarchy-m5/releases/tag/engine-v0.9.2-omarchy.20261115.d33f2cef00c4),
asset `installer-v0.9.2-omarchy.20261115.d33f2cef00c4.tar.gz`, sha256
`eac6cf71489f993e7b24780a5854f41d15b7dab239db3a1b3064d37fa8adc89b`, 17914686 bytes (downloaded
back and checked). The next build still needs new build inputs (`finish-inputs.py` bundles the
engine). This engine has not run an install, or a firmware rebuild, on hardware yet.

## 2026-11-15: #13, the K114s admitted in developer builds (chrisohearn)

[#13](https://github.com/betizzel/omarchy-m5/pull/13) from chrisohearn: `installer/patches-j714s-r2/0009`
(engine `k114sap` device, the 26B8125 stub row, the board 0x14 gate, `stage1-k114s` Mach-O members,
k* trackpad firmware collection), TREE `fdd3eb0e`, engine `v0.9.2-omarchy.20261115.c979ebe82723`,
`make-release-inputs.py --board` and `CHECK_APP_BOARD`. Merged after release 7 as merge commit
a46d36c (his commit 47dca43 kept); the one conflict, the 0008/0009 rows in `installer/README.md`,
kept both. His README section moved verbatim to [`docs/boards/k114s.md`](boards/k114s.md)
(b2a9a03); the README keeps an "Other M5 boards" entry.

Checked before merging, because the engine pin moves for the J714s too:

- Tree: 0001-0009 rebuilds to `fdd3eb0e` (release 7's set still gives `fe2218e7`).
- Engine: `Engine/prepare-engine.py` run twice reproduced `e220f68f…`, 17914568 bytes (four
  identical repacks). Against release 7's engine only `main.py`, `omarchy_asahi.py` and `version.tag`
  differ: the added `k114sap` device, 26B8125 row (devices `[k114sap]`) and `BOARD_MACHO` row, the
  board gate (equivalent for `j714sap`: chip 0x6050, board 0x08) and the k* multitouch pass. On a
  J714s that pass finds nothing: the J714s identity in the 26B123 manifest has FUD files only under
  `Firmware/`, so `fud_firmware/` holds `Firmware` and `j714s`. The firmware rebuild path picks the
  first 27.2 row, still 26B123.
- Tests (`test/all`): Engine tooling 77, engine overlay 446 (release 7: 441), scripts 306, Packaging
  36, all passing.
- Unchanged between the two trees: `image-builder/` (with `stage1_qualification.py`),
  `Integration/` and the Recovery sources; the engine is not inside the image. So the image,
  its `installer_data.json` (j714sap, `board-macho-ctxr-v1`, 27.2) and its Stage 1 members
  (`esp/aurora/stage1-j714s.{bin,macho}`, `esp/m1n1/boot-ctxr.bin`) would be the same; no image
  was rebuilt.
- App: `make-release-inputs.py` locally, against release 7's image, for both variants. The
  release 7 tree and engine reproduce release 7's published catalogs byte for byte. The PR tree
  differs only in `engineVersion`, `engineDigest`, the engine file name and size and
  `downstreamRevision`. Then a CI run on the merge commit: `installer-app.yml` run 43748023300
  (online, release 7's image, app 2.3.16). The run used a temporary `test-pr13-engine`
  prerelease and published `test-pr13-app`; both releases and the `test-pr13` branch were
  deleted afterwards. Same result in its sealed catalog: `apple,j714s` only, `metadataDigest`
  `0357666f…` and `payloadDigest` `6d10e8b3…` equal to release 7's, and `check-app.sh` passed
  with the default board.

Engine published for the next J714s build: release
[`engine-v0.9.2-omarchy.20261115.c979ebe82723`](https://github.com/betizzel/omarchy-m5/releases/tag/engine-v0.9.2-omarchy.20261115.c979ebe82723),
asset `installer-v0.9.2-omarchy.20261115.c979ebe82723.tar.gz`, sha256
`e220f68f9523ccbf184344b5940f38f4184e9d3582a985a6c404eb04f71e82a9`, 17914568 bytes (downloaded
back and checked). The next build also needs new build inputs: `finish-inputs.py` puts the
engine in the bundle, and `afdde351c894` carries the old one. This engine has not run an install
on a J714s yet.

## 2026-11-15: invitation to send M5 work here

Added [`CONTRIBUTING.md`](../CONTRIBUTING.md), a pull request template and a hardware test report
issue template (commit 213aea2), and a short "Send your M5 work here" paragraph at the top of the
README. Then posted:

| Where | Link |
| --- | --- |
| Pinned issue in this repo | [#12](https://github.com/betizzel/omarchy-m5/issues/12) |
| M5 owners' thread | [omacom/linux-aurora#293 comment](https://github.com/omacom/linux-aurora/issues/293#issuecomment-6898406716) |

@-mentioned in #12 (each checked against this repo or their public M5 work first): rolotrealanis98,
edimoldovan, FatBoy721, Isaac-Duarte, chrisohearn, joshuaswarren, sithglan, erikwb, MarianoMiguel,
kazuhidet, funkzy, MikaVohl, nickyrice04, XY55bqg6iAw8ttP. Thanked by name only, not asked to send
work here: DjDeveloperr, Ryan Murray, Jens Axboe, Diljit Singh (aurora-silicon maintainers and core
contributors) and Satya Benson (satchlj, an aurora-silicon member). The #293 comment mentions nobody.

### #12 text

> This repo builds one **edge** Omarchy image for the 14-inch MacBook Pro with M5 Pro (J714s) today, from the work of many people, with each part credited. If you work on Linux or Omarchy for an M5 Mac, you are welcome to send your work here.
>
> ## What is in it now
>
> [Release 6](https://github.com/betizzel/omarchy-m5/releases/tag/omarchy-j714s-6) (a prerelease), kernel v272-11, Apple's 27.2 firmware. On one J714s: all 15 CPU cores, GPU, the internal panel at 120 Hz, keyboard and trackpad, Wi-Fi, Bluetooth, sound cards and speakers behind speaker protection, fan control, firewall. HDMI and DisplayPort on the left USB-C port were seen on release 5's kernel. Open: the right USB-C port and the DFU port show no picture, no deep sleep, microphones are very faint, the camera and Neural Engine come up as devices but no picture or workload has been checked. The full table, with whose work each row is, is in the [README](https://github.com/betizzel/omarchy-m5#what-works).
>
> Today (2026-11-15) the first from-scratch install of release 6 passed on that J714s: the installer shrank macOS and installed; kernel v272-11; sound cards, Neural Engine and camera devices, Wi-Fi, Bluetooth and the firewall came up. The speaker switch-over ran before the speaker card appeared at first boot and passed when run by hand; the fix (firmware j714s12) is committed and goes into the next image. External displays have not been re-checked on this install yet.
>
> ## How to send your work
>
> - **Open a pull request here with your own patch, recipe or doc change**, under your own name: `git format-patch` from your branch keeps your `From:` and `Signed-off-by:`. [CONTRIBUTING.md](https://github.com/betizzel/omarchy-m5/blob/main/CONTRIBUTING.md) says which directory holds what.
> - **Keep your upstream pull request** (aurora-silicon/linux, aurora-silicon/aura, omacom). Upstream is the goal; this repo carries a copy until yours merges there, then drops it.
> - **Test reports** are welcome too: [test report template](https://github.com/betizzel/omarchy-m5/issues/new?template=test-report.md). Please say what you saw on the hardware and what you only checked by command.
> - **Other M5 boards** are welcome when their owner tests them. A board gets its own image once an owner of that board has tested it here.
>
> ## People whose work is already in it or who are working on M5 boards
>
> - @rolotrealanis98 (J716s): the 27.2/27.3 GPU InitData and firmware 27 display patches (kernel 0001-0004), panel VRR (0014).
> - @edimoldovan (J714c): front camera tuning and the camera light (kernel 0007-0009, 0011-0013), the J714 sound profiles.
> - @FatBoy721 (J714s): the HDMI port, HDMI hold and HPD forwarding (kernel 0017-0019, Aura 0007), seen on a Samsung Odyssey G9.
> - @Isaac-Duarte (J714s): fan targets (kernel 0024, reproduced here), dock display routing and the DP tunnel fix (0020-0023, 0025-0026; carried, no dock tried here yet).
> - @chrisohearn (K114s): the reports behind release 6's RFCOMM and hyprland-m5 fixes (#8, #9) and behind the boot guard for the kernel pin (#11, committed, not in an image yet), and the K114s installer admission offered in #10.
> - @joshuaswarren: J714c and T6050 work in the kernel base (tiled 5K displays, firmware 27 display modes) and the M5 Max 27.3 GPU build in Aura 0003.
> - @sithglan (K116s): sent the K114/K116 27.2 GPU identity (kernel 0005) and the PMP power domains through s2idle (0028); the Aura chainload copy stub.
> - @erikwb: T6050 USB4 and external display work in the kernel base, which USB-C DisplayPort builds on.
> - @MarianoMiguel: the T6050 die0 range over the ISP watchdog, merged upstream and in the kernel base.
> - @kazuhidet (M4 Air): the busy-card discovery in the firmware package that lets PipeWire find the speakers.
> - @funkzy: an earlier 27.2 display method table (credited in the older `patches/linux-aurora` series); M5 Ultra Mac Studio work upstream.
> - @MikaVohl (J716s): the omarchy-M5-pro repo, watched.
> - @nickyrice04 (M5 Max): the ilinux repo, watched.
> - @XY55bqg6iAw8ttP (J714c): the trackpad reset, SMC sensors and keyboard backlight device tree, open upstream.
>
> If you are missing from this list, or something here is wrong, please say so below.
>
> ## Thanks
>
> The image is built on aurora-silicon and omacom. Thank you to DjDeveloperr, Ryan Murray (RyanTheTide), Jens Axboe, Diljit Singh, Satya Benson and everyone else working there: the kernel, Aura, the M5 device trees, speaker protection and the GPU driver this image uses are theirs.
>
> 🤖 Generated with [Claude Code](https://claude.com/claude-code)

### #293 comment text

> J714s (14-inch M5 Pro) update: [omarchy-j714s 6](https://github.com/betizzel/omarchy-m5/releases/tag/omarchy-j714s-6) is out as an edge (prerelease) image, kernel v272-11 on the 27.2 stub.
>
> Today the first from-scratch install of it passed on one J714s: the installer shrank macOS and installed, and on first boot the sound cards, Neural Engine and camera devices, Wi-Fi, Bluetooth and the firewall came up. The speakers needed the speaker switch-over run by hand (it ran before the speaker card appeared; the fix is committed for the next image). External displays have not been re-checked on this install yet.
>
> Anyone who wants to send M5 work there under their own name, or post a test report from their board, is welcome: https://github.com/betizzel/omarchy-m5/issues/12. Upstream pull requests stay the goal; the repo drops its copy of a change once it merges upstream.
>
> 🤖 Generated with [Claude Code](https://claude.com/claude-code)

## 2026-11-15

| Item | From | What we did | State |
| --- | --- | --- | --- |
| [#11](https://github.com/betizzel/omarchy-m5/issues/11) A channel switch, `omarchy refresh pacman` or `omarchy reinstall` drops the image's `IgnorePkg` pin and downgrades the kernel, m1n1 and U-Boot | chrisohearn | Confirmed against omacom/omarchy v4.5.0 (`omarchy-refresh-pacman` copies the channel template over `/etc/pacman.conf`, then `pacman -Syyuu`). Fix (646d264, refined in a later commit): firmware j714s11 ships a pacman hook outside `pacman.conf` (`00-omarchy-j714s-boot-guard.hook` + `j714s-boot-guard`) that stops any transaction replacing `linux-aurora`, `m1n1-aurora`, `uboot-aurora` or `omarchy-aurora-firmware` with a build that isn't a J714s build, or removing them. Tested in a throwaway container on ush and on the J714s (below). Shipped in firmware j714s12 in [release 7](https://github.com/betizzel/omarchy-m5/releases/tag/omarchy-j714s-7) | closed after release 7 was published |
| [#10](https://github.com/betizzel/omarchy-m5/issues/10) K114s on release 3, `apple,k114s` installer admission offered | chrisohearn | Said yes to a PR, labelled as tested on his machine only, with the README pointing K114s owners to [his repo](https://github.com/chrisohearn/omarchy-m5p-oled). The trackpad fix he found (aurora-silicon/linux #1568, open draft for the K114c) isn't needed on the J714s, whose trackpad already works, and isn't in our series | PR [#13](https://github.com/betizzel/omarchy-m5/pull/13) merged (see above) |
| [#9](https://github.com/betizzel/omarchy-m5/issues/9) Kernel config: ufw `hl`/`rt` matches, RFCOMM, `pkcs8_key_parser` | chrisohearn | ufw matches since kernel v272-7 (release 5), RFCOMM and PKCS8 since v272-9; both modules load on v272-11 on the J714s | closed after [release 6](https://github.com/betizzel/omarchy-m5/releases/tag/omarchy-j714s-6) (v272-11) was published |
| [#8](https://github.com/betizzel/omarchy-m5/issues/8) hyprland-m5 0.57.2-2 moves `CMonitor` members, the stock titlebars plugin aborts Hyprland | chrisohearn | Fixed in hyprland-m5 0.57.2-3 (41d8d77, his fix 1). Crash reproduced on -2 and gone on -3 on the J714s ([upstream tracker](upstream.md)) | closed after [release 6](https://github.com/betizzel/omarchy-m5/releases/tag/omarchy-j714s-6) (hyprland-m5 0.57.2-3) was published |
| [#7](https://github.com/betizzel/omarchy-m5/pull/7) J714s HDMI on 27.3 (PR) | FatBoy721 | All three commits carried into `patches/j714s-27.2` (kernel 0017-0019, Aura 0007). HDMI seen on an Odyssey G9 with v272-7. The 27.3 directory is history | closed, not merged (carried) |
| [#6](https://github.com/betizzel/omarchy-m5/issues/6) 27.3 Aura chain test report (nvme-adopt, Touch ID on a second J714s) | FatBoy721 | Both findings recorded in [`status-and-history.md`](status-and-history.md) ("Reports from other owners on the 27.3 line") | closed (27.3 line replaced by 27.2) |

### #11: the boot guard and its test

**Why a hook.** `omarchy-refresh-pacman` overwrites `/etc/pacman.conf`, so nothing kept in that file
survives. Omarchy's `pre-refresh-pacman` user hook doesn't stop anything: `omarchy-hook` prints
"Hook failed" and carries on. An ALPM hook in `/usr/share/libalpm/hooks` runs for every
transaction, whoever wrote `pacman.conf`, and `AbortOnFail` stops a `PreTransaction` hook's
transaction before anything changes.

**How it tells a J714s build.** ALPM gives a hook the package names only. The script finds the
incoming version the way pacman did: from a package file or URL on pacman's command line
(`pacman -U`; a relative path is read from the directory pacman was started in, or by its file name), or else from the first
repository that lists the name (`-S`, `-Su`, `-Syyuu`, `repo/name`). J714s builds carry `v272`,
`up273` or `j714s` in their version; the channel's builds don't. A removal, or a version it
can't find, is refused. It judges the build, not the direction, so a newer generic build is
stopped too. `/etc/omarchy-j714s/allow-boot-package-change` allows one transaction on purpose
(the hook deletes the file when it uses it). When it refuses and `pacman.conf` has no `IgnorePkg`
but `pacman.conf.bak` does, it saves that backup as `/etc/pacman.conf.j714s-pinned` and tells the
user to copy it back. The refresh rewrites `.bak` on every run, so after a second run (the channel
switch's own error text says to rerun) `.bak` no longer has the pin.

**One guard for every board (#12).** From firmware j714s13 the guard is `m5-boot-guard`, run by
`00-omarchy-m5-boot-guard.hook` and `01-omarchy-m5-esp-space.hook`. It reads the board from the
device tree's `compatible`: `apple,k114s` is a K114s; anything else, or an unreadable device tree,
is judged as before. Compared side by side with j714s12's script in scratch roots on 21
scenarios, including (generic, M5, up273 and j714s builds, a mixed set, an unknown version, -R/-Rns/--remove, the
one-time override, a lost or saved pin, a package not installed, -U with URL/relative/absolute
files, repo/name, empty stdin, the j714s13 firmware): identical exit codes, stdout, stderr and
files. Only pacman's own output differs (a renamed hook line and one more no-op hook line).

A K114s gets two more checks. Before a boot package changes, `m1n1/boot-ctxr.bin` must carry an
`apple,k114s` device tree and the image's Stage 2 helper must know the K114s (the stock one copies
`boot.bin` over it). Before a transaction touches the files and packages a boot-image rebuild
reads, `/boot/efi` must be mounted and have 100 MiB free (a rebuild writes an 80 MB image there).
`/etc/omarchy-k114s/allow-low-esp` skips the space check only, never the mount check.

The override file is per board (`/etc/omarchy-<board>/allow-boot-package-change`).
`j714s-boot-guard` stays as a shim, and j714s12 upgrades with no step. Test:
`installer/recipes/omarchy-aurora-firmware/test.sh` (scratch root, fake pacman, no root). Written by
chrisohearn from the K114s guards in omarchy-m5p-oled.

**Test, 2026-11-15, on ush.** Firmware j714s11 was built from this recipe in `alarm-builder:20261112`
(Arch Linux ARM under qemu-user; package sha256 `8e33fed0...2a7022`) and installed in a
throwaway container with fake packages: J714s builds with the image's versions, and a local
"edge" repository holding the generic builds with #11's versions (`linux-aurora 7.2.11.aurora16-1`,
`m1n1-aurora 1.6.1.aurora23-2`, `uboot-aurora 2026.07.aurora6-1`,
`omarchy-aurora-firmware 20261014-7`). 21 cases, all as expected:

| Case | Result |
| --- | --- |
| Pin in place, `pacman -Syyuu` | IgnorePkg holds, the guard isn't triggered, an unrelated package upgrades |
| Pin removed as the refresh does it (backup, template copy), then `pacman -Syyuu`; the same with `OMARCHY_UPDATE_PACMAN=1`; `pacman -Suu` | **stopped**, all four packages listed, nothing changed |
| `pacman -U` of the generic kernel (absolute path, relative path, relative path with no `PWD` in pacman's environment as after `sudo`) or the generic firmware package | **stopped** |
| A newer generic kernel (`7.4.0.aurora18-1`) in the channel, plain `pacman -Syu` | **stopped** |
| `pacman -S edge/uboot-aurora`; `pacman -Rdd uboot-aurora` | **stopped** |
| `pacman -U` J714s v272-11 to v272-12 while the channel offers the generic build; rollback to v272-10 from a relative path; v272-12 from a relative path with no `PWD`; v272-11 from a `file://` URL | goes through |
| Override file, then `pacman -U` of the generic m1n1 | goes through once, file removed; the next generic `-U` is stopped again |
| Back to the J714s m1n1 over the generic one | goes through |
| A second refresh (`.bak` is now the template too), `pacman -Syyuu` | **stopped**; the message points to `/etc/pacman.conf.j714s-pinned`, saved at the first refusal |
| Pin restored from that copy as the message says, `pacman -Syyuu` | goes through, IgnorePkg holds |

A probe `PreTransaction` hook sorted after the guard (`50-`) never ran when the guard stopped a
transaction, and ran when it let one through: pacman stops at the failed `AbortOnFail` hook, so
later pre-transaction hooks don't act on a transaction that won't happen. `sudo` doesn't run
under qemu-user in that container, so Omarchy's `sudo env ... pacman` was run as root with the
same environment.

**Limits.** A libalpm front end other than pacman (pamac) gives no command line to read, so a
`-U` through it falls back to the repository version and may be refused (fail closed). If the
image builder upgrades these packages inside a target root after this firmware package is
installed, the hook runs there too. It doesn't: the builder installs the firmware package in the
same fresh `pacman -S` as the kernel, m1n1 and U-Boot (no upgrade, and the hook isn't on disk yet),
and release 7's image (run 43743352382) and update-check (run 43745245431) logs show the hook never ran.

**On the J714s, 2026-11-15 (release 7).** Firmware j714s12 (`4486b6c5…`, 52467 bytes, from
101a6e6: j714s11's guard plus the speaker switch-over waiting for the speaker card) was installed
with `pacman -U` over j714s10 on TripleU613's J714s, running release 6 from its from-scratch
install, without a reboot. The same steps were rehearsed first in a throwaway container on ush.

| Case | Result |
| --- | --- |
| `pacman -U` j714s12 over j714s10 | goes through (the hook isn't on disk until this transaction ends) |
| `pacman -U` j714s12 again (reinstall) | goes through; "Checking that the J714s boot packages stay J714s builds..." runs first |
| Override file absent; `pacman -U --noconfirm` of a fake generic `linux-aurora 7.2.11.aurora16-1` (one empty file) | **stopped** by the guard, exit 1, "no packages were upgraded" |

Before and after the refusal: `linux-aurora 7.3.0.aurora17.v272-11`, `m1n1-aurora
1.6.1.aurora24.v272-3`, `uboot-aurora 2026.07.aurora6.j714s3-1`; sha256 of `/boot/vmlinuz-linux-aurora`
`0779a659…`, the initramfs `b160b621…`, the UKI `0f728ed7…`, `limine.conf` `263d2f33…`,
`m1n1/boot-ctxr.bin` `bf702326…` and `/etc/pacman.conf` `4fb09042…`, all unchanged (also across the
j714s12 install, whose initramfs rebuild came out byte-identical); `pacman -Qk` found no missing files.
`systemctl cat aurora-speaker-upgrade` shows the new `ExecStartPre`. The speaker wait has not been
through a boot yet.
