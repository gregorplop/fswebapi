#tag Class
Protected Class endpoint_files
	#tag Method, Flags = &h21
		Private Sub Constructor()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(byref initWorkerThread as ipsc_ConnectionThread, initRootFolder as FolderItem)
		  WorkerThread = initWorkerThread
		  
		  lastTX = DateTime.Now
		  WorkerThread.BytesReceived = 0
		  WorkerThread.BytesSent = 0
		  
		  dim path() as String = WorkerThread.SocketRef.RequestPath.Split("/")
		  path.RemoveAt(0) // remove empty
		  path.RemoveAt(0) // remove /files endpoint
		  
		  if path.LastIndex < 0 then  // it was just /files
		    WorkerThread.SocketRef.RespondInError(422)  // unprocessable entity
		    Return
		  end if
		  
		  dim verb as string = WorkerThread.SocketRef.RequestVerb.Uppercase
		  
		  dim filename as String = path.Pop
		  folder = new FolderItem(initRootFolder)
		  
		  for i as Integer = 0 to path.LastIndex  // let's build the target folder, one level at a time
		    folder = folder.Child(path(i))
		    
		    if IsNull(folder) then
		      WorkerThread.SocketRef.RespondInError(422) // unprocessable entity
		      Return
		    else
		      if not folder.Exists then
		        WorkerThread.SocketRef.RespondInError(422) // unprocessable entity
		        Return
		      elseif not folder.IsFolder then
		        WorkerThread.SocketRef.RespondInError(422) // unprocessable entity
		        Return
		      end if
		    end if
		    
		  next i
		  
		  file = new FolderItem(folder.Child(filename))
		  
		  if file.IsFolder then
		    WorkerThread.SocketRef.RespondInError(422 , "Alleged file is actually an existing folder") // unprocessable entity
		    Return
		  end if
		  
		  // ========== setup complete: we know what folderitem we are referring to now ===========
		  
		  select case verb
		  case "POST" , "PUT"  // uploads a file: post fails if file exists, put overwrites the file
		    POST_PUT(verb)
		  case "GET"  // download a file
		    GET
		  case "DELETE"  // deletes the file
		    DELETE
		  case "RENAME"  // non-standard HTTP , requires url parameter newname
		    RENAME
		  else
		    WorkerThread.SocketRef.RespondInError(501)  // not implemented
		  end select
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DELETE()
		  fileError = DeleteFSobject(file)
		  
		  if fileError = 0 then
		    WorkerThread.SocketRef.RespondOK
		  else
		    WorkerThread.SocketRef.RespondInError(422 , "Error deleting file, code " + fileError.ToString)
		  end if
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function DeleteFSobject(fsobject as FolderItem) As integer
		  // returns OS IO error code, 0 is success
		  try
		    fsobject.Remove
		  Catch e as NilObjectException
		    Return -1
		  Catch ee as IOException
		    Return ee.ErrorNumber
		  end try
		  
		  Return 0
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub GET()
		  if not file.Exists then
		    WorkerThread.SocketRef.RespondInError(404) // not found
		    Return
		  end if
		  
		  dim Readable as Boolean = false  // it's not guaranteed that a file is readable until we actually read from it
		  dim FileSize as Integer = file.Length
		  dim chunk as String
		  dim n as Integer = 4  // multiplier of default chunk size to read from file->write to socket
		  
		  try
		    
		    stream = BinaryStream.Open(file)
		    Readable = true // it is readable
		    
		    WorkerThread.SocketRef.PrepareResponseHeaders_SendBinaryFile(FileSize , file.Name)
		    WorkerThread.SocketRef.RespondOK(true)
		    
		    while not stream.EndOfFile
		      
		      chunk = stream.Read(ipsc_Lib.SocketChunkSize * n)  // adjust n to taste
		      WorkerThread.YieldToNext
		      
		      if not WorkerThread.SocketRef.IsConnected then exit while  // freezes on connection drops without it, in this exact place
		      WorkerThread.SocketRef.Write(chunk)
		      WorkerThread.BytesSent = WorkerThread.BytesSent + chunk.Bytes
		      
		      WorkerThread.SocketRef.Flush  // without this, it is all one big data packet
		      
		      WorkerThread.YieldToNext
		      
		    wend
		    
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
		  
		  stream.Close
		  
		  // make sure the last packet has been sent
		  while WorkerThread.SocketRef.IsConnected and WorkerThread.SocketRef.BytesLeftToSend > 0
		    WorkerThread.YieldToNext
		  wend
		  
		  // close the socket here, closing it on the socket's last SendComplete has caused some mis-timings
		  WorkerThread.SocketRef.Disconnect
		  WorkerThread.SocketRef.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub POST_PUT(verb as string)
		  dim overwrite as Boolean = False
		  
		  if verb = "POST" then
		    if file.Exists then
		      WorkerThread.SocketRef.RespondInError(409 , "File already exists") // conflict
		      Return
		    end if
		  else // put
		    overwrite = true
		  end if
		  
		  try
		    
		    stream = BinaryStream.Create(file , overwrite)
		    
		    while WorkerThread.BytesReceived < WorkerThread.SocketRef.RequestContentLength
		      
		      if WorkerThread.GetReceiveBufferChunks > 0 then
		        
		        stream.Write(WorkerThread.ReceiveBuffer(0))
		        WorkerThread.BytesReceived = WorkerThread.BytesReceived + WorkerThread.ReceiveBuffer(0).Bytes
		        WorkerThread.ReceiveBuffer.RemoveAt(0)
		        lastTX = DateTime.Now
		        
		      end if
		      
		      // receive timeout check
		      if DateTime.Now.SecondsFrom1970 - lastTX.SecondsFrom1970 > ipsc_Lib.TimeoutOnReceive then // transfer has timed out
		        stream.Close
		        fileError = DeleteFSobject(file)
		        if fileError <> 0 then
		          DebugMsg("POST/PUT: Error deleting file after IO error: " + fileError.ToString , CurrentMethodName , true)
		        end if
		        WorkerThread.SocketRef.RespondInError(408)  // Request Timeout 
		        Return
		      end if
		      
		      // no op
		      WorkerThread.YieldToNext
		      
		    wend
		    
		    stream.Flush
		    stream.Close
		    
		    WorkerThread.SocketRef.PrepareResponseHeaders_ReceivedData
		    WorkerThread.SocketRef.RespondOK(false)
		    
		  Catch e as IOException
		    stream.Close
		    
		    fileError = DeleteFSobject(file)
		    if fileError <> 0 then
		      DebugMsg("POST: Error deleting file after IO error: " + fileError.ToString , CurrentMethodName , true)
		    end if
		    
		    WorkerThread.SocketRef.RespondInError(500 , "File IO Error: " + e.ErrorNumber.ToString) // internal server error
		  end try
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub RENAME()
		  if not WorkerThread.SocketRef.RequestParameters.HasKey("newname") then
		    WorkerThread.SocketRef.RespondInError(400 , "newname URL parameter missing")
		    Return
		  end if
		  
		  dim newFilename as String = WorkerThread.SocketRef.RequestParameters.Value("newname").StringValue
		  dim oldFilename as String = file.Name
		  
		  if not file.Exists then
		    WorkerThread.SocketRef.RespondInError(404 , "File not found") // not found
		    Return
		  end if
		  
		  try
		    
		    file.Name = newFilename
		    
		    WorkerThread.SocketRef.RespondOK
		    
		  Catch e as IOException
		    WorkerThread.SocketRef.RespondInError(403 , "Error renaming """ + oldFilename + """ to """ + newFilename + """ , error code " + e.ErrorNumber.ToString)
		  end try
		  
		  
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private file As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h21
		Private FileError As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private folder As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h21
		Private lastTX As DateTime
	#tag EndProperty

	#tag Property, Flags = &h21
		Private stream As BinaryStream
	#tag EndProperty

	#tag Property, Flags = &h21
		Private WorkerThread As ipsc_ConnectionThread
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
