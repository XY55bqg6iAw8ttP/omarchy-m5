# J714s in the official Omarchy Mac installer: plan

Goal: the 14-inch MacBook Pro M5 Pro (J714s, Mac17,9, `j714sap`, T6050) supported by
[omacom/omarchy-mac-installer](https://github.com/omacom/omarchy-mac-installer) through small
pull requests from TripleU613. Surveyed 2026-11-15. Tracker row: [upstream.md](upstream.md).

## 1. What upstream has (head `c07e54c`, 2026-11-06, the same commit our patch sets start from)

Installer:
- No J714s, no T6050, no M5 board at all. `scripts/supported-models.json` refuses `apple,j614s`
  ("M4 and later Macs are not supported") and `apple,j575d` (the engine has no device entry for
  it); the `developer` list is empty. The README says M4 and later stay blocked in public builds.
- AGENTS.md: public builds keep unqualified boards fail-closed; developer builds (sealed developer
  catalog only) "may admit unqualified boards their engine supports".
- The pinned engine (`Engine/patches/0001`, `CHIP_MIN_VER`, device table) has no `0x6050` chip and
  no `j714sap` device, and no 27.2 (26B123) firmware row. Adding one means an engine rename,
  repack and `source-lock.json` re-pin, which maintainers publish.
- No Mach-O Stage 1 path. Raw Stage 1 only, plus board Stage 1/Stage 2 files for the Neo (j700)
  and J613.
- The Recovery "Finish setup" flow exists (native Recovery app); its text is board-independent.
- Image: boot packages from omacom/omarchy-pkgs; `m1n1-aurora` floor `1.6.1.aurora20-3`; package
  name `aura` is in `refused_packages`.

Kernel and loader the upstream image takes:
- omacom/omarchy-pkgs `linux-aurora` 7.2.11.aurora16 pins omacom/linux-aurora `bed544b`. That tree
  has `t8142-j813*` (M5 Air) but **no `t6050` device tree**; neither does omacom/linux-aurora
  `integration/aurora` today.
- Open there: #404 (T6050 base + J714c, edimoldovan; needs the 27.3 beta firmware), #413 (J716s,
  rolotrealanis98), #422 (J714c camera), #439 (G17/M5 GPU). Our J714s board PR #414 was closed by us
  on 2026-11-09 (kept in [`patches/upstream-prs/`](../patches/upstream-prs)).
- omacom/m1n1 `m1n1-aurora` 1.6.1.aurora23 pins `ba130ff`. T6050 work open: #30 (edimoldovan,
  boot from disk on the J714c), #33-#37 (rolotrealanis98). #26 closed.
- Our J714s path uses a different line: aurora-silicon/linux `integration/aurora` + aurora-silicon/aura,
  with Aura's Mach-O Stage 1 on the 27.2 stub. The omacom line (#404, m1n1 #30) needs the 27.3 beta
  firmware (on `mBoot-20457.41.3` the secondary cores don't start there).

**So upstream's current image cannot boot a J714s, and its engine cannot even plan one.**

Open work there that touches the same ground:
- [#157](https://github.com/omacom/omarchy-mac-installer/pull/157) (DjDeveloperr): Mach-O NV2 mode
  in Recovery, for the Neo only (`esp/macho/aura-boot.macho`, `aura-stage2.pkg`, `nv-config`),
  plus multi-install planning. Open, conflicting, last updated 2026-11-01. Same payload name as our
  0002; a J714s Mach-O path should build on it, not beside it.
- [#133](https://github.com/omacom/omarchy-mac-installer/pull/133) (erikwb): J713 in the engine
  behind the developer catalog. Open since 2026-10-25. The precedent for a developer-catalog
  admission; it also renames the engine (so does #157, #45).
- [#208](https://github.com/omacom/omarchy-mac-installer/pull/208) (edimoldovan): IMX958 setfiles
  (J714c camera). Our camera collection needs it.
- [#216](https://github.com/omacom/omarchy-mac-installer/issues/216): request for the J813. No J714s
  issue or PR existed before ours.
- [#219](https://github.com/omacom/omarchy-mac-installer/issues/219) (ours): duplicate boot
  filesystem IDs. No maintainer reply yet.

## 2. Our patch sets against upstream head

Our J714s installer is four stacked sets on `c07e54c`: [`installer/patches/`](../installer/patches)
0001-0019, [`patches-upstream-27.3/`](../installer/patches-upstream-27.3) 0001-0006,
[`patches-j714s/`](../installer/patches-j714s) 0001-0010,
[`patches-j714s-r2/`](../installer/patches-j714s-r2) 0001-0007. The engine's T6050/`j714sap` rows
start in `patches/0002` (as 27.3) and move to 27.2 in `patches-j714s/0001`, so group (b) work has
prerequisites in the base sets.

Classes: **(a)** already upstream, **(b)** J714s support that belongs upstream, **(c)** our
image/release plumbing, **(d)** needs kernel/loader work that isn't upstream yet, **(o)** someone
else's work, theirs to send.

| Patch | What | Class |
| --- | --- | --- |
| patches/0001 | `Integration/M5/J714s-Normal-System/` freeze, manifest, recipes, provenance | c |
| patches/0002 | `j714s-developer` profile, manual ARM CI image workflow; **engine chip `0x6050` and `j714sap` device** | engine rows: b+d; profile/workflow: c |
| patches/0003-0004 | ALARM mirror for the developer image; profile chosen after builder Python | c |
| patches/0005 | native kernel headers build check | c |
| patches/0006 | resolve desktop packages against pinned versions | c (may be generic; not checked against upstream's builder) |
| patches/0007-0014, 0016-0018 | kernel/loader/firmware package bumps for the old developer image | c+d |
| patches/0015 | keep pacman's reason when the precheck fails (FatBoy721) | o |
| patches/0019 | image pin covers our packages | c |
| upstream-27.3/0001, 0004-0006 | aurora-silicon kernel and Aura package pins (27.3) | c+d |
| upstream-27.3/0002-0003 | edimoldovan's #208 and its engine re-pin | o (#208 open) |
| j714s/0001 | engine: 26B123 row, T6050/`j714sap` minimum 27.2, `board-macho-ctxr-v1`, `omarchy_macho.py` (from aurora-installer `AuraStage1.swift`, MIT), Recovery staging in Mach-O mode | b+d; Mach-O staging overlaps #157 |
| j714s/0002 | Recovery app: pad the Mach-O object, `kmutil inspect` check, `bputil -nc`, `kmutil configure-boot --compress` (aurora-installer port) | b+d; overlaps #157 |
| j714s/0003 | Recovery install-data check follows the boot mode | b; overlaps #157 |
| j714s/0004 | image profile `j714s`: `stage1-j714s.{bin,macho}`, `boot-ctxr.bin` + pacman hook, payload name | b+d (needs J714s boot packages in omacom/omarchy-pkgs); payload name: c |
| j714s/0005, 0007 | candidate manifest pins to our built packages, Recovery provenance | c |
| j714s/0006 | `apple,j714s` in the developer list, `--developer-only` sealed catalog, model name | admission + model name: b+d; `--developer-only`: c |
| j714s/0008 | Stage 1 proxy window 15 s; `compress` switch | b with 0002 (window value open, see follow-up 3) |
| j714s/0009 | Finish-setup text names the step and the wrong turn | b, board-independent |
| j714s/0010 | engine: J714s camera setfiles and ALS calibration | b+d; needs #208 |
| j714s-r2/0001-0007 | release 2-6 package sets, Recovery provenance, pins | c |

Nothing is (a): upstream has none of it.

## 3. First pull request: not sent; an issue instead

Decision on 2026-11-15: **no pull request.** Every smallest J714s change fails to stand on its own:
- Admission, even developer-only, needs an engine that supports the board (AGENTS.md); upstream's
  has no T6050 row, and adding it is an engine rename/re-pin that #133, #157 and #45 already contend
  for.
- The 27.2 path needs a Mach-O Stage 1, which is #157's ground.
- The kernel the upstream image pins has no T6050 device tree, so a PR could not claim the
  official image installs a working J714s.
- The model name alone (`MacModelNames.swift`) changes nothing a J714s user sees today: the
  catalog refuses the board before the name matters.

Instead, issue [#221](https://github.com/omacom/omarchy-mac-installer/issues/221) offers the
installer work, states what our install used and what it depends on, and asks the maintainers which
pieces they want and in what order.

Evidence used (one Mac): J714s, macOS 27.3, Omarchy stub on the 27.2 OS firmware
(`UniversalMac_27.2_26B123_Restore.ipsw`, iBoot `mBoot-20457.41.3`). On 2026-11-15, release
`omarchy-j714s-6` installed from scratch: the app shrank macOS, installed, Finish setup in the
stub's Recovery worked, first boot fine, kernel `7.3.0-17.v272-11-ARCH`. Every part of that result
depends on our build: our ad hoc developer app and sealed catalog, our engine repack
`v0.9.2-omarchy.20261113.774d9abc59d3`, our Recovery app (run 43477703681), and our packages
(linux-aurora = aurora-silicon/linux a5ebec5f + 32 patches; m1n1-aurora = Aura 22b71758 + FatBoy721's
DP PHY tunables). The install ran with the 15 s Stage 1 proxy window and `--compress` on (j714s/0008).
The install result comes from the owner's report of 2026-11-15; `docs/fresh-install-j714s.md` does not
record it yet.

## 4. Follow-up pull requests, in order

Send each only when what it needs is there, and as the maintainers answer #221.

1. **Finish-setup text** (j714s/0009, minus the J714s mentions). Board-independent. Needs: a macOS
   run of the Swift tests (`swift test` debug and release, Recovery checks) on upstream head, and a
   look at whether #167's copy cuts changed the same strings.
2. **Engine: T6050 / `j714sap`, 27.2 (26B123) row**, developer catalog only (as #133). Needs: a
   maintainer answer on #221 about the kernel line (omacom #404 on 27.3 vs aurora-silicon on 27.2),
   and #133/#157 settled so the engine rename doesn't collide. Tests: engine overlay tests,
   `scripts/tests`, `./test/all`.
3. **Mach-O Stage 1 for the J714s on top of #157**: extend #157's Neo-only Mach-O mode to a board
   Mach-O kind (fill the raw Stage 1, carry it into the object, pad for the 128 MiB window, `kmutil
   inspect` check, `--compress`), credited to aurora-silicon/aurora-installer. Needs: #157 merged
   (or DjDeveloperr's agreement to stack on it). Open point: the Stage 1 window. Ours is 15000 ms
   (a debug aid that let a stopped boot show on the cable); upstream's board rows use 0 ms (J713)
   or 5000 ms (Neo), so the value to send is the maintainers' call.
4. **Admission**: `apple,j714s` in `developer` in `supported-models.json` + model name. Needs: 2 and 3.
5. **J714s image profile** (stage1-j714s.{bin,macho}, Stage 2, the hook). Needs: J714s-capable
   `linux-aurora` and `m1n1-aurora` in omacom/omarchy-pkgs (omacom/linux-aurora #404/#413 + a J714s
   board tree, omacom/m1n1 T6050 work, or the maintainers choosing the aurora-silicon line).
6. **Camera setfiles and ALS calibration collection** (j714s/0010). Needs: #208 merged, and 2.
7. **#219** (boot filesystem IDs): waiting for the maintainers' choice of fix.

Not to be sent: everything in class (c) and the `--developer-only` catalog switch. The Stage 1
window goes with follow-up 3 at whatever value the maintainers want.
