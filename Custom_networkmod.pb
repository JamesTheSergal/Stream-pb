DeclareModule net
  Declare.i StartServer(port)
  ;Declare.i StartClient(serveraddress$,port)
  ;- Server Globals
  Global NewList serverIDs.i()
  Global mapaccess = CreateMutex()
  Global mapmemlis = CreateMutex()
  Global memthread = CreateMutex()
  Global NewMap Threads.i()
  Global NewMap Memlist.i()
  
  ;- Client Globals
  Declare.i StartClient(ClientAgent,Address$,port)
  Declare.s ClientSendDataWait(ClientAgent,String$)
  Structure liz
    Address.s
    port.i
    ThreadID.i
    Status.i
  EndStructure
  Structure xob
    ClientAgent.i
    returncode.s
    message.s
  EndStructure
  Global NewMap Clients.liz()
  Global ClientlizMutx = CreateMutex()
  Global sendmutex = CreateMutex()
  Global inmutex = CreateMutex()
  Global NewList Outbox.xob()
  Global NewList Inbox.xob()
  
  
EndDeclareModule


Module net
  Declare serverthread(port)
  Declare ServerIndividualThread(ClientID)
  Declare ClientThread(ClientAgent)
  Declare ServerSend(ClientID,retco$,message$)
  Declare.s ServerExtractData(FormedMessage$)
  ;Declare ClientSendData(ClientAgent,String$)
  InitNetwork()
  
  ;- Server
  
  Procedure.i StartServer(port)
    ;CreateThread(@serverthread(),port)
    serverthread(port)
  EndProcedure
  
  Procedure serverthread(port)
;     Structure lz
;     address.i
;     status.i
;     EndStructure
    Debug "Server Started"
    ServerID = Random(9999,0)
    Debug ServerID
    CreateNetworkServer(ServerID,port)
    
    Repeat
      
      ServerEvent = NetworkServerEvent()
      
      If ServerEvent
        ClientID = EventClient()
        Select ServerEvent
            
          Case #PB_NetworkEvent_Connect
            Debug "Client connected."
            Thread = CreateThread(@ServerIndividualThread(),ClientID)
            ResetMap(Threads())
            AddMapElement(Threads(),Str(ClientID))
            Threads() = Thread
            
            
          Case #PB_NetworkEvent_Disconnect
            Debug "Client: "+Str(ClientID)+" Disconnected."
            LockMutex(mapaccess)
            Debug Str(Threads(Str(ClientID)))+" Is the Thread ID."
            KillThread(Threads(Str(ClientID)))
            DeleteMapElement(Threads(),Str(ClientID))
            UnlockMutex(mapaccess)
            Debug "killed thread"
            
          Case #PB_NetworkEvent_Data
            *ReceiveBuffer = AllocateMemory(65536)
            ReceiveNetworkData(ClientID,*ReceiveBuffer,65536)
            LockMutex(mapmemlis)
            AddMapElement(Memlist(),Str(ClientID))
            Memlist(Str(ClientID)) = *ReceiveBuffer
            UnlockMutex(mapmemlis)
            
            
        EndSelect
      Else
        Delay(1)
      EndIf
      
;       ; thread memory check.
;       LockMutex(mapmemlis)
;       ResetMap(Memlist)
;       While NextMapElement(Memlist())
;         If Memlist() \status = 1
;           Debug "Freeing memory: "+Memlist()
;           FreeMemory(Memlist())
;         EndIf
;       Wend
;       UnlockMutex(mapmemlis)
;       ;

    ForEver

  EndProcedure
  
  Procedure ServerIndividualThread(ClientID)
    Debug "Individual thread started."
    NewList ToBeFree.i()
    NewList 
    
    Repeat  
      Delay(5)
      If FindMapElement(Memlist(),Str(ClientID)) 
        ;LockMutex(mapmemlis)
        ResetMap(MemList())
        FindMapElement(Memlist(),Str(ClientID)) 
        memory = Memlist(Str(ClientID))
        received$ = PeekS(memory)
        FreeMemory(memory)
        DeleteMapElement(Memlist(),Str(ClientID))
        message$ = StringField(received$,2,"<sep-ret*message>")
        retco$ = StringField(received$,1,"<sep-ret*message>")
    
    ;- custom commands section
    
   If message$ <> "" 
    Select message$
      Case "ping"
        Debug "Sent a ping response."
        serversend(ClientID,retco$,"pong")
        
      Case "status"
        Debug "Gathering Information..."
        LockMutex(mapaccess)
        Clients = MapSize(Threads())
        UnlockMutex(mapaccess)
        LockMutex(mapmemlis)
        act = MapSize(Memlist())
        UnlockMutex(mapmemlis)
        send$ = "There are "+Str(Clients)+" Active Client(s) and "+Str(act)+" pending jobs"
        serversend(ClientID,retco$,send$) 
        
      Default
        Command$ = StringField(message$,1,"(")
    EndSelect
  EndIf
  
  If command$ <> ""
    Select Command$
      Case "Login"
        
        Param$ = StringField(message$,2,"(")
        Param$ = StringField(Param$,1,")")
        If Param$ <> ""
          
        Else
          Debug "Login Data invalid."
        EndIf
        
      Case "CreateUser"
        Param$ = ServerExtractData(message$)
        User$ = StringField(Param$,1,"|||")
        Password$ = StringField(Param$,2,"|||")
        datahandler::AddInsDestVal("Users","Name",User$)
        datahandler::AddInsDestVal("Users","Password",Password$)
        datahandler::Insertdata(1,"Users")
    EndSelect
  EndIf
  
    ;- end of custom commands section
    message$ = ""
    Command$ = ""

  EndIf
   fail:
      Delay(1)

    Until exit = 1
  EndProcedure
  
  Procedure ServerSend(ClientID,retco$,message$)
    SendNetworkString(ClientID,retco$+"<sep-ret*message>"+message$,#PB_Unicode)
  EndProcedure
  
  Procedure.s ServerExtractData(FormedMessage$)
;     Actual$ = StringField(FormedMessage$,2,"(")
;     actlen = Len(actual$)
;     Actual$ = Left(Actual$,actlen-1)
    
    count = Len(FormedMessage$)
    open = FindString(FormedMessage$,"(")
    extract = count-open
    Semi$ = Right(FormedMessage$,extract)
    Actual$ = Left(Semi$,extract-1)
    
    
    ProcedureReturn Actual$
  EndProcedure
  
  
  ;- Client
  
  Procedure.i StartClient(ClientAgent,Address$,port)
    LockMutex(ClientlizMutx)
    If FindMapElement(Clients(),Str(ClientAgent))
      If Clients() \Status = 0
        Clients() \Address = Address$
        Clients() \port = port
        Thread = CreateThread(@ClientThread(),ClientAgent)
        ;Input()
        ;ClientThread(ClientAgent)
        Clients() \ThreadID = Thread
        UnlockMutex(ClientlizMutx)
      Else
        Debug "ClientAgent Number already in use."
      EndIf
      Else
    AddMapElement(Clients(),Str(ClientAgent))
    Clients() \Address = Address$
    Clients() \port = port
    Thread = CreateThread(@ClientThread(),ClientAgent)
        ;Input()
        ;ClientThread(ClientAgent)
    Clients() \ThreadID = Thread
    UnlockMutex(ClientlizMutx)
  EndIf
  
  EndProcedure
  
  Procedure ClientThread(ClientAgent)
    LockMutex(ClientlizMutx)
    If FindMapElement(Clients(),Str(ClientAgent))
      ConnAddress$ = Clients() \Address
      ConnPort = Clients() \port
      Clients() \Status = 1
      UnlockMutex(ClientlizMutx)
    Else
      Clients() \Status = 0
      UnlockMutex(ClientlizMutx)
      Debug "Error. Could not find Client Agent Map element."
    EndIf
    
    ConnectionID = OpenNetworkConnection(ConnAddress$,ConnPort)
    If ConnectionID
      Repeat
        ; send out any data so that it is possible we can get data back quicker.
        LockMutex(sendmutex)
        ResetList(Outbox())
        While NextElement(Outbox())
          If Outbox() \ClientAgent = ClientAgent
            retco$ = Outbox() \returncode
            Message$ = Outbox() \message
            UnlockMutex(sendmutex)
            SendNetworkString(ConnectionID,retco$+"<sep-ret*message>"+Message$,#PB_Unicode)
            LockMutex(sendmutex)
            DeleteElement(Outbox())
          EndIf
        Wend
        UnlockMutex(sendmutex)
        
        
        
        ; Check for incoming data.
        CliEvent = NetworkClientEvent(ConnectionID)
        If CliEvent
          Select CliEvent
              
            Case #PB_NetworkEvent_Data
              Debug "Client has received data."
              *ReceiveBuffer = AllocateMemory(65536)
              PeekS(*ReceiveBuffer,65536,#PB_Unicode)
              ReceiveNetworkData(ConnectionID,*ReceiveBuffer,65536)
              Received$ =  PeekS(*ReceiveBuffer)
              FreeMemory(*ReceiveBuffer)
              
              
              retco$ = StringField(Received$,1,"<sep-ret*message>")
              message$ = StringField(Received$,2,"<sep-ret*message>")
              LockMutex(inmutex)
              AddElement(inbox())
              Inbox() \ClientAgent = ClientAgent
              Inbox() \message = Message$
              Inbox() \returncode = retco$
              UnlockMutex(inmutex)
              
            Case #PB_NetworkEvent_Disconnect
              MessageRequester("Server-side","Server has shutdown or disconnected.")
              exit = 1
              LockMutex(ClientlizMutx)
              Clients(Str(ClientAgent)) \Status = 0
              UnlockMutex(ClientlizMutx)
          EndSelect
        Else
          Delay(1)
        EndIf
        
          
        Until exit = 1
    Else
      LockMutex(ClientlizMutx)
      Clients(Str(ClientAgent)) \Status = 0
      UnlockMutex(ClientlizMutx)
      Debug "Error, Was unable to connect to server."
    EndIf
 
  EndProcedure
  
  Procedure.s ClientSendDataWait(ClientAgent,String$)
    returncode$ = Str(Random(9999,0))
    LockMutex(sendmutex)
    InsertElement(Outbox())
    Outbox() \ClientAgent = ClientAgent
    Outbox() \message = String$
    Outbox() \returncode = returncode$
    UnlockMutex(sendmutex)
    
    retry:
    LockMutex(inmutex)
    ResetList(Inbox())
    ForEach Inbox()
      If Inbox() \ClientAgent = ClientAgent
        Debug "Looking for "+Str(ClientAgent)+" found "+Inbox() \ClientAgent
        If Inbox() \returncode = returncode$
          Message$ = Inbox() \message
          DeleteElement(Inbox())
          Break
        EndIf
      EndIf
      If ListIndex(Inbox()) = ListSize(Inbox())
        ResetList(Inbox())
        UnlockMutex(inmutex)
        Delay(100)
        LockMutex(inmutex)
      EndIf
    Next
    UnlockMutex(Inmutex)
    Delay(12)
    If message$ = ""
      Goto retry
    EndIf
      ProcedureReturn Message$  
    
  EndProcedure
  
  
EndModule 

; IDE Options = PureBasic 5.62 (Windows - x64)
; CursorPosition = 120
; FirstLine = 55
; Folding = Tw
; EnableXP
; Executable = ServerTest.exe