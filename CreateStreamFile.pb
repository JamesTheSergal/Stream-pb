NewList PartsLocations()
Maxbytes = 65535
Filepath$ = OpenFileRequester("Choose File to Stream copy.","","*.*",0)
Filepos = 0


If OpenFile(1,Filepath$)
  filebytes = Lof(1)
  parts = filebytes / Maxbytes
  Debug "Parts:"
  Debug parts
  FileSeek(1,0)
  
  AddElement(PartsLocations())
  PartsLocations() = 0
  
  Debug "Starting..."
  While Not Eof(1)
    Filepos = Filepos + Maxbytes
    FileSeek(1,Filepos)
    If (Filepos+Maxbytes) > Lof(1)
      Break
    EndIf
    
    AddElement(PartsLocations())
    PartsLocations() = Filepos
    
  Wend
Else
  Debug "Couldn't open file."
EndIf
CloseFile(1)

; Now for exporting the list

Debug "Exporting List..."
ListName$ = Str(Random(999999))

If OpenFile(1,ListName$+".stream")
  WriteStringN(1,Filepath$)
  WriteStringN(1,"Parts: "+Str(parts))
  ResetList(PartsLocations())
  
  While NextElement(PartsLocations())
    WriteStringN(1,Str(PartsLocations()))
  Wend
Else
  Debug "Could not create stream file."
EndIf
CloseFile(1)
FreeList(PartsLocations())

Debug "Done."

  
  




; IDE Options = PureBasic 5.62 (Windows - x64)
; CursorPosition = 52
; EnableXP