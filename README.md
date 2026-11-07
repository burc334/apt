# burc334 APT repository

Sileo source URL:

`https://burc334.github.io/apt/`

This repository indexes the released `com.burc334.*` packages from the individual tweak repositories.

## Update

Sync the latest releases and rebuild the indexes:

```sh
./scripts/sync-releases.sh
```

Or rebuild the indexes from the debs already in `docs/pool/`:

```sh
./scripts/update-repo.sh
```

The repository is signed with the key in `docs/repo-public.key`.
