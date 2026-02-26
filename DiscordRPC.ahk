/**
 * DiscordRPC.ahk
 * Discord Rich Presence Library for AutoHotkey v2
 */
class DiscordRPC {
    static PIPE_NAME := "\\.\pipe\discord-ipc-0"
    static OP_HANDSHAKE := 0
    static OP_FRAME := 1
    static OP_CLOSE := 2

    hPipe := 0
    clientId := ""
    callbacks := Map()
    buffer := Buffer(0)

    __New(clientId) {
        this.clientId := clientId
    }

    /**
     * Discord に接続してハンドシェイクを実行
     * @returns {Boolean} 接続成功なら true
     */
    Connect() {
        if (this.hPipe)
            this.Close()

        loop 10 {
            pipeName := "\\.\pipe\discord-ipc-" . (A_Index - 1)
            this.hPipe := DllCall("CreateFile", "Str", pipeName, "UInt", 0xC0000000, "UInt", 0, "Ptr", 0, "UInt", 3, "UInt", 0, "Ptr", 0, "Ptr")
            if (this.hPipe != -1)
                break
            this.hPipe := 0
        }

        if (!this.hPipe)
            return false

        ; Handshake (v1)
        payload := '{"v":1,"client_id":"' . this.clientId . '"}'
        if (!this._Send(DiscordRPC.OP_HANDSHAKE, payload)) {
            this.Close()
            return false
        }

        ; 読み取りタイマーの開始
        SetTimer(() => this._OnTick(), 50)
        return true
    }

    /**
     * イベントリスナーの登録
     * @param {String} event イベント名 (READY, ERROR, etc.)
     * @param {Function} callback コールバック関数
     */
    On(event, callback) {
        this.callbacks[Upper(event)] := callback
    }

    /**
     * 汎用的なリクエスト送信メソッド
     * @param {String} cmd コマンド
     * @param {Object} args 引数
     * @param {String} evt イベント名（SUBSCRIBE/UNSUBSCRIBE用）
     */
    Request(cmd, args := {}, evt := "") {
        data := {
            cmd: cmd,
            nonce: this._CreateGuid()
        }
        if (args)
            data.args := args
        if (evt)
            data.evt := evt
        return this._Send(DiscordRPC.OP_FRAME, this._ToJson(data))
    }

    ; --- Authentication & Authorization ---

    Authorize(scopes, client_id := "") => this.Request("AUTHORIZE", {scopes: scopes, client_id: client_id || this.clientId})
    Authenticate(access_token) => this.Request("AUTHENTICATE", {access_token: access_token})

    ; --- Rich Presence & Activities ---

    SetActivity(details) => this.Request("SET_ACTIVITY", {pid: DllCall("GetCurrentProcessId"), activity: details})
    ClearActivity() => this.Request("SET_ACTIVITY", {pid: DllCall("GetCurrentProcessId"), activity: Map()})
    SendActivityJoinInvite(userId) => this.Request("SEND_ACTIVITY_JOIN_INVITE", {user_id: userId})
    CloseActivityRequest(userId) => this.Request("CLOSE_ACTIVITY_REQUEST", {user_id: userId})
    AcceptActivityInvite(userId, type, sessionId, channelId := "") => this.Request("ACCEPT_ACTIVITY_INVITE", {user_id: userId, type: type, session_id: sessionId, channel_id: channelId})
    ActivityInviteUser(userId, type, content := "") => this.Request("ACTIVITY_INVITE_USER", {user_id: userId, type: type, content: content})

    ; --- Voice Control ---

    SetVoiceSettings(settings) => this.Request("SET_VOICE_SETTINGS", settings)
    SetUserVoiceSettings(userId, settings) => (settings.user_id := userId, this.Request("SET_USER_VOICE_SETTINGS", settings))
    SelectVoiceChannel(channelId, force := false) => this.Request("SELECT_VOICE_CHANNEL", {channel_id: channelId, force: force})
    GetVoiceSettings() => this.Request("GET_VOICE_SETTINGS")
    GetSelectedVoiceChannel() => this.Request("GET_SELECTED_VOICE_CHANNEL")

    ; --- Voice Control Helpers ---

    SetMute(mute := true) => this.SetVoiceSettings({mute: mute})
    SetDeaf(deaf := true) => this.SetVoiceSettings({deaf: deaf})
    ToggleMute() => (this.On("GET_VOICE_SETTINGS", (data) => this.SetMute(!data.mute)), this.GetVoiceSettings())
    ToggleDeaf() => (this.On("GET_VOICE_SETTINGS", (data) => this.SetDeaf(!data.deaf)), this.GetVoiceSettings())

    ; --- Guild & Channel Information ---

    GetGuild(guildId, timeout := 0) => this.Request("GET_GUILD", {guild_id: guildId, timeout: timeout})
    GetGuilds() => this.Request("GET_GUILDS")
    GetChannel(channelId) => this.Request("GET_CHANNEL", {channel_id: channelId})
    GetChannels(guildId) => this.Request("GET_CHANNELS", {guild_id: guildId})
    SelectTextChannel(channelId, timeout := 0) => this.Request("SELECT_TEXT_CHANNEL", {channel_id: channelId, timeout: timeout})
    CreateChannelInvite(channelId, max_age := 86400, max_uses := 0, temporary := false, unique := false) => this.Request("CREATE_CHANNEL_INVITE", {channel_id: channelId, max_age: max_age, max_uses: max_uses, temporary: temporary, unique: unique})

    ; --- User & Relationships ---

    GetUser(userId) => this.Request("GET_USER", {user_id: userId})
    GetRelationships() => this.Request("GET_RELATIONSHIPS")

    ; --- Hardware & Client Control ---

    SetCertifiedDevices(devices) => this.Request("SET_CERTIFIED_DEVICES", {devices: devices})
    CaptureShortcut(action) => this.Request("CAPTURE_SHORTCUT", {action: action})
    OverlaySetLocked(locked) => this.Request("OVERLAY_SET_LOCKED", {locked: locked})
    OpenInviteDialog() => this.Request("OPEN_INVITE_DIALOG")
    DeepLink(params) => this.Request("DEEP_LINK", params)
    BrowserHandoff() => this.Request("BROWSER_HANDOFF")
    GiftCodeBrowser(code) => this.Request("GIFT_CODE_BROWSER", {code: code})

    ; --- Store & Entitlements ---

    GetApplicationTicket() => this.Request("GET_APPLICATION_TICKET")
    GetEntitlements() => this.Request("GET_ENTITLEMENTS")
    GetEntitlementTicket() => this.Request("GET_ENTITLEMENT_TICKET")
    GetSkus() => this.Request("GET_SKUS")

    ; --- Networking ---

    GetNetworkingConfig() => this.Request("GET_NETWORKING_CONFIG")

    ; --- Event Subscription ---

    Subscribe(events) {
        if !(events is Array)
            events := [events]
        for event in events {
            this.Request("SUBSCRIBE", {}, Upper(event))
        }
    }

    Unsubscribe(events) {
        if !(events is Array)
            events := [events]
        for event in events {
            this.Request("UNSUBSCRIBE", {}, Upper(event))
        }
    }

    /**
     * 接続を終了
     */
    Close() {
        if (this.hPipe) {
            SetTimer(() => this._OnTick(), 0)
            DllCall("CloseHandle", "Ptr", this.hPipe)
            this.hPipe := 0
        }
    }

    _OnTick() {
        if (!this.hPipe)
            return

        ; 利用可能なデータ量を確認
        if (!DllCall("PeekNamedPipe", "Ptr", this.hPipe, "Ptr", 0, "UInt", 0, "Ptr", 0, "UInt*", &avail := 0, "Ptr", 0)) {
            if (this.callbacks.Has("DISCONNECTED"))
                this.callbacks["DISCONNECTED"]("Lost connection to Discord")
            this.Close()
            return
        }

        if (avail > 0) {
            buf := Buffer(avail)
            if (DllCall("ReadFile", "Ptr", this.hPipe, "Ptr", buf, "UInt", avail, "UInt*", &read := 0, "Ptr", 0)) {
                this._HandleData(buf)
            }
        }
    }

    _HandleData(buf) {
        ; 既存のバッファと結合
        oldSize := this.buffer.Size
        newBuf := Buffer(oldSize + buf.Size)
        if (oldSize > 0)
            DllCall("RtlMoveMemory", "Ptr", newBuf, "Ptr", this.buffer, "UInt", oldSize)
        DllCall("RtlMoveMemory", "Ptr", newBuf.Ptr + oldSize, "Ptr", buf, "UInt", buf.Size)
        this.buffer := newBuf

        while (this.buffer.Size >= 8) {
            op := NumGet(this.buffer, 0, "UInt")
            len := NumGet(this.buffer, 4, "UInt")

            if (this.buffer.Size < 8 + len)
                break

            payload := StrGet(this.buffer.Ptr + 8, len, "UTF-8")
            
            ; 次のデータのためにバッファを切り詰める
            remSize := this.buffer.Size - (8 + len)
            remBuf := Buffer(remSize)
            if (remSize > 0)
                DllCall("RtlMoveMemory", "Ptr", remBuf, "Ptr", this.buffer.Ptr + 8 + len, "UInt", remSize)
            this.buffer := remBuf

            this._Dispatch(op, payload)
        }
    }

    _Dispatch(op, payload) {
        try {
            data := this._FromJson(payload)
            if (op = DiscordRPC.OP_FRAME) {
                if (data.HasProp("evt") && data.evt) {
                    evt := Upper(data.evt)
                    if (this.callbacks.Has(evt)) {
                        this.callbacks[evt](data.data)
                    }
                }
            }
        } catch as e {
            ; JSON パース失敗等は無視するか、内部エラーイベントを投げる
        }
    }

    _Send(op, payload) {
        if (!this.hPipe)
            return false

        payloadBuf := Buffer(StrPut(payload, "UTF-8") - 1)
        StrPut(payload, payloadBuf, "UTF-8")
        
        header := Buffer(8)
        NumPut("UInt", op, header, 0)
        NumPut("UInt", payloadBuf.Size, header, 4)

        if (!DllCall("WriteFile", "Ptr", this.hPipe, "Ptr", header, "UInt", 8, "Ptr", 0, "Ptr", 0))
            return false
        
        if (!DllCall("WriteFile", "Ptr", this.hPipe, "Ptr", payloadBuf, "UInt", payloadBuf.Size, "Ptr", 0, "Ptr", 0))
            return false
        
        return true
    }

    _CreateGuid() {
        VarSetStrCapacity(&guid, 38)
        DllCall("rpcrt4\UuidCreate", "Ptr", p := Buffer(16))
        DllCall("rpcrt4\UuidToString", "Ptr", p, "Ptr*", &ptr := 0)
        s := StrGet(ptr)
        DllCall("rpcrt4\RpcStringFree", "Ptr*", &ptr)
        return s
    }

    /**
     * JSON エンコーダー（Map/Object/Array 対応）
     */
    _ToJson(obj) {
        if IsObject(obj) {
            if (obj is Array) {
                res := "["
                for i, v in obj {
                    res .= (i = 1 ? "" : ",") . this._ToJson(v)
                }
                return res . "]"
            }
            res := "{"
            first := true
            if (obj is Map) {
                for k, v in obj {
                    res .= (first ? "" : ",") . '"' . k . '":' . this._ToJson(v)
                    first := false
                }
            } else {
                for k, v in obj.OwnProps() {
                    res .= (first ? "" : ",") . '"' . k . '":' . this._ToJson(v)
                    first := false
                }
            }
            return res . "{" == res ? "{}" : res . "}"
        } else if IsNumber(obj) {
            return obj
        } else if (obj == "null") {
            return "null"
        } else {
            return '"' . StrReplace(StrReplace(StrReplace(obj, "\", "\\"), '"', '\"'), "`n", "\n") . '"'
        }
    }

    /**
     * 簡易 JSON デコーダー
     */
    _FromJson(json) {
        ; AHK v2 には標準の JSON デコーダーがないため、簡易的な実装を行うか、
        ; 他のスクリプトから引用する。ここでは軽量な実装を行う。
        static htmlfile := ComObject("htmlfile")
        htmlfile.write('<script>Object.prototype.toJSON = function() { return JSON.stringify(this); };</script>')
        return this._JsToAhk(htmlfile.parentWindow.JSON.parse(json))
    }

    _JsToAhk(jsObj) {
        if !IsObject(jsObj)
            return jsObj
        
        try {
            if (jsObj.length != "") {
                ; 配列の場合
                ahkArr := []
                loop jsObj.length
                    ahkArr.Push(this._JsToAhk(jsObj.%A_Index-1%))
                return ahkArr
            }
        } catch {
            ; length プロパティがない場合はオブジェクトとして処理
        }

        ; オブジェクトの場合
        ahkObj := {}
        for prop in jsObj {
            ahkObj.%prop% := this._JsToAhk(jsObj.%prop%)
        }
        return ahkObj
    }
}
