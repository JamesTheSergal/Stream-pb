Streamfile$ = OpenFileRequester("Open Stream file","","*.stream",0)
Returnvalue = 1
Debug "Reading Name..."

If OpenFile(1,Streamfile$)
  Path$ = ReadString(1)
  If OpenFile(Path$)
    Debug "Valid File."
  Else
    Debug "Invalid File"
    ; Leave open for return value
    End
  EndIf
  
  
  
EndIf

; IDE Options = PureBasic 5.62 (Windows - x64)
; CursorPosition = 9
; EnableXP