#Requires AutoHotkey v2.0
#Include lib/DiscordRPC.ahk
#Include lib/DotEnv.ahk

; .env から設定を読み込む
DotEnv.Load()

; GUI の作成
mainGui := Gui("+Resize", "DiscordRPC.ahk - All Features Test Tool")
mainGui.SetFont("s9", "Segoe UI")

; Client ID / Secret 設定エリア
mainGui.Add("GroupBox", "w400 h75", "Initialization")
mainGui.Add("Text", "xp+10 yp+20", "Client ID:")
clientIdEdit := mainGui.Add("Edit", "x+5 w150 vClientId", DotEnv.Get("CLIENT_ID", ""))
mainGui.Add("Text", "x20 y+10", "Client Secret:")
clientSecretEdit := mainGui.Add("Edit", "x+5 w250 vClientSecret", DotEnv.Get("CLIENT_SECRET", ""))
btnConnect := mainGui.Add("Button", "x+10 yp-20 w80", "Connect")
btnConnect.OnEvent("Click", (*) => OnConnect())
btnClose := mainGui.Add("Button", "x+10 yp w80", "Close")
btnClose.OnEvent("Click", (*) => OnClose())

; テスト機能タブ
tab := mainGui.Add("Tab3", "x10 y+20 w400 h300", ["Presence", "Voice", "Information", "Advanced"])

; Presence タブ
tab.UseTab(1)
mainGui.Add("Text", "", "Details:")
editDetails := mainGui.Add("Edit", "w380 vDetails", "DiscordRPC.ahk をテスト中")
mainGui.Add("Text", "", "State:")
editState := mainGui.Add("Edit", "w380 vState", "AutoHotkey v2 で開発中")
btnUpdatePresence := mainGui.Add("Button", "w100", "Update Presence")
btnUpdatePresence.OnEvent("Click", (*) => OnUpdatePresence())
btnClearPresence := mainGui.Add("Button", "x+10 w100", "Clear Presence")
btnClearPresence.OnEvent("Click", (*) => rpc.ClearActivity())

; Voice タブ
tab.UseTab(2)
mainGui.Add("GroupBox", "w380 h80", "Toggle Controls")
btnMute := mainGui.Add("Button", "xp+10 yp+25 w100", "Toggle Mute")
btnMute.OnEvent("Click", (*) => rpc.ToggleMute())
btnDeaf := mainGui.Add("Button", "x+10 w100", "Toggle Deafen")
btnDeaf.OnEvent("Click", (*) => rpc.ToggleDeaf())

mainGui.Add("GroupBox", "x20 y+40 w380 h80", "Query")
btnGetVoice := mainGui.Add("Button", "xp+10 yp+25 w150", "Get Voice Settings")
btnGetVoice.OnEvent("Click", (*) => rpc.GetVoiceSettings())
btnGetSelChannel := mainGui.Add("Button", "x+10 w150", "Get Selected Channel")
btnGetSelChannel.OnEvent("Click", (*) => rpc.GetSelectedVoiceChannel())

; Information タブ
tab.UseTab(3)
btnGetGuilds := mainGui.Add("Button", "w150", "Get Guilds")
btnGetGuilds.OnEvent("Click", (*) => rpc.GetGuilds())
mainGui.Add("Text", "y+10", "Guild ID:")
editGuildId := mainGui.Add("Edit", "w150 vGuildId", "")
btnGetChannels := mainGui.Add("Button", "x+10 w150", "Get Channels")
btnGetChannels.OnEvent("Click", (*) => rpc.GetChannels(mainGui.Submit(false).GuildId))

mainGui.Add("Text", "x20 y+20", "User ID (Blank for Self):")
editUserId := mainGui.Add("Edit", "w200 vUserId", "")
btnGetUser := mainGui.Add("Button", "x+5 w100", "Get User")
btnGetUser.OnEvent("Click", (*) => rpc.GetUser(mainGui.Submit(false).UserId))

; Advanced タブ
tab.UseTab(4)
mainGui.Add("Text", "", "Scopes (space separated):")
editScopes := mainGui.Add("Edit", "w300 vScopes", "rpc rpc.activities.write")
btnAuthorize := mainGui.Add("Button", "w100", "Authorize")
btnAuthorize.OnEvent("Click", (*) => OnAuthorize())

mainGui.Add("Text", "y+10", "Access Token:")
editToken := mainGui.Add("Edit", "w300 vAccessToken", DotEnv.Get("ACCESS_TOKEN", ""))
btnAuthenticate := mainGui.Add("Button", "w100", "Authenticate")
btnAuthenticate.OnEvent("Click", (*) => OnAuthenticate())

mainGui.Add("Text", "y+10", "Invite Dialog Test:")
btnInvite := mainGui.Add("Button", "w150", "Open Invite Dialog")
btnInvite.OnEvent("Click", (*) => rpc.OpenInviteDialog())

tab.UseTab() ; タブ外

; ログエリア
mainGui.Add("Text", "x10 y+10", "Incoming Logs / JSON Response:")
logArea := mainGui.Add("Edit", "x10 y+5 w400 h200 ReadOnly Multi vLogArea")

mainGui.OnEvent("Close", (*) => (rpc.Close(), ExitApp()))
mainGui.Show()

; RPC 初期化（後延し）
global rpc := 0

AppendLog(msg) {
    logArea.Value .= FormatTime(, "HH:mm:ss") . " - " . msg . "`n"
    SendMessage(0x0115, 7, 0, logArea.Hwnd, "User32.dll") ; Scroll to bottom
}

OnConnect() {
    global rpc
    formData := mainGui.Submit(false)
    rpc := DiscordRPC(formData.ClientId)
    
    ; イベントリスナーの登録
    rpc.On("READY", (data) => (
        AppendLog("CONNECTED: " . data.user.username . "#" . data.user.discriminator),
        ToolTip("Discord Connected!"),
        SetTimer(() => ToolTip(), -2000)
    ))
    
    rpc.On("ERROR", (data) => AppendLog("ERROR: " . (data.HasProp("message") ? data.message : JSON.Stringify(data))))
    rpc.On("DISCONNECTED", (msg) => AppendLog("DISCONNECTED: " . msg))
    
    ; 汎用レスポンスリスナー（全コマンドの結果をログに表示）
    for eventName in ["GET_VOICE_SETTINGS", "GET_SELECTED_VOICE_CHANNEL", "GET_GUILDS", "GET_CHANNELS", "GET_USER", "AUTHORIZE", "AUTHENTICATE"] {
        ; 無名関数を使って現在の eventName を束縛する
        ((name) => rpc.On(name, (data) => AppendLog(name . ": " . JSON.Stringify(data))))(eventName)
    }

    if (rpc.Connect()) {
        AppendLog("Connection attempt started...")
        ; トークンがあれば自動認証
        savedToken := DotEnv.Get("ACCESS_TOKEN", "")
        if (savedToken) {
            AppendLog("Auto-authenticating with saved token...")
            SetTimer(() => OnAuthenticate(savedToken), -500)
        }
    } else {
        AppendLog("Failed to open pipe.")
    }
}

OnClose() {
    if (rpc) {
        rpc.Close()
        AppendLog("Connection closed.")
    }
}

OnUpdatePresence() {
    if (!rpc) {
        MsgBox("接続が確立されていない。")
        return
    }
    formData := mainGui.Submit(false)
    activity := {
        details: formData.Details,
        state: formData.State,
        assets: {
            large_image: "ahk_logo",
            large_text: "AutoHotkey v2"
        },
        timestamps: {
            start: DiscordRPC.GetUnixTime()
        }
    }
    rpc.SetActivity(activity)
    AppendLog("Presence updated.")
}

OnAuthorize() {
    formData := mainGui.Submit(false)
    scopes := StrSplit(formData.Scopes, " ")
    
    ; AUTHORIZE レスポンスハンドラを一回限りで登録
    rpc.On("AUTHORIZE", (data) => (
        AppendLog("Authorize Success: " . JSON.Stringify(data)),
        (data.HasProp("code") && formData.ClientSecret) ? OnExchangeCode(data.code) : ""
    ))
    
    rpc.Authorize(scopes)
    AppendLog("Authorize request sent.")
}

OnExchangeCode(code) {
    formData := mainGui.Submit(false)
    AppendLog("Exchanging code for token...")
    res := rpc.ExchangeCodeForToken(code, formData.ClientSecret)
    if (res.HasProp("access_token")) {
        AppendLog("Token obtained successfully.")
        editToken.Value := res.access_token
        OnAuthenticate(res.access_token)
    } else {
        AppendLog("Token exchange failed: " . JSON.Stringify(res))
    }
}

OnAuthenticate(token := "") {
    if (!token) {
        formData := mainGui.Submit(false)
        token := formData.AccessToken
    }
    
    if (!token) {
        AppendLog("No access token provided.")
        return
    }

    ; AUTHENTICATE 成功時にトークンを保存
    rpc.On("AUTHENTICATE", (data) => (
        AppendLog("Authenticated as: " . data.user.username),
        DotEnv.Write("ACCESS_TOKEN", token),
        AppendLog("Access token saved to .env")
    ))

    rpc.Authenticate(token)
    AppendLog("Authenticate request sent.")
}

