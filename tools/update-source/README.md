# The [omarchy-m5] package repository

A signed pacman repository on the release [`repo-aarch64`](https://github.com/betizzel/omarchy-m5/releases/tag/repo-aarch64).
It serves our tested builds of the four J714s boot packages: `linux-aurora`, `omarchy-aurora-firmware`,
`m1n1-aurora` and `hyprland-m5`. With it on, `omarchy update` brings new J714s builds like any other
package, with no manual `pacman -U`.

## Turn it on (once, on the Mac)

```
curl -fsSLO https://raw.githubusercontent.com/betizzel/omarchy-m5/main/tools/update-source/enable
bash enable
omarchy update
```

`enable --disable` turns it off and pins the four packages again.

What `enable` does, and why it's safe:

- It downloads the repository key and refuses it unless the fingerprint is
  `E86FAF980FDC450871B7EA99FCA533429F69AE22`. Then it adds the key to pacman's keyring and signs it locally.
- It writes `/etc/pacman.d/omarchy-m5.conf` (`SigLevel = Required`) and includes it **above `[omarchy]`**.
  pacman takes a package from the first repository that has it, so omacom's builds of the four packages
  can't replace ours. That's why the four leave `IgnorePkg`; every other pin stays.
- It installs itself as an Omarchy `pre-refresh-pacman` hook. `omarchy refresh pacman` rewrites
  `/etc/pacman.conf`, and the hook puts the repository line and the pins back.

Tested on our J714s (2026-11-24):
- `pacman -Sp` takes all four packages from `[omarchy-m5]`. omacom's are `linux-aurora 7.3.0.aurora1-1` and
  `m1n1-aurora 1.6.1.aurora23-4`.
- `pacman -Syu --print` leaves the four alone.
- A reinstall from the repository shows "Validated By: Signature".
- After `pacman.conf` was wiped of the repository line and every pin, the hook restored it byte for byte
  (blank lines aside).

## Publishing a package (maintainers)

The repository key's private half is on the build host (`ush:~/m5/private/repo-signing`), with a backup in
the Actions secret `REPO_SIGNING_KEY`. Never copy it anywhere else.

1. Put the tested `.pkg.tar.zst` in `ush:~/m5/repo-aarch64/`. Remove the version it replaces; the
   repository keeps one version of each package.
2. Sign the packages and rebuild the database there, in `archlinux:base-devel` with the key mounted at
   `/g` ([`sign-repo.sh`](sign-repo.sh)).
3. Upload the changed packages, their `.sig` files, and `omarchy-m5.{db,files}{,.sig}` (the real
   files, not repo-add's symlinks) to the `repo-aarch64` release with `--clobber`. Delete the replaced
   package's assets.

Only publish a package that has booted on a J714s and passed this repo's update-check.
