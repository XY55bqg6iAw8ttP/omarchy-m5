# Repo maintenance

Pull requests and issues on this repo: what came in, what we did, where it stands. Newest first.

## 2026-11-15

| Item | From | What we did | State |
| --- | --- | --- | --- |
| [#11](https://github.com/betizzel/omarchy-m5/issues/11) A channel switch, `omarchy refresh pacman` or `omarchy reinstall` drops the image's `IgnorePkg` pin and downgrades the kernel, m1n1 and U-Boot | chrisohearn | Confirmed against omacom/omarchy v4.5.0 (`omarchy-refresh-pacman` copies the channel template over `/etc/pacman.conf`, then `pacman -Syyuu`). Fix (646d264): firmware j714s11 ships a pacman hook outside `pacman.conf` (`00-omarchy-j714s-boot-guard.hook` + `j714s-boot-guard`) that stops any transaction replacing `linux-aurora`, `m1n1-aurora`, `uboot-aurora` or `omarchy-aurora-firmware` with a build that isn't a J714s build, or removing them. Tested in a throwaway container on ush (below). Not in an image yet | open until it ships in an image |
| [#10](https://github.com/betizzel/omarchy-m5/issues/10) K114s on release 3, `apple,k114s` installer admission offered | chrisohearn | Said yes to a PR, labelled as tested on his machine only, with the README pointing K114s owners to [his repo](https://github.com/chrisohearn/omarchy-m5p-oled). The trackpad fix he found (aurora-silicon/linux #1568, open draft for the K114c) isn't needed on the J714s, whose trackpad already works, and isn't in our series | open, waiting for his PR |
| [#9](https://github.com/betizzel/omarchy-m5/issues/9) Kernel config: ufw `hl`/`rt` matches, RFCOMM, `pkcs8_key_parser` | chrisohearn | ufw matches since kernel v272-7 (release 5), RFCOMM and PKCS8 since v272-9; both modules load on v272-11 on the J714s | see the comment for the closing state |
| [#8](https://github.com/betizzel/omarchy-m5/issues/8) hyprland-m5 0.57.2-2 moves `CMonitor` members, the stock titlebars plugin aborts Hyprland | chrisohearn | Fixed in hyprland-m5 0.57.2-3 (41d8d77, his fix 1). Crash reproduced on -2 and gone on -3 on the J714s ([upstream tracker](upstream.md)) | see the comment for the closing state |
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
(the hook deletes the file when it uses it).

**Test, 2026-11-15, on ush.** Firmware j714s11 was built from this recipe in `alarm-builder:20261112`
(Arch Linux ARM under qemu-user; package sha256 `035636b0...20c46c`) and installed in a
throwaway container with fake packages: J714s builds with the image's versions, and a local
"edge" repository holding the generic builds with #11's versions (`linux-aurora 7.2.11.aurora16-1`,
`m1n1-aurora 1.6.1.aurora23-2`, `uboot-aurora 2026.07.aurora6-1`,
`omarchy-aurora-firmware 20261014-7`). 18 cases, all as expected:

| Case | Result |
| --- | --- |
| Pin in place, `pacman -Syyuu` | IgnorePkg holds, the guard isn't triggered, an unrelated package upgrades |
| Pin removed as the refresh does it (backup, template copy), then `pacman -Syyuu`; the same with `OMARCHY_UPDATE_PACMAN=1`; `pacman -Suu` | **stopped**, all four packages listed, nothing changed |
| `pacman -U` of the generic kernel (absolute and relative path) or the generic firmware package | **stopped** |
| A newer generic kernel (`7.4.0.aurora18-1`) in the channel, plain `pacman -Syu` | **stopped** |
| `pacman -S edge/uboot-aurora`; `pacman -Rdd uboot-aurora` | **stopped** |
| `pacman -U` J714s v272-11 to v272-12 while the channel offers the generic build; rollback to v272-10 from a relative path; v272-11 from a `file://` URL | goes through |
| Override file, then `pacman -U` of the generic m1n1 | goes through once, file removed; the next generic `-U` is stopped again |
| Back to the J714s m1n1 over the generic one | goes through |
| Pin restored from `/etc/pacman.conf.bak` as the message says, `pacman -Syyuu` | goes through, IgnorePkg holds |

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
