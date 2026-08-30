# macOS: 再起動後に Nix store が読めないとき

macOS では `/nix` は通常のディレクトリではなく **APFS ボリューム**（名前: `Nix Store`）である。再起動後にこのボリュームが `/nix` に乗らないと、`/nix/store` 配下の CLI がすべて「コマンドが見つからない」になる。中身が消えたわけではない。

このホストは Determinate Nix が daemon と `/etc/nix/nix.conf` を所有し、nix-darwin は `nix.enable = false` でそれに干渉しない（`nix/darwin.nix`）。

## 今すぐ直す

Cursor / Terminal.app から、**Nix に依存しない**次のコマンドを使う。`~/.zshrc` は store への symlink なので壊れていることがある。`/bin/bash` で直接実行する。

```bash
/bin/bash ~/.config/nix-darwin/home/bin/nix-store-repair.sh
```

リポジトリがまだ古い場合:

```bash
/usr/bin/curl -fsSL https://raw.githubusercontent.com/k-adachi-01/dotfiles/main/home/bin/nix-store-repair.sh | sudo /bin/bash
```

診断だけ:

```bash
/bin/bash ~/.config/nix-darwin/home/bin/nix-store-repair.sh --status
```

成功したら新しい login shell を開く:

```bash
exec "$SHELL" -l
```

`nix --version` と `ls /nix/store | head` が通れば復旧。

**やってはいけないこと**

- `diskutil apfs deleteVolume "Nix Store"`（store 本体を消す）
- まず Nix を再インストールする（インストーラは修復ツールではない）

## 再起動後も直らないとき（BTM）

`launchctl bootstrap` は **今のブートだけ** 効く。macOS 14.6.1 以降、署名のない LaunchDaemon は Background Task Management (BTM) にブロックされ、再起動するとまた `/nix` が空になる。

1. システム設定 → 一般 → ログイン項目と拡張機能 → **バックグラウンドで許可**
2. `sh` / `Nix` / `Determinate`（「未確認のデベロッパからの項目」と出ることが多い）を **オン**
3. 見た目オンでも BTM が `disallowed` のときは、オフ→オンで書き直す

確認:

```bash
sudo sfltool dumpbtm | grep -B2 -A10 -iE 'nixos|determinate|darwin-store|nix-daemon'
```

`Disposition` に `disallowed` が残っていると、次の再起動で再発する。

## スクリプトが直さないもの

| 症状 | 対処 |
|---|---|
| `/nix` 自体が無い | `/etc/synthetic.conf` に `nix` の行を足して再起動 |
| `fstab` の UUID がボリュームと不一致 | `diskutil info "Nix Store"` の Volume UUID を `sudo vifs` で `/etc/fstab` に合わせる |
| ボリュームが `/Volumes/Nix Store` に乗っている | スクリプトが unmount して `/nix` に付け直す |

## なぜ `.zprofile` を store の外に置くか

home-manager の `.text` は Nix store への symlink になる。`/nix` が未マウントだと login shell が `.zprofile` を読めず、Homebrew の PATH も消える。`home/zprofile` を `mkOutOfStoreSymlink` で `~/.zprofile` に張ると、repo（データボリューム）だけあれば login shell が動き、未マウント時に修復コマンドを案内できる。`~/bin/nix-store-repair` も同様。

`programs.zsh.enable` は別キー `home.file."./.zprofile"` にも session vars 用ファイルを書く。`.zprofile` と `./.zprofile` は assertion 上は別物なので、両方有効だと files builder が `Error installing file './.zprofile' outside $HOME` で落ちる。Darwin では生成側を `enable = false` にし、session vars は `home/zprofile` から profile パス経由で読む。
