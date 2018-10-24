IncludeFile "Stream_mod.pb"
UseModule Stream
OpenConsole()
StreamID = Random(9999)

counter = 1
Filepath$ = OpenFileRequester("Choose File to Stream copy.","","*.*",0)
activefolder$ = CreateTempfolder()

Result$ = Createstreamfile("",Filepath$,activefolder$)

LoadStreamSequence(StreamID,Result$)
parts = GetStreamPartAmmount(StreamID)
Filename$ = RetrieveStreamFileName(StreamID) 
OpenFile(50,activefolder$+Filename$)


While counter <> parts+1
  PrintN(Str(counter))
  Streamout$ = LoadStreamPiece(StreamID,counter)
  *memory = RetrieveMemAddress(Streamout$)
  act = RetrieveActRead(Streamout$)
  WriteData(50,*memory,act)
  FreeMemory(*memory)
  counter+1
  Delay(10)
Wend
Debug counter
  
Input()

; IDE Options = PureBasic 5.62 (Windows - x64)
; CursorPosition = 25
; EnableXP