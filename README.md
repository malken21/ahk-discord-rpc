# Discord RPC for AutoHotkey v2

AutoHotkey (v2.0+) を使用して、外部 DLL に依存せずに Discord Rich Presence を実現する軽量ライブラリ。

## 特徴
- **外部依存なし**: Windows 標準の Named Pipe を使用して Discord と直接通信。
- **AutoHotkey v2 専用**: 最新の AHK v2 構文向けに最適化。
- **軽量**: 簡易 JSON エンコーダと UUID 生成機能を内蔵。

## 使用方法

1. [Discord Developer Portal](https://discord.com/developers/applications) で Application ID を取得する。
2. `DiscordRPC.ahk` をプロジェクトに含める。
3. 以下のコードで Rich Presence を更新する。

```autohotkey
#Include DiscordRPC.ahk

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

## 注意事項
- Discord デスクトップクライアントが起動している必要がある。
- `timestamps` や `party` などの詳細なパラメータも、オブジェクト形式で渡すことが可能。
