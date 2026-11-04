# Pi の Web 検索ルーティング（K-373）

Pi の Web 検索は、ローカルの RustXNG を第一候補にし、使えないときだけ OpenAI（ChatGPT サブスク認証）へ落とす構成にしている。検証結果は `~/src/261104_pi-web-search` に置いた（8 クエリで hit@5 16/16、中央値 3.8–4.7 秒。OpenAI 単独は 10/16、11–13 秒）。

## 構成要素

| 要素 | 管理場所 | 内容 |
|---|---|---|
| `rustxng` バイナリ | `nix/pkgs/rustxng.nix` | v0.27.1 のリリース成果物を checksum 付きで固定。ソースビルドはしない |
| 常駐 | `nix/launchd.nix` | `com.adachi.rustxng` がログイン時に `127.0.0.1:29483` で起動。異常終了時のみ再起動 |
| 検索ルーティング | `nix/agents/pi.nix` → `~/.pi/agent/web-search.json` | SearXNG 互換 API を先に、失敗種別に応じて OpenAI へ |
| Pi 拡張 | ローカル（`pi install`） | `npm:pi-web-access@0.46.0` を `~/.pi/agent/npm` に導入 |

`web-search.json` はクラス A（merge）で宣言する。認証情報は含まないためリポジトリに置ける。Pi 拡張の導入はマシンごとの操作で、`settings.json` の `packages` 配列に残る（宣言していないので switch では消えない）。

## 初回セットアップ（マシンごと）

```bash
pi install npm:pi-web-access@0.46.0   # 拡張の導入（1 回だけ）
sudo darwin-rebuild switch --flake ~/.config/nix-darwin#macbook
curl -s http://127.0.0.1:29483/healthz   # OK が返れば RustXNG は起動済み
```

## 動作確認

```bash
pi -p --tools web_search "RustXNG の SearXNG 互換 API を調べて"
```

検索結果の `Provider:` が `searxng` なら第一候補が使われている。RustXNG を止めた状態でも同じコマンドが通り、`Provider:` が `openai` になる（フォールバック）。

`web-search.json` を一時的に上書きしたいときは環境変数が使える。

```bash
SEARXNG_BASE_URL=http://127.0.0.1:29483 pi   # 別ポートの RustXNG を使う
```

## フォールバック条件

`searchRouting.fallbackOn` に列挙した失敗種別だけ OpenAI へ進む。空結果・上流全滅・レート制限・接続不可はここに含めた。`provider: "openai"` を明示すると OpenAI 固定になる。

```json
{
  "searxngBaseUrl": "http://127.0.0.1:29483",
  "searchRouting": {
    "providers": ["searxng", "openai"],
    "fallbackOn": ["transient", "quota", "network", "invalid-response", "empty"]
  }
}
```

## 更新

RustXNG を上げるときは `nix/pkgs/rustxng.nix` の `version` と 5 つのハッシュ（4 プラットフォーム + LICENSE/NOTICE）をリリースの `.sha256` に合わせて差し替える。ハッシュを 1 つでも取り違えると `nix build` がフェッチ段階で落ちる。

## 注意

- RustXNG は上流の検索エンジンを叩く。上流が CAPTCHA や 429 を返すと品質が落ちる（検証時は 23 エンジンが unresponsive でも 1 位を維持した）。落ちたときは OpenAI フォールバックが働く。
- ループバック限定で動かす。`--bind` は変えない。
- agent-browser は検索には使わない。JS レンダリングやログインが必要なページ閲覧にだけ使う。
