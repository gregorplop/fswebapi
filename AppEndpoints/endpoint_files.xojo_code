#tag Class
Protected Class endpoint_files
	#tag Method, Flags = &h21
		Private Sub APPEND()
		  // APPENDS data to the end of an existing file
		  
		  dim EOL as String
		  dim appendeol as String // appendeol , append end of line parameter
		  
		  select case RqParams.KeyCount
		  case 0
		    appendeol = "" 
		  case 1
		    if not RqParams.HasKey("appendeol") then
		      WorkerThread.SocketRef.RespondInError(400 , "appendeol is the only parameter allowed")
		      Return
		    end if
		    
		    select case RqParams.Value("appendeol").StringValue.Lowercase.Trim
		    case "native"
		      appendeol = EndOfLine.Native
		    case "windows"
		      appendeol = EndOfLine.Windows
		    case "macos"
		      appendeol = EndOfLine.macOS
		    case "unix"
		      appendeol = EndOfLine.UNIX
		    else
		      WorkerThread.SocketRef.RespondInError(400 , "appendeol parameter only accepts native/windows/macos/unix values")
		      Return
		    end select
		    
		  Case is > 1
		    WorkerThread.SocketRef.RespondInError(400 , "URL contains invalid parameters")
		    Return
		  end select
		  
		  
		  
		  // ============= walk through the path, does not try to build tree =================
		  
		  dim file as FolderItem // this is to hold the file at the end of the url path
		  
		  for i as Integer = 1 to RqPath.LastIndex - 1
		    
		    folder = folder.Child(RqPath(i) , false) // do not follow aliases for security reasons
		    
		    if IsNull(folder) then 
		      WorkerThread.SocketRef.RespondInError(404 , "Invalid path")
		      Return
		    end if
		    
		    if not folder.Exists then
		      WorkerThread.SocketRef.RespondInError(404 , "Folder does not exist")
		      Return
		    end if
		    
		    if not folder.IsFolder then
		      WorkerThread.SocketRef.RespondInError(422 , "Path points to file") // unprocessable entity
		      Return
		    end if
		    
		  next i 
		  
		  file = folder.Child(RqPath(RqPath.LastIndex)) // this should be the file
		  
		  if file.IsFolder then
		    WorkerThread.SocketRef.RespondInError(422 , "File is actually a folder") // unprocessable entity
		    Return
		  end if
		  
		  if not file.Exists then // file does not exist
		    WorkerThread.SocketRef.RespondInError(404 , "File does not exst")
		    Return
		  end if
		  
		  // ============= ready to start i/o =========================
		  
		  dim stream as BinaryStream
		  
		  try
		    
		    stream = BinaryStream.Open(file , true)  // open as read-write
		    stream.BytePosition = stream.Length // go to the end of the file
		    
		    while WorkerThread.BytesReceived < WorkerThread.SocketRef.RequestContentLength
		      
		      if WorkerThread.GetReceiveBufferChunks > 0 then
		        
		        stream.Write(WorkerThread.ReceiveBuffer(0))
		        WorkerThread.BytesReceived = WorkerThread.BytesReceived + WorkerThread.ReceiveBuffer(0).Bytes
		        WorkerThread.ReceiveBuffer.RemoveAt(0)
		        lastTX = DateTime.Now
		        
		      end if
		      
		      // receive timeout check
		      if DateTime.Now.SecondsFrom1970 - lastTX.SecondsFrom1970 > ipservercore.TimeoutOnReceive then // transfer has timed out
		        stream.Close
		        WorkerThread.SocketRef.RespondInError(408)  // Request Timeout 
		        Return
		      end if
		      
		      // no op
		      WorkerThread.YieldToNext
		      
		    wend
		    
		    stream.Write(appendeol)
		    
		    stream.Flush
		    stream.Close
		    
		    WorkerThread.SocketRef.PrepareResponseHeaders_ReceivedData
		    WorkerThread.SocketRef.RespondOK(false)
		    
		  Catch e as IOException
		    
		    stream.Close
		    WorkerThread.SocketRef.RespondInError(500 , "File IO Error: " + e.ErrorNumber.ToString) // internal server error
		    
		  end try
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Constructor()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(byref initWorkerThread as ipservercore.ipscConnectionThread, initRootFolder as FolderItem)
		  WorkerThread = initWorkerThread
		  
		  lastTX = DateTime.Now
		  WorkerThread.BytesReceived = 0
		  WorkerThread.BytesSent = 0
		  
		  // internal copies to keep code more readable
		  RqVerb = WorkerThread.SocketRef.RequestVerb.Uppercase
		  RqPath = WorkerThread.SocketRef.RequestPathArray
		  RqParams = WorkerThread.SocketRef.RequestParameters
		  folder = new FolderItem(initRootFolder) // start with the root folder, take it from there
		  
		  
		  select case RqVerb
		  case "POST" , "PUT"  // uploads a file: post fails if file exists, put overwrites the file
		    POST_PUT
		  case "GET"  // download a file
		    GET
		  case "DELETE"  // deletes the file
		    DELETE
		  case "RENAME"  // non-standard HTTP , requires url parameter newname
		    RENAME
		  case "APPEND"  // non-standard HTTP , appends to the end of the file (that has to exist)
		    APPEND
		  case "INFO"   // non-standard HTTP, returns a json with file info. can be also used as EXISTS
		    INFO
		    
		  else
		    WorkerThread.SocketRef.RespondInError(501)  // not implemented
		  end select
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DELETE()
		  dim failonabsence as Boolean = true // this boolean parameter dictates whether trying to delete a file that does not exist should result in an error or not
		  
		  select case RqParams.KeyCount
		  case 0
		    failonabsence = true // redundant, but makes it clear that the default failonabsence parameter is true
		  case 1
		    if not RqParams.HasKey("failonabsence") then
		      WorkerThread.SocketRef.RespondInError(400 , "failonabsence is the only parameter allowed")
		      Return
		    end if
		    
		    select case RqParams.Value("failonabsence").StringValue.Lowercase.Trim
		    case "true"
		      failonabsence = true
		    case "false"
		      failonabsence = false
		    else
		      WorkerThread.SocketRef.RespondInError(400 , "failonabsence parameter only accepts true/false values")
		      Return
		    end select
		    
		  Case is > 1
		    WorkerThread.SocketRef.RespondInError(400 , "URL contains invalid parameters")
		    Return
		  end select
		  
		  
		  // complete path to the file has to exist, let's build it
		  
		  dim file as FolderItem // this is to hold the file at the end of the url path
		  
		  for i as Integer = 1 to RqPath.LastIndex - 1 // walk through up to one level before the file
		    
		    folder = folder.Child(RqPath(i) , false) // do not follow aliases for security reasons
		    
		    if IsNull(folder) then 
		      WorkerThread.SocketRef.RespondInError(404 , "Invalid path")
		      Return
		    end if
		    
		    if not folder.Exists then 
		      WorkerThread.SocketRef.RespondInError(404 , "Folder does not exist")
		      Return
		    else
		      if not folder.IsFolder then
		        WorkerThread.SocketRef.RespondInError(422 , "Path points to file") // unprocessable entity
		        Return
		      end if
		    end if
		    
		  next i 
		  
		  file = folder.Child(RqPath(RqPath.LastIndex)) // this should be the file
		  
		  if not file.Exists then
		    if failonabsence then
		      WorkerThread.SocketRef.RespondInError(404 , "File does not exist")
		      Return
		    else // the file we need to delete does not exist -- consider it deleted ok!
		      WorkerThread.SocketRef.RespondOK
		      Return
		    end if
		  end if
		  
		  if file.IsFolder then
		    WorkerThread.SocketRef.RespondInError(422 , "File is actually a folder") // unprocessable entity
		    Return
		  end if
		  
		  
		  try
		    
		    file.Remove
		    
		    WorkerThread.SocketRef.RespondOK
		    
		  Catch e as IOException
		    WorkerThread.SocketRef.RespondInError(403 , "Error removing file, error code " + e.ErrorNumber.ToString)
		  end try
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub GET()
		  if RqParams.KeyCount > 0 then
		    WorkerThread.SocketRef.RespondInError(400 , "URL contains invalid parameters")
		    Return
		  end if
		  
		  // complete path to the file has to exist, let's build it
		  
		  dim file as FolderItem // this is to hold the file at the end of the url path
		  
		  for i as Integer = 1 to RqPath.LastIndex - 1 // walk through up to one level before the file
		    
		    folder = folder.Child(RqPath(i) , false) // do not follow aliases for security reasons
		    
		    if IsNull(folder) then 
		      WorkerThread.SocketRef.RespondInError(404 , "Invalid path") // unprocessable entity
		      Return
		    end if
		    
		    if not folder.Exists then 
		      WorkerThread.SocketRef.RespondInError(404 , "Folder does not exist") // unprocessable entity
		      Return
		    else
		      if not folder.IsFolder then
		        WorkerThread.SocketRef.RespondInError(422 , "Path points to file") // unprocessable entity
		        Return
		      end if
		    end if
		    
		  next i 
		  
		  file = folder.Child(RqPath(RqPath.LastIndex)) // this should be the file
		  
		  if not file.Exists then
		    WorkerThread.SocketRef.RespondInError(404 , "File does not exist")
		    Return
		  end if
		  
		  if file.IsFolder then
		    WorkerThread.SocketRef.RespondInError(422 , "File is actually a folder") // unprocessable entity
		    Return
		  end if
		  
		  // ========== we have the final file folderitem to rename ======================
		  
		  
		  dim Readable as Boolean = false  // it's not guaranteed that a file is readable until we actually read from it
		  dim FileSize as Integer = file.Length
		  dim chunk as String
		  dim n as Integer = 10  // multiplier of default chunk size to read from file->write to socket
		  dim stream as BinaryStream
		  
		  try
		    
		    stream = BinaryStream.Open(file)
		    Readable = true // it is readable, we just opened it
		    
		    WorkerThread.SocketRef.PrepareResponseHeaders_SendBinaryFile(FileSize , file.Name)
		    WorkerThread.SocketRef.RespondOK(true) // respond ok and payload follows
		    
		    while not stream.EndOfFile
		      
		      chunk = stream.Read(ipservercore.SocketChunkSize * n)  // adjust n to taste, default is 4
		      
		      WorkerThread.SocketRef.Write(chunk)
		      WorkerThread.BytesSent = WorkerThread.BytesSent + chunk.Bytes
		      
		      // the commented-out code below was a bad approach: a cancelled download made the entire app completely unresponsive
		      // the original idea was to read a chunk from the file and write it to the socket, but it had the nasty side-effect mentioned above
		      //WorkerThread.SocketRef.Flush  // without this, it is all one big data packet
		      //WorkerThread.YieldToNext
		      
		      WorkerThread.Sleep(100)
		      
		    wend
		    
		    stream.Close
		    
		  Catch e as IOException
		    
		    stream.Close
		    
		    if not Readable or WorkerThread.BytesSent = 0 then // nothing has been sent, we can respond in error
		      WorkerThread.SocketRef.RespondInError(423 , "Unreadable file , IO error " + e.ErrorNumber.ToString)  // locked
		      Return
		    end if
		    
		    // we got an io error while we had already started sending an OK response
		    // we just kill the connection and hope the client can detect it's incomplete
		    
		    WorkerThread.SocketRef.Disconnect
		    WorkerThread.SocketRef.Close
		    Return
		    
		  end try
		  
		  
		  // make sure the last packet has been sent
		  while WorkerThread.SocketRef.IsConnected and WorkerThread.SocketRef.BytesLeftToSend > 0
		    WorkerThread.Sleep(100)
		  wend
		  
		  
		  // close the socket here, closing it on the socket's last SendComplete has caused some mis-timings
		  //if not WorkerThread.SocketRef.SSLEnabled then // if not ssl, close it here. if sll, it's gonna close by itself?
		  //WorkerThread.SocketRef.Disconnect
		  //WorkerThread.SocketRef.Close
		  //end if
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub INFO()
		  if RqParams.KeyCount <> 0 then
		    WorkerThread.SocketRef.RespondInError(400 , "URL contains invalid parameters")
		    Return
		  end if
		  
		  // complete path to the file has to exist, let's build it
		  
		  dim file as FolderItem // this is to hold the file at the end of the url path
		  
		  for i as Integer = 1 to RqPath.LastIndex - 1 // walk through up to one level before the file
		    
		    folder = folder.Child(RqPath(i) , false) // do not follow aliases for security reasons
		    
		    if IsNull(folder) then 
		      WorkerThread.SocketRef.RespondInError(404 , "Invalid path") 
		      Return
		    end if
		    
		    if not folder.Exists then 
		      WorkerThread.SocketRef.RespondInError(404 , "Folder does not exist")
		      Return
		    else
		      if not folder.IsFolder then
		        WorkerThread.SocketRef.RespondInError(422 , "Path points to file") // unprocessable entity
		        Return
		      end if
		    end if
		    
		  next i 
		  
		  file = folder.Child(RqPath(RqPath.LastIndex)) // this should be the file
		  
		  if not file.Exists then
		    WorkerThread.SocketRef.RespondInError(404 , "File does not exist") 
		    Return
		  end if
		  
		  if file.IsFolder then
		    WorkerThread.SocketRef.RespondInError(422 , "File is actually a folder") // unprocessable entity
		    Return
		  end if
		  
		  
		  // we have the final file folderitem to rename
		  
		  dim infoPayload as new JSONItem
		  
		  infoPayload.Compact = false
		  
		  infoPayload.Value("name") = file.Name
		  infoPayload.Value("folder") = file.Parent.NativePath.Replace(app.RootFolder.NativePath , empty)
		  infoPayload.Value("size") = file.Length.ToString
		  infoPayload.Value("createstamp") = file.CreationDateTime.SQLDateTime
		  infoPayload.Value("modifystamp") = file.ModificationDateTime.SQLDateTime
		  infoPayload.Value("permissions") = file.Permissions.ToString
		  
		  WorkerThread.SocketRef.RespondOK(infoPayload.ToString)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub POST_PUT()
		  // PUT overwrites if target file exists, POST return an error in that case
		  
		  dim buildtree as Boolean = false // url parameter that creates the entire path to file, if not exist
		  dim overwrite as Boolean = false
		  
		  select case RqVerb
		  case "POST"
		    overwrite = false
		  case "PUT"
		    overwrite = true
		  end select
		  
		  select case RqParams.KeyCount
		  case 0
		    buildtree = False // redundant, but makes it clear that the default buildtree parameter is false
		  case 1
		    if not RqParams.HasKey("buildtree") then
		      WorkerThread.SocketRef.RespondInError(400 , "buildtree is the only parameter allowed")
		      Return
		    end if
		    
		    select case RqParams.Value("buildtree").StringValue.Lowercase.Trim
		    case "true"
		      buildtree = true
		    case "false"
		      buildtree = false
		    else
		      WorkerThread.SocketRef.RespondInError(400 , "buildtree parameter only accepts true/false values")
		      Return
		    end select
		    
		  Case is > 1
		    WorkerThread.SocketRef.RespondInError(400 , "URL contains invalid parameters")
		    Return
		  end select
		  
		  // ============= walk through the path, creating folders if necessary =================
		  
		  dim file as FolderItem // this is to hold the file at the end of the url path
		  dim created(-1) as FolderItem
		  
		  for i as Integer = 1 to RqPath.LastIndex - 1
		    
		    folder = folder.Child(RqPath(i) , false) // do not follow aliases for security reasons
		    
		    if IsNull(folder) then 
		      WorkerThread.SocketRef.RespondInError(404 , "Invalid path")
		      Return
		    end if
		    
		    if not folder.Exists then
		      
		      if buildtree then
		        
		        try
		          folder.CreateFolder
		          created.Add new FolderItem(folder)
		        Catch e as IOException
		          call infoplastique.DeleteFSitems(created) // try to cleanup, fail silently if unable
		          WorkerThread.SocketRef.RespondInError(422 , "Error creating folder, error " + e.ErrorNumber.ToString) // unprocessable entity
		          Return
		        end try
		        
		      else
		        
		        WorkerThread.SocketRef.RespondInError(404 , "Folder does not exist")
		        Return
		        
		      end if
		      
		    else
		      
		      if not folder.IsFolder then
		        WorkerThread.SocketRef.RespondInError(422 , "Path points to file") // unprocessable entity
		        Return
		      end if
		      
		    end if
		    
		  next i 
		  
		  file = folder.Child(RqPath(RqPath.LastIndex)) // this should be the file
		  
		  if file.Exists and file.IsFolder then
		    WorkerThread.SocketRef.RespondInError(422 , "File is actually a folder") // unprocessable entity
		    Return
		  end if
		  
		  if file.Exists and not overwrite then // file already exists and we're not allowed to overwrite
		    WorkerThread.SocketRef.RespondInError(409 , "File already exists") // conflict
		    Return
		  end if
		  
		  // ============= ready to start i/o =========================
		  
		  dim stream as BinaryStream
		  
		  try
		    
		    stream = BinaryStream.Create(file , overwrite)
		    
		    created.Add file
		    
		    
		    while WorkerThread.BytesReceived < WorkerThread.SocketRef.RequestContentLength
		      
		      if WorkerThread.GetReceiveBufferChunks > 0 then
		        
		        stream.Write(WorkerThread.ReceiveBuffer(0))
		        WorkerThread.BytesReceived = WorkerThread.BytesReceived + WorkerThread.ReceiveBuffer(0).Bytes
		        WorkerThread.ReceiveBuffer.RemoveAt(0)
		        lastTX = DateTime.Now
		        
		      end if
		      
		      //receive timeout check
		      if DateTime.Now.SecondsFrom1970 - lastTX.SecondsFrom1970 > ipservercore.TimeoutOnReceive then // transfer has timed out
		        stream.Close
		        call infoplastique.DeleteFSitems(created)
		        WorkerThread.SocketRef.RespondInError(408)  // Request Timeout 
		        Return
		      end if
		      
		      // no op
		      //WorkerThread.YieldToNext   // this doesn't work very well
		      
		      WorkerThread.Sleep(2)  // this works best
		      
		    wend
		    
		    
		    stream.Flush
		    stream.Close
		    
		    WorkerThread.SocketRef.PrepareResponseHeaders_ReceivedData
		    WorkerThread.SocketRef.RespondOK(false)
		    
		  Catch e as IOException
		    
		    stream.Close
		    call infoplastique.DeleteFSitems(created)
		    WorkerThread.SocketRef.RespondInError(500 , "File IO Error: " + e.ErrorNumber.ToString) // internal server error
		    
		  end try
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub RENAME()
		  if not RqParams.HasKey("newname") then
		    WorkerThread.SocketRef.RespondInError(400 , "newname URL parameter missing")
		    Return
		  end if
		  
		  if RqParams.KeyCount <> 1 then
		    WorkerThread.SocketRef.RespondInError(400 , "URL contains invalid parameters")
		    Return
		  end if
		  
		  // complete path to the file has to exist, let's build it
		  
		  dim file as FolderItem // this is to hold the file at the end of the url path
		  
		  for i as Integer = 1 to RqPath.LastIndex - 1 // walk through up to one level before the file
		    
		    folder = folder.Child(RqPath(i) , false) // do not follow aliases for security reasons
		    
		    if IsNull(folder) then 
		      WorkerThread.SocketRef.RespondInError(404 , "Invalid path") 
		      Return
		    end if
		    
		    if not folder.Exists then 
		      WorkerThread.SocketRef.RespondInError(404 , "Folder does not exist")
		      Return
		    else
		      if not folder.IsFolder then
		        WorkerThread.SocketRef.RespondInError(422 , "Path points to file") // unprocessable entity
		        Return
		      end if
		    end if
		    
		  next i 
		  
		  file = folder.Child(RqPath(RqPath.LastIndex)) // this should be the file
		  
		  if not file.Exists then
		    WorkerThread.SocketRef.RespondInError(404 , "File does not exist") 
		    Return
		  end if
		  
		  if file.IsFolder then
		    WorkerThread.SocketRef.RespondInError(422 , "File is actually a folder") // unprocessable entity
		    Return
		  end if
		  
		  
		  // we have the final file folderitem to rename
		  
		  dim newFilename as String = RqParams.Value("newname").StringValue.Trim
		  dim oldFilename as String = file.Name
		  
		  try
		    
		    file.Name = newFilename
		    
		    WorkerThread.SocketRef.RespondOK
		    
		  Catch e as IOException
		    WorkerThread.SocketRef.RespondInError(403 , "Error renaming """ + oldFilename + """ to """ + newFilename + """ , error code " + e.ErrorNumber.ToString)
		  end try
		  
		  
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private folder As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h21
		Private lastTX As DateTime
	#tag EndProperty

	#tag Property, Flags = &h21
		Private RqParams As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private RqPath() As string
	#tag EndProperty

	#tag Property, Flags = &h21
		Private RqVerb As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private WorkerThread As ipservercore.ipscConnectionThread
	#tag EndProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
