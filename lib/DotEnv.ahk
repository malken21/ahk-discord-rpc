/**
 * DotEnv.ahk
 * Simple .env file loader for AutoHotkey v2
 */
class DotEnv {
    /**
     * .env ファイルを読み込み、プロセス環境変数に展開する
     * @param {String} path ファイルパス
     * @returns {Boolean} ファイルが存在し読み込みに成功した場合は true
     */
    static Load(path := ".env") {
        if !FileExist(path)
            return false
        
        try {
            content := FileRead(path, "UTF-8")
            for line in StrSplit(content, "`n", "`r") {
                line := Trim(line)
                ; 空行またはコメントをスキップ
                if (line == "" || SubStr(line, 1, 1) == "#")
                    continue
                
                ; 最初の = で分割
                if RegExMatch(line, "^([^=]+)=(.*)$", &m) {
                    key := Trim(m[1])
                    val := Trim(m[2])
                    
                    ; 前後のクォート（" または '）を除去
                    if (RegExMatch(val, '^"(.*)"$', &v) || RegExMatch(val, "^'(.*)'$", &v)) {
                        val := v[1]
                        ; エスケープされた改行などを展開
                        val := StrReplace(val, "\n", "`n")
                        val := StrReplace(val, "\r", "`r")
                    }
                    
                    EnvSet(key, val)
                }
            }
            return true
        } catch as e {
            OutputDebug("DotEnv Error: " . e.Message)
            return false
        }
    }

    /**
     * 指定したキーの値を環境変数から取得する
     * @param {String} key 
     * @param {String} default デフォルト値
     */
    static Get(key, default := "") {
        val := EnvGet(key)
        return (val == "") ? default : val
    }

    /**
     * 指定したキーの値を .env ファイルに保存・更新する
     * @param {String} key 
     * @param {String} value 
     * @param {String} path 
     */
    static Write(key, value, path := ".env") {
        EnvSet(key, value)
        
        content := ""
        if FileExist(path)
            content := FileRead(path, "UTF-8")
        
        lines := StrSplit(content, "`n", "`r")
        found := false
        newLines := []
        
        for line in lines {
            if RegExMatch(line, "^" . key . "=", &m) {
                newLines.Push(key . '="' . value . '"')
                found := true
            } else {
                newLines.Push(line)
            }
        }
        
        if (!found) {
            if (newLines.Length > 0 && newLines[newLines.Length] != "")
                newLines.Push("")
            newLines.Push(key . '="' . value . '"')
        }
        
        out := ""
        for line in newLines {
            out .= line . "`r`n"
        }
        
        f := FileOpen(path, "w", "UTF-8")
        f.Write(Trim(out, "`r`n") . "`r`n")
        f.Close()
    }
}
