
#SingleInstance force

; Define the hotkey to trigger the script <Ctrl+Shift+T>
^+t::{

    global script_exitingFlag:= false
    global script_typingFlag:= false
    global script_speed:= 1.0
    global script_subDocDelimiter:= "¬"
    global script_subDocs:= [""]
    global script_pos:= 1
    global script_minKeyDelay:= 8
    global script_maxKeyDelay:= 96
    global script_minEnterDelay:= 128 
    global script_maxEnterDelay:= 256 
    global script_playSounds:= true
    global script_showMessages:= true

    ; Usage: AutoHotkey.exe CipBoardTextTyper.ahk <subDocDelimiter> <showMessages> <playSounds>
    ;
    ; subDocDelimiter   : The character that seperates sub-documents in the clipboard. Default '¬'
    ; showMessages      : Whether to show or surpress script messages. Default 'On' 
    ; playSounds        : Whether to play startup and exit sounds. Default 'On'
    ;
    ; Example: Sets the delimter to '#' and suppresses script messages
    ;
    ;   AutoHotkey.exe CipBoardTextTyper.ahk # off on
    ; 
    ProcessScriptParameters()

    ; Read the clipboard and set an event up in case it changes
    ReadClipboardHandler(1)
    OnClipboardChange ReadClipboardHandler

    PlayStartingSound()
    
    ; show help
    msg:= "Started"
    msg.= "`n" . "<Ctrl+Shift+Esc> to quit"
    msg.= "`n" . "<Ctrl+Shift+V> to type next sub-document"
    msg.= "`n" . "<Ctrl+Shift+Up> to move back to previous sub-document"
    msg.= "`n" . "<Ctrl+Shift+Down> to move forward to next sub-document"
    msg.= "`n" . "<Ctrl+Shift+Left> to reduce typing speed"
    msg.= "`n" . "<Ctrl+Shift+Right> to increase typing speed"
    msg.= "`n" . "<Ctrl+Shift+M> to toggle messages on/off"
    msg.= "`n" . "<Ctrl+Shift+S> to toggle sounds on/off"
    ShowMessage(msg,5)

    ; Activate in-script hot-keys
    Hotkey "^+Escape", ExitHandler, "On"
    Hotkey "^+Up", PreviousDocHandler, "On"
    Hotkey "^+Down", NextDocHandler, "On"
    Hotkey "^+Left", ReduceSpeedHandler, "On"
    Hotkey "^+Right", IncreaseSpeedHandler, "On"
    Hotkey "^+V", TypeDocHandler, "On"
    Hotkey "^+M", ToggleMessagesHandler, "On"
    Hotkey "^+S", ToggleSoundHandler, "On"

    while not script_exitingFlag
    {
        Sleep(10)
    }

    ; De-activate in-script-hot-keys
    Hotkey  "^+Escape", "Off", "Off"
    Hotkey  "^+Up", "Off", "Off"
    Hotkey  "^+Down", "Off", "Off"
    Hotkey  "^+Left", "Off", "Off"
    Hotkey  "^+Right", "Off", "Off"
    Hotkey  "^+V", "Off", "Off"
    Hotkey  "^+M", "Off", "Off"
    Hotkey  "^+S", "Off", "Off"

    PlayExitingSound()

    ShowMessage("Exited.",1)

    exit

    ;---[End of main script]---------------------------------------------------------------

    ExitHandler(key)
    {
        global script_exitingFlag:= true
    }
    
    ProcessScriptParameters()
    {
        if A_Args.Length > 0
        {
            global script_subDocDelimiter:= SubStr(A_Args[1],1,1)
        }
        if A_Args.Length > 1
        {
            global script_showMessages:= StrCompare(A_Args[1],"on","Off") = 0
        }
        if A_Args.Length > 2
        {
            global script_playSounds:= StrCompare(A_Args[1],"on","Off") = 0
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

            isFirstLineOptions:= StrCompare(SubStr(A_Clipboard, 1, 9),"{options ","Off") = 0
            if isFirstLineOptions
            {
                firstLinefeed:= InStr(A_Clipboard,"`n")
                firstLine:= SubStr(A_Clipboard, 1, firstLinefeed)
                ProcessFirstLineOptions(firstLine)
                script_subDocs:= StrSplit(SubStr(A_Clipboard,firstLinefeed+1),script_subDocDelimiter)
            }
            else
            {
                script_subDocs:= StrSplit(A_Clipboard,script_subDocDelimiter)
            }

            script_subDocs.InsertAt(script_subDocs.Length+1, "")
            script_pos:= 1
        }
    }

    ProcessFirstLineOptions(optionsLine)
    {
        options:= StrSplit(Trim(SubStr(StrLower(StrReplace(optionsLine," ")),9),"} `n`r"),",")

        Loop options.Length
        {
            keyval:= StrSplit(options[A_Index],"=")

            switch keyval[1]
            {
                case "delimeter":
                    global script_subDocDelimiter:= SubStr(keyval[2],1)

                case "messages":
                    global script_showMessages:= StrCompare(keyval[2],"on","Off") = 0

                case "sounds":
                    global script_playSounds:= StrCompare(keyval[2],"on","Off") = 0

                default:
                    ; ignore
            }

        }

    }

    ToggleMessagesHandler(key)
    {
        global script_showMessages:= !script_showMessages
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

    ToggleSoundHandler(key)
    {
        global script_playSounds:= !script_playSounds
        if script_typingFlag
        {
            if script_playSounds 
            {
                SoundLoop(A_ScriptDir . "\ClipboardTextTyper-start.wav")
            }
            else  
            {
                SoundLoop("")
            }
        } 
        ShowMessage("Sound: " . script_playSounds ? "ON": "OFF",1)
    }

    PlayStartingSound()
    {
        global script_playSounds
        if script_playSounds
        {
            SoundPlay(A_WinDir . "\Media\Windows Information Bar.wav")
        }
    }

    PlayExitingSound()
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
        if key != ""
        {
            ShowMessage(CurrentDocumentSummary(),2)
        }
    }

    NextDocHandler(key)
    {
        global script_pos:= Min(script_subDocs.Length,script_pos+1)
        if key != ""
        {
            ShowMessage(CurrentDocumentSummary(),2)
        }
    }

    CurrentDocumentSummary()
    {
        summary:= script_pos = script_subDocs.Length ? "<End>": "Sub-document " . script_pos . " of " . script_subDocs.Length-1
        summary.= "`n`n" . SubStr(Trim(script_subDocs[script_pos]),1,128) 
        summary.= StrLen(Trim(script_subDocs[script_pos])) > 128 ? "..." : ""
        return summary
    }

    ReduceSpeedHandler(key)
    {
        global script_speed:= Max(0.01,Round(script_speed/1.25,2)+0)
        if key != ""
        {
            ShowMessage("Typing speed: " . script_speed,1)
        }
    }

    IncreaseSpeedHandler(key)
    {
        global script_speed:= Min(128,Round(script_speed*1.25,2)+0)
        if key != ""
        {
            ShowMessage("Typing speed: " . script_speed,1)
        }
    }

    TypeDocHandler(key)
    {
        global script_subDocs
        global script_pos

        subDocument:= script_subDocs[script_pos]

        isMacro:= StrCompare(SubStr(subDocument, 1, 7),"{macro}","Off") = 0

        if isMacro
        {
            SendInput(SubStr(subDocument, 8))
        }
        else
        {
            TypeText(subDocument)
        }

        ; Select next sub-document, supress message if active
        NextDocHandler("")
    }

    TypeText(textToType)
    {

        global script_typingFlag
        global script_speed
        global script_playSounds
        global script_minKeyDelay
        global script_maxKeyDelay
        global script_spaceMinKeyDelay
        global script_spaceMaxKeyDelay

        len:= StrLen(textToType)
        strpos:= 1
        spaces := ""

        script_typingFlag:= true

        SoundLoop(A_ScriptDir . "\ClipboardTextTyper-start.wav")

        while not script_exitingFlag
        {
            char := SubStr(textToType, strpos, 1)

            switch char
            {
                ; type multiple sequential spaces all at once
                ; gives a better "tab"-esque effect
                case " ":
                    spaces:= spaces . " "
                
                ; carriage return 
                case "`r":
                    ;ignore it

                ; new line
                case "`n":
                    Sleep(Random(script_minEnterDelay/script_speed,script_maxEnterDelay/script_speed))
                    SendInput("{Enter}")
                    spaces:= ""

                ; everything else
                default:
                    Sleep(Random(script_minKeyDelay/script_speed, script_maxKeyDelay/script_speed))
                    SendText(spaces . char)
                    spaces:= ""
            }

            if strpos++ > len
            {
                break
            }
        }

        script_typingFlag:= false
        SoundLoop("")

    }

    SoundLoop(File := "") {
        ; http://msdn.microsoft.com/en-us/library/dd743680(v=vs.85).aspx
        ; SND_ASYNC       0x00000001  /* play asynchronously */
        ; SND_NODEFAULT   0x00000002  /* silence (!default) if sound not found */
        ; SND_LOOP        0x00000008  /* loop the sound until next sndPlaySound */
        ; SND_NOWAIT      0x00002000  /* don't wait if the driver is busy */
        ; SND_FILENAME    0x00020000  /* name is file name */
        ; --------------- 0x0002200B
        return DllCall("Winmm.dll\PlaySoundW", 'Ptr', File = "" ? 0 : StrPtr(File), 'Ptr', 0, 'UInt', 0x0002200B)
    }
}
