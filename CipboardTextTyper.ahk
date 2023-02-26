
#SingleInstance force

; Define the hotkey to trigger the script <Ctrl+Shift+T>
^+t::{

    global script_exitingFlag:= False
    global script_speed:= 1.0
    global script_subDocDelimiter:= "¬"
    global script_subDocs:= [""]
    global script_pos:= 1
    global script_minKeyDelay:= 8
    global script_maxKeyDelay:= 96
    global script_minSpaceDelay:= 128 
    global script_maxSpaceDelay:= 256 
    global script_playSounds:= true
    global script_showMessages:= true

    ; Usage: AutoHotkey.exe CipBoardTextTyper.ahk <subDocDelimiter> <showMessages> <playSounds>
    ;
    ; subDocDelimiter   : The character that seperates sub-documents in the clipboard. Default '¬'
    ; showMessages      : Whether to show or surpress script messages. Default 'true' 
    ; playSounds        : Whether to play startup and exit sounds. Default 'true'
    ;
    ; Example: Sets the delimter to '#' and suppresses script messages
    ;
    ;   AutoHotkey.exe CipBoardTextTyper.ahk # false true
    ; 
    ProcessScriptParameters()
    
    PlayStartSound()

    ; show help
    msg:= "Started"
    msg:= msg . "`n" . "<Esc> to quit"
    msg:= msg . "`n" . "<Ctrl+Shift+V> to type next sub-document"
    msg:= msg . "`n" . "<Ctrl+Shift+Up> to move back to previous sub-document"
    msg:= msg . "`n" . "<Ctrl+Shift+Down> to move forward to next sub-document"
    msg:= msg . "`n" . "<Ctrl+Shift+Left> to reduce typing speed"
    msg:= msg . "`n" . "<Ctrl+Shift+Right> to increase typing speed"
    ShowMessage(msg,5)

    ; Activate in-script hot-keys
    Hotkey "^+Up", PreviousDocHandler, "On"
    Hotkey "^+Down", NextDocHandler, "On"
    Hotkey "^+Left", ReduceSpeedHandler, "On"
    Hotkey "^+Right", IncreaseSpeedHandler, "On"
    Hotkey "^+V", TypeDocHandler, "On"
    Hotkey "^+M", ToggleMessagesHandler, "On"

    ; Process the clipboard
    ReadClipboardHandler(1)
    OnClipboardChange ReadClipboardHandler

    Loop {

        if GetKeyState("Escape","P") or script_exitingFlag
        {
            break
        }
        else
        {
            Sleep(10)
        }
    }

    ; De-activate in-script-hot-keys
    Hotkey  "^+Up", "Off", "Off"
    Hotkey  "^+Down", "Off", "Off"
    Hotkey  "^+Left", "Off", "Off"
    Hotkey  "^+Right", "Off", "Off"
    Hotkey  "^+V", "Off", "Off"
    Hotkey  "^+M", "Off", "Off"

    PlayQuitSound()

    ShowMessage("Exited.",1)

    exit

    ;---[End of main script]---------------------------------------------------------------

    ProcessScriptParameters()
    {
        if A_Args.Length > 0
        {
            global script_subDocDelimiter:= SubStr(A_Args[1],1,1)
        }
        if A_Args.Length > 1
        {
            global script_showMessages:= StrCompare(A_Args[1],"true","Off") = 0
        }
        if A_Args.Length > 2
        {
            global script_playSounds:= StrCompare(A_Args[1],"true","Off") = 0
        }
    }

    ReadClipboardHandler(clipType)
    {
        ; Only process if text on clipboard
        if clipType = 1
        {
            global script_subDocDelimiter
            global script_subDocs
            global script_pos

            script_subDocs:= StrSplit(A_Clipboard,script_subDocDelimiter)
            script_subDocs.InsertAt(script_subDocs.Length+1, "")
            script_pos:= 1
        }
    }

    ShowMessage(msg, forSeconds)
    {
        global script_showMessages
        if script_showMessages
        {
            ToolTip "ClipboardTextTyper: " . msg
            SetTimer () => ToolTip(), -forSeconds*1000
        }

        return
    }

    PlayStartSound()
    {
        global script_playSounds
        if script_playSounds
        {
            SoundPlay(A_WinDir . "\Media\Windows Information Bar.wav")
        }
    }

    PlayQuitSound()
    {
        global script_playSounds
        if script_playSounds
        {
            SoundPlay(A_WinDir . "\Media\Windows Menu Command.wav")
        }
    }

    PlayCommandSound()
    {
        global script_playSounds
        if script_playSounds
        {
            SoundPlay(A_WinDir . "\Media\Windows Navigation Start.wav")
        }
    }

    PreviousDocHandler(key)
    {
        global script_pos:= Max(1,script_pos-1)
        ShowMessage("Positioned at " . script_pos . " of " . script_subDocs.Length-1,1)
    }

    NextDocHandler(key)
    {
        global script_pos:= Min(script_subDocs.Length,script_pos+1)
        ShowMessage("Positioned at " . script_pos . " of " . script_subDocs.Length-1,1)
    }

    ReduceSpeedHandler(key)
    {
        global script_speed:= Max(0.01,Round(script_speed/1.25,2)+0)
        ShowMessage("Typing speed: " . script_speed,1)
    }

    IncreaseSpeedHandler(key)
    {
        global script_speed:= Min(128,Round(script_speed*1.25,2)+0)
        ShowMessage("Typing speed: " . script_speed,1)
    }

    TypeDocHandler(key)
    {
        global script_subDocs
        global script_pos

        TypeText(script_subDocs[script_pos])
        global script_pos:= Min(script_subDocs.Length,script_pos+1)
    }

    ToggleMessagesHandler(key)
    {
        global script_showMessages:= !script_showMessages
    }

    TypeText(textToType)
    {

        global script_speed
        global script_minKeyDelay
        global script_maxKeyDelay
        global script_spaceMinKeyDelay
        global script_spaceMaxKeyDelay

        len:= StrLen(textToType)
        strpos:= 1
        spaces := ""

        Loop 
        {
            if GetKeyState("Esc","P")
            {
                global script_exitingFlag:= true
                break
            }

            char := SubStr(textToType, strpos, 1)

            switch char
            {
                ; type multiple sequential spaces all at once
                ; gives a better "tab"-esque effect
                case " ":
                    spaces:= spaces . " "

                case "`n":
                    Sleep(Random(script_minSpaceDelay/script_speed,script_maxSpaceDelay/script_speed))
                    SendInput("{Enter}")
                    spaces:= ""

                case "`r":
                    ;skip it

                default:
                    SendText(spaces . char)
                    Sleep(Random(script_minKeyDelay/script_speed, script_maxKeyDelay/script_speed))
                    spaces:= ""
            }

            if strpos++ > len
            {
                break
            }
        }

    }
}
