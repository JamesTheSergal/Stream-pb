DeclareModule stream
  Declare.s CreateStreamFile(Name_opt$,Path$,Writeout_opt$)
  Declare.i LoadStreamSequence(StreamID,Path$)
  Declare.i GetStreamPartAmmount(StreamID)
  Declare.s LoadStreamPiece(StreamID,num)
  Declare.i RetrieveMemAddress(FromLoadStream$)
  Declare.i RetrieveActRead(FromLoadStream$)
  Declare.s CreateTempfolder()
  Declare.s RetrieveStreamFileName(StreamID) 
  Structure pf
    parts.i
    tempfolder.s
    Path.s
    Location.s
  EndStructure
 
  Global NewMap StreamMap.pf()
EndDeclareModule

Module stream
  
  ; Creating Stream Files
  
  Procedure.s CreateStreamFile(Name_opt$,FilePath$,Writeout_opt$)
    
NewList PartsLocations()
Maxbytes = 65535
Filepos = 0


If OpenFile(1,Filepath$)
  filebytes = Lof(1)
  parts.f = filebytes / Maxbytes
  parts.f = Round(parts.f,#PB_Round_Up )
  Debug "Parts:"
  Debug parts
  FileSeek(1,0)
  
  AddElement(PartsLocations())
  PartsLocations() = 0
  
  Debug "Starting..."
  While Not Eof(1)
    Filepos = Filepos + Maxbytes 
    FileSeek(1,Filepos)
    Debug Filepos
    
    AddElement(PartsLocations())
    PartsLocations() = Filepos
    
     If (Filepos+Maxbytes) > Lof(1)
      Debug "Final Bytes --"
      Debug "File Size: " + Str(Lof(1))
      Debug "Final full pack: " + Str(Filepos)
      LastBytes = Filepos+Maxbytes - Lof(1)
      Debug "Bytes Left: " + Str(LastBytes)
      LastPos = Lof(1) - LastBytes
      Debug "Last position to Load: " + Str(LastPos)
      AddElement(PartsLocations())
      PartsLocations() = LastPos

      
      Break
    EndIf
    
  Wend
Else
  Debug "Couldn't open file"
  ProcedureReturn "Couldn't open file"
EndIf
CloseFile(1)

; Now for exporting the list

Debug "Exporting List..."
If Name_opt$ = ""
  ListName$ = Str(Random(999999))
Else
  ListName$ = Name_opt$
EndIf

If Writeout_opt$ = ""
  ; do nothing
  out$ = ListName$+".stream"
Else
  out$ = Writeout_opt$+ListName$+".stream"
  ListName$ = Writeout_opt$+ListName$
EndIf


If OpenFile(1,ListName$+".stream")
  WriteStringN(1,Filepath$)
  WriteStringN(1,"Parts: "+Str(parts))
  ResetList(PartsLocations())
  
  While NextElement(PartsLocations())
    WriteStringN(1,Str(PartsLocations()))
  Wend
Else
  Debug "Could not create stream file"
  ProcedureReturn "Could not create stream file"
EndIf
CloseFile(1)
FreeList(PartsLocations())

Debug "Done."

    ProcedureReturn out$
  EndProcedure
  
  Procedure.i LoadStreamSequence(StreamID, Path$)
    Debug "Loading Stream Sequence..."
    If FindMapElement(StreamMap(), Str(StreamID))
      ProcedureReturn 0
    Else
      
     If OpenFile(1,Path$)
      FilePath$ = ReadString(1)
      If OpenFile(2,FilePath$)
        Debug "Valid File."
        Debug "Loading Sequence..."
        Parts = Val(StringField(ReadString(1),2," "))
        Debug "Parts: "+Str(Parts)
        AddMapElement(StreamMap(),Str(StreamID))
        StreamMap(Str(StreamID))\Path = FilePath$
        StreamMap(Str(StreamID))\parts = Parts
        While Not Eof(1)
          StreamMap(Str(StreamID))\Location = StreamMap(Str(StreamID))\Location + ReadString(1) + ","
        Wend
        CloseFile(1)
        CloseFile(2)
        Debug "Loaded Sequence."
      Else
         Debug "Invalid File"
         ; Leave open for return value
         End
      EndIf
    
     EndIf


  
  
EndIf
  EndProcedure
  
  Procedure.s LoadStreamPiece(StreamID,num)
    parts = GetStreamPartAmmount(StreamID)
    pathToFile$ = StreamMap(Str(StreamID))\Path
    If parts < num
      ProcedureReturn "0"
    EndIf
    
    If num < 1
      ProcedureReturn "0"
    EndIf
    
    Pos = Val(StringField(StreamMap(Str(StreamID))\Location,num,","))
    If OpenFile(1,pathToFile$)
      FileSeek(1,Pos)
      *PieceMemory = AllocateMemory(65535)
      actread = ReadData(1,*PieceMemory,65535)
      CloseFile(1)
      ProcedureReturn Str(*PieceMemory)+"-"+Str(actread)
    Else
      ProcedureReturn "0"
    EndIf
    
      
  EndProcedure
  
  Procedure.i GetStreamPartAmmount(StreamID)
    If FindMapElement(StreamMap(),Str(StreamID))
      parts = StreamMap(Str(StreamID))\parts
      ProcedureReturn parts
    Else
      ProcedureReturn 0
    EndIf
  EndProcedure
    
  ; Utility 
  
  Procedure.i RetrieveMemAddress(FromLoadStream$)
    If FromLoadStream$ = "0"
      Debug "Error, Load Stream Piece threw error: 0"
      ProcedureReturn 0
    Else
      memaddress = Val(StringField(FromLoadStream$,1,"-"))
      ProcedureReturn memaddress
    EndIf
    
  EndProcedure
  
  Procedure.i RetrieveActRead(FromLoadStream$)
    If FromLoadStream$ = "0"
      Debug "Error, Load Stream Piece threw error: 0"
      ProcedureReturn 0
    Else
      actread = Val(StringField(FromLoadStream$,2,"-"))
      ProcedureReturn actread
    EndIf
  EndProcedure
  
  Procedure.s RetrieveStreamFileName(StreamID)  
    If FindMapElement(StreamMap(),Str(StreamID))
      FullPath$ = StreamMap(Str(StreamID))\Path
      FileName$ = GetFilePart(FullPath$)
      ProcedureReturn FileName$
    Else
      ProcedureReturn "0"
    EndIf
  EndProcedure
  
  Procedure.s CreateTempfolder()
    checks:
    tempfolder$ = Str(Random(999999))
    If FileSize("temp\") = -2
      If FileSize("temp\"+tempfolder$) = -1
        CreateDirectory("temp\"+tempfolder$)
        ProcedureReturn "temp\"+tempfolder$+"\"
      Else
        Goto checks
      EndIf
    Else
      CreateDirectory("temp\")
      Goto checks
    EndIf
    
      
  EndProcedure
  
    
EndModule

; IDE Options = PureBasic 5.62 (Windows - x64)
; CursorPosition = 74
; FirstLine = 74
; Folding = H5
; EnableXP