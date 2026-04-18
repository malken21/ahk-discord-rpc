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
        resolvedPath := this._GetPath(path)
        if !FileExist(resolvedPath)
            return false
        
        try {
            content := FileRead(resolvedPath, "UTF-8")
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
        
        resolvedPath := this._GetPath(path)
        try {
            content := ""
            if FileExist(resolvedPath)
                content := FileRead(resolvedPath, "UTF-8")
        
        lines := StrSplit(content, "`n", "`r")
        found := false
        newLines := []
        
        for line in lines {
            line := Trim(line)
            if (line == "")
                continue
            
            if RegExMatch(line, "^" . key . "=", &m) {
                newLines.Push(key . '="' . value . '"')
                found := true
            } else {
                newLines.Push(line)
            }
        }
        
        if (!found) {
            newLines.Push(key . '="' . value . '"')
        }
        
        out := ""
        for line in newLines {
            out .= line . "`r`n"
        }
        
            f := FileOpen(resolvedPath, "w", "UTF-8")
            f.Write(out)
            f.Close()
            return true
        } catch as e {
            OutputDebug("DotEnv Write Error: " . e.Message)
            return false
        }
    }

    /**
     * 相対パスを A_ScriptDir を起点とした絶対パスに変換する
     * @param {String} path 
     * @returns {String} 
     */
    static _GetPath(path) {
        if (RegExMatch(path, "^[a-zA-Z]:") || SubStr(path, 1, 2) == "\\")
            return path
        return A_ScriptDir . "\" . path
    }
}
