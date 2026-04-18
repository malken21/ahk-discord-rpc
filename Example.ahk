#Requires AutoHotkey v2.0
#Include lib/DiscordRPC.ahk
#Include lib/DotEnv.ahk

; .env から設定を読み込む
DotEnv.Load()

; GUI の作成
mainGui := Gui("+Resize", "DiscordRPC.ahk - All Features Test Tool")
mainGui.SetFont("s9", "Segoe UI")

; Client ID / Secret 設定エリア
mainGui.Add("GroupBox", "Section x10 y10 w400 h90", "Initialization")
mainGui.Add("Text", "xs+10 ys+25 w80", "Client ID:")
clientIdEdit := mainGui.Add("Edit", "x+5 w200 vClientId", DotEnv.Get("CLIENT_ID", ""))
btnConnect := mainGui.Add("Button", "x+10 yp-2 w80", "Connect")
btnConnect.OnEvent("Click", (*) => OnConnect())

mainGui.Add("Text", "xs+10 y+12 w80", "Client Secret:")
clientSecretEdit := mainGui.Add("Edit", "x+5 w200 vClientSecret", DotEnv.Get("CLIENT_SECRET", ""))
btnClose := mainGui.Add("Button", "x+10 yp-2 w80", "Disconnect")
btnClose.OnEvent("Click", (*) => OnDisconnect())

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
btnClearPresence.OnEvent("Click", (*) => EnsureRPC() && rpc.ClearActivity())

; Voice タブ
tab.UseTab(2)
mainGui.Add("GroupBox", "Section w380 h80", "Toggle Controls")
btnMute := mainGui.Add("Button", "xs+10 ys+25 w100", "Toggle Mute")
btnMute.OnEvent("Click", (*) => EnsureRPC() && rpc.ToggleMute())
btnDeaf := mainGui.Add("Button", "x+10 w100", "Toggle Deafen")
btnDeaf.OnEvent("Click", (*) => EnsureRPC() && rpc.ToggleDeaf())

mainGui.Add("GroupBox", "xs y+20 w380 h80", "Query")
btnGetVoice := mainGui.Add("Button", "xp+10 yp+25 w150", "Get Voice Settings")
btnGetVoice.OnEvent("Click", (*) => EnsureRPC() && rpc.GetVoiceSettings())
btnGetSelChannel := mainGui.Add("Button", "x+10 w150", "Get Selected Channel")
btnGetSelChannel.OnEvent("Click", (*) => EnsureRPC() && rpc.GetSelectedVoiceChannel())

; Information タブ
tab.UseTab(3)
btnGetGuilds := mainGui.Add("Button", "w150 Section", "Get Guilds")
btnGetGuilds.OnEvent("Click", (*) => EnsureRPC() && rpc.GetGuilds())
mainGui.Add("Text", "xs y+15", "Guild ID:")
editGuildId := mainGui.Add("Edit", "xs y+5 w150 vGuildId", "")
btnGetChannels := mainGui.Add("Button", "x+10 yp-2 w120", "Get Channels")
btnGetChannels.OnEvent("Click", (*) => EnsureRPC() && rpc.GetChannels(mainGui.Submit(false).GuildId))

mainGui.Add("Text", "xs y+15", "User ID (Blank for Self):")
editUserId := mainGui.Add("Edit", "xs y+5 w150 vUserId", "")
btnGetUser := mainGui.Add("Button", "x+10 yp-2 w100", "Get User")
btnGetUser.OnEvent("Click", (*) => (
    targetId := mainGui.Submit(false).UserId,
    (!targetId && rpc is DiscordRPC && rpc.HasProp("user")) ? targetId := rpc.user.id : "",
    EnsureRPC() && rpc.GetUser(targetId)
))

; Advanced タブ
tab.UseTab(4)
mainGui.Add("Text", "Section", "Scopes (space separated):")
editScopes := mainGui.Add("Edit", "w250 vScopes", DotEnv.Get("SCOPES", "rpc rpc.activities.write"))
btnAuthorize := mainGui.Add("Button", "x+10 yp-2 w100", "Authorize")
btnAuthorize.OnEvent("Click", (*) => OnAuthorize())

mainGui.Add("Text", "xs y+10", "Access Token:")
editToken := mainGui.Add("Edit", "w250 vAccessToken", DotEnv.Get("ACCESS_TOKEN", ""))
btnAuthenticate := mainGui.Add("Button", "x+10 yp-2 w100", "Authenticate")
btnAuthenticate.OnEvent("Click", (*) => OnAuthenticate())

mainGui.Add("Text", "xs y+10", "Invite & Utility Test:")
mainGui.Add("Text", "xs y+5", "Channel ID (Optional for Dialog):")
editTestChannelId := mainGui.Add("Edit", "w250 vTestChannelId", "")
mainGui.Add("Text", "xs y+5 cGray", "※OpenInviteDialog は Activity 以外では動作しない場合があります。")

btnInvite := mainGui.Add("Button", "w150", "Open Invite Dialog")
btnInvite.OnEvent("Click", (*) => (
    targetId := mainGui.Submit(false).TestChannelId,
    EnsureRPC() && rpc.OpenInviteDialog(targetId)
))

btnCreateInvite := mainGui.Add("Button", "x+10 w150", "Create Invite Code")
btnCreateInvite.OnEvent("Click", (*) => (
    targetId := mainGui.Submit(false).TestChannelId,
    !targetId ? MsgBox("Channel ID を入力してください。", "Error", 16) :
    EnsureRPC() && rpc.CreateChannelInvite(targetId, , , , , (data) => (
        data.HasProp("code") ? (
            inviteUrl := "https://discord.gg/" . data.code,
            A_Clipboard := inviteUrl,
            MsgBox("招待コードが作成されました: " . data.code . "`nURL をクリップボードにコピーしました:`n" . inviteUrl, "Success", 64)
        ) : MsgBox("招待の作成に失敗しました。ログを確認してください。", "Error", 16)
    ))
))

tab.UseTab() ; タブ外

; ログエリア
mainGui.Add("Text", "x10 y+10", "Incoming Logs / JSON Response:")
logArea := mainGui.Add("Edit", "x10 y+5 w400 h200 ReadOnly Multi vLogArea")

mainGui.OnEvent("Close", (*) => ((rpc is DiscordRPC) && rpc.Close(), ExitApp()))
mainGui.Show()

    AppendLog("Initialization complete.")

; RPC 初期化（後延し）
global rpc := 0
global currentVoiceChannelId := ""

EnsureRPC() {
    global rpc
    if (rpc is DiscordRPC)
        return true
    MsgBox("Discord に接続されていません。Initialization セクションの Connect ボタンを押してください。", "Error", 16)
    return false
}

AppendLog(msg) {
    logArea.Value .= FormatTime(, "HH:mm:ss") . " - " . msg . "`n"
    SendMessage(0x0115, 7, 0, logArea.Hwnd, "User32.dll") ; Scroll to bottom
}

OnConnect() {
    global rpc
    formData := mainGui.Submit(false)
    
    ; 設定を保存
    DotEnv.Write("CLIENT_ID", formData.ClientId)
    DotEnv.Write("CLIENT_SECRET", formData.ClientSecret)
    
    rpc := DiscordRPC(formData.ClientId)
    
    ; イベントリスナーの登録
    rpc.On("READY", (data) => (
        rpc.user := data.user,
        AppendLog("CONNECTED: " . data.user.username . "#" . data.user.discriminator),
        ToolTip("Discord Connected!"),
        SetTimer(() => ToolTip(), -2000)
    ))
    
    rpc.On("ERROR", (data) => AppendLog("ERROR: " . (data.HasProp("message") ? data.message : JSON.Stringify(data))))
    rpc.On("DISCONNECTED", (msg) => AppendLog("DISCONNECTED: " . msg))
    
    ; 汎用レスポンスリスナー（全コマンドの結果をログに表示）
    OnGetResponse(name, data) {
        global currentVoiceChannelId
        if (name = "GET_SELECTED_VOICE_CHANNEL")
            currentVoiceChannelId := data.HasProp("id") ? data.id : ""
        AppendLog(name . ": " . JSON.Stringify(data))
    }

    for eventName in ["GET_VOICE_SETTINGS", "GET_SELECTED_VOICE_CHANNEL", "GET_GUILDS", "GET_CHANNELS", "GET_USER", "AUTHORIZE", "AUTHENTICATE", "OPEN_INVITE_DIALOG", "CREATE_CHANNEL_INVITE"] {
        rpc.On(eventName, OnGetResponse.Bind(eventName))
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

OnDisconnect() {
    if (rpc is DiscordRPC) {
        rpc.Close()
        AppendLog("Connection closed.")
    }
}

OnUpdatePresence() {
    if (!EnsureRPC()) {
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
    if (!EnsureRPC()) {
        return
    }
    formData := mainGui.Submit(false)
    
    ; Scopes を保存
    DotEnv.Write("SCOPES", formData.Scopes)
    
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
    if (!EnsureRPC()) {
        return
    }
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
        rpc.user := data.user,
        AppendLog("Authenticated as: " . data.user.username),
        DotEnv.Write("ACCESS_TOKEN", token),
        AppendLog("Access token saved to .env")
    ))

    rpc.Authenticate(token)
    AppendLog("Authenticate request sent.")
}

