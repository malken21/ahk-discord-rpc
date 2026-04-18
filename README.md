# Discord RPC for AutoHotkey v2

AutoHotkey (v2.0+) を使用して、外部 DLL に依存せずに Discord Rich Presence を実現する軽量ライブラリ。

## 特徴
- **外部 DLL 不要**: Windows 標準の Named Pipe を使用して Discord と直接通信。
- **AutoHotkey v2 専用**: 最新の AHK v2 構文向けに最適化。
- **純粋 AHK 実装**: `htmlfile` (Internet Explorer) に依存しない、最新の 高精度 JSON 解析エンジン (`JSON.ahk`) を搭載。

## 使用方法

1. [Discord Developer Portal](https://discord.com/developers/applications) で Application ID を取得する。
2. `lib` フォルダ内の `DiscordRPC.ahk` および `JSON.ahk` をプロジェクトの `lib` フォルダ（またはライブラリフォルダ）に配置する。
3. 以下のコードで Rich Presence を更新する。

```autohotkey
#Include lib/DiscordRPC.ahk

rpc := DiscordRPC("YOUR_CLIENT_ID")
if (rpc.Connect()) {
    rpc.SetActivity({
        state: "ステータス文字",
        details: "詳細情報",
        assets: {
            large_image: "image_key"
        }
    })
}
```

## API リファレンス

### 接続・基本操作
- `Connect()`: Discord デスクトップクライアントへの接続を開始。
- `Close()`: 接続を終了。
- `On(event, callback)`: イベントリスナーを登録 (`READY`, `DISCONNECTED`, `ERROR` 等)。

### リッチプレゼンス
- `SetActivity(details)`: Rich Presence を更新。オブジェクト形式でパラメータを渡します。
- `ClearActivity()`: Rich Presence を消去。

### ボイス制御 (要認証/スコープ設定)
- `SetMute(bool)`: マイクのミュート状態を設定。
- `SetDeaf(bool)`: スピーカーのミュート状態を設定。
- `ToggleMute()`: マイクのミュート状態を反転。
- `ToggleDeaf()`: スピーカーのミュート状態を反転。

## 高度なサンプル
ボイスチャットの制御やボタン付きプレゼンスの詳細は [AdvancedExample.ahk](AdvancedExample.ahk) を参照してください。

## 注意事項
- Discord デスクトップクライアントが起動している必要がある。
- `lib/JSON.ahk` が `DiscordRPC.ahk` と同一ディレクトリに必要です。
- ボイス制御などの一部の機能は、Discord 側での承認（RPC 連携）が必要な場合があります。
