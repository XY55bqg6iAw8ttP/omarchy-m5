# Repo maintenance

Pull requests and issues on this repo: what came in, what we did, where it stands. Newest first.

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
| [#11](https://github.com/betizzel/omarchy-m5/issues/11) A channel switch, `omarchy refresh pacman` or `omarchy reinstall` drops the image's `IgnorePkg` pin and downgrades the kernel, m1n1 and U-Boot | chrisohearn | Confirmed against omacom/omarchy v4.5.0 (`omarchy-refresh-pacman` copies the channel template over `/etc/pacman.conf`, then `pacman -Syyuu`). Fix (646d264, refined in a later commit): firmware j714s11 ships a pacman hook outside `pacman.conf` (`00-omarchy-j714s-boot-guard.hook` + `j714s-boot-guard`) that stops any transaction replacing `linux-aurora`, `m1n1-aurora`, `uboot-aurora` or `omarchy-aurora-firmware` with a build that isn't a J714s build, or removing them. Tested in a throwaway container on ush (below). Not in an image yet | open until it ships in an image |
| [#10](https://github.com/betizzel/omarchy-m5/issues/10) K114s on release 3, `apple,k114s` installer admission offered | chrisohearn | Said yes to a PR, labelled as tested on his machine only, with the README pointing K114s owners to [his repo](https://github.com/chrisohearn/omarchy-m5p-oled). The trackpad fix he found (aurora-silicon/linux #1568, open draft for the K114c) isn't needed on the J714s, whose trackpad already works, and isn't in our series | open, waiting for his PR |
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
installed, the hook runs there too. The next image build will show whether that happens. Not
installed on any Mac.
