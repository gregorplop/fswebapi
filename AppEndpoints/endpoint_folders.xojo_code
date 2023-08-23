#tag Class
Protected Class endpoint_folders
	#tag Method, Flags = &h21
		Private Sub Constructor()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(byref initWorkerThread as ipservercore.ipscConnectionThread, initRootFolder as FolderItem)
		  // Instantiated objects are not supposed to be reused
		  
		  WorkerThread = initWorkerThread
		  
		  WorkerThread.BytesReceived = 0
		  WorkerThread.BytesSent = 0
		  
		  // internal copies to keep code more readable
		  RqVerb = WorkerThread.SocketRef.RequestVerb.Uppercase
		  RqPath = WorkerThread.SocketRef.RequestPathArray
		  RqParams = WorkerThread.SocketRef.RequestParameters
		  folder = new FolderItem(initRootFolder) // start with the root folder
		  
		  
		  select case RqVerb // route request
		    
		  case "POST" // creates the folder if not exist
		    POST
		  case "LIST"  // non-standard HTTP , gets folder contents
		    LIST
		  case "DELETE"  // deletes the folder
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
		  dim deletemode as string = "simple" // default is "simple"
		  dim allowedDeletemodes() as String = Array("simple" , "recursive" , "clear")
		  
		  // modes are:
		  // simple = deletes the folder IF it is empty. this is the default.
		  // recursive = deletes the folder and its entire contents, including subfolders
		  // clear = deletes the contents of the folder but keeps the folder itself
		  //
		  // note: you cannot do a simple or recursive delete on the base folder
		  
		  if RqParams.HasKey("deletemode") then
		    
		    if RqParams.KeyCount <> 1 then // if has deletemode then it has to be the only parameter
		      WorkerThread.SocketRef.RespondInError(400 , "URL contains invalid parameters")
		      Return
		    end if
		    
		    if allowedDeletemodes.IndexOf(RqParams.Value("deletemode").StringValue.Lowercase.Trim) < 0 then
		      WorkerThread.SocketRef.RespondInError(400 , "deletemode parameter is invalid")
		      Return
		    end if
		    
		    deletemode = RqParams.Value("deletemode").StringValue.Lowercase.Trim
		    
		  end if
		  
		  dim rootfolder as FolderItem = new FolderItem(folder) // save the root folder, to compare to the resulting base folder
		  
		  // complete path has to exist, let's build it
		  
		  for i as Integer = 1 to RqPath.LastIndex
		    
		    folder = folder.Child(RqPath(i) , false) // do not follow aliases for security reasons
		    
		    if IsNull(folder) then 
		      WorkerThread.SocketRef.RespondInError(422 , "Invalid path") // unprocessable entity
		      Return
		    end if
		    
		    if not folder.Exists then 
		      WorkerThread.SocketRef.RespondInError(422 , "Folder does not exist") // unprocessable entity
		      Return
		    else
		      if not folder.IsFolder then
		        WorkerThread.SocketRef.RespondInError(422 , "Path points to file") // unprocessable entity
		        Return
		      end if
		    end if
		    
		  next i 
		  
		  if folder.NativePath = rootfolder.NativePath and (deletemode = "simple" or deletemode = "recursive") then
		    WorkerThread.SocketRef.RespondInError(422 , "Cannot delete base folder") // unprocessable entity
		    Return
		  end if
		  
		  // we have the final folderitem for the folder
		  
		  dim fsobjects() as FolderItem
		  
		  if deletemode = "simple" then 
		    
		    fsobjects.Add folder
		    
		  ElseIf deletemode = "recursive" or deletemode = "clear" then
		    
		    try
		      infoplastique.ScanFolderItems(folder , fsobjects , true)
		    Catch ioe as IOException
		      WorkerThread.SocketRef.RespondInError(422 , "Error scanning folder tree: " + ioe.Message)
		      Return
		    Catch noe as NilObjectException
		      WorkerThread.SocketRef.RespondInError(422 , "Error scanning folder tree: " + noe.Message)
		      Return
		    end try
		    
		    if deletemode = "clear" then fsobjects.RemoveAt(0) // remove starting folder from remove-list
		    
		  end if
		  
		  
		  dim FileErrorCode as Integer = infoplastique.DeleteFSitems(fsobjects) // delete stuff
		  
		  if FileErrorCode = 0 then
		    WorkerThread.SocketRef.RespondOK
		  else
		    WorkerThread.SocketRef.RespondInError(422 , "Error deleting << " + fsobjects(fsobjects.LastIndex).NativePath + " >>, code " + FileErrorCode.ToString)
		  end if
		  
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub LIST()
		  // returns a tab-delimited list of files with the following fields
		  // 1=filename , 2=fs object type{file,dir,alias} , 3=size(only for files) , 4=creation timestamp , 5=modification timestamp
		  
		  if RqParams.KeyCount > 0 then 
		    WorkerThread.SocketRef.RespondInError(400 , "No parameters allowed")
		    Return
		  end if
		  
		  
		  for i as Integer = 1 to RqPath.LastIndex
		    
		    folder = folder.Child(RqPath(i) , false) // do not follow aliases for security reasons
		    
		    if IsNull(folder) then 
		      WorkerThread.SocketRef.RespondInError(422 , "Invalid path") // unprocessable entity
		      Return
		    end if
		    
		    if not folder.Exists then 
		      WorkerThread.SocketRef.RespondInError(422 , "Folder does not exist") // unprocessable entity
		      Return
		    else
		      if not folder.IsFolder then
		        WorkerThread.SocketRef.RespondInError(422 , "Path points to file") // unprocessable entity
		        Return
		      end if
		    end if
		    
		  next i 
		  
		  // we have the folder
		  
		  dim ContentsList as String
		  
		  if not infoplastique.ListFolderContents(folder , ContentsList) then
		    WorkerThread.SocketRef.RespondInError(422 , "Error building contents list") // unprocessable entity
		    Return
		  end if
		  
		  
		  WorkerThread.SocketRef.PrepareResponseHeaders_SendTextReply(ContentsList.Bytes)
		  WorkerThread.SocketRef.RespondOK(true)
		  WorkerThread.SocketRef.Write(ContentsList)
		  //WorkerThread.SocketRef.LastDataPacket2Send = true
		  
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub POST()
		  if RqParams.KeyCount > 0 then 
		    WorkerThread.SocketRef.RespondInError(400 , "No parameters allowed")
		    Return
		  end if
		  
		  dim created(-1) as FolderItem
		  
		  for i as Integer = 1 to RqPath.LastIndex
		    
		    folder = folder.Child(RqPath(i) , false) // do not follow aliases for security reasons
		    
		    
		    if IsNull(folder) then 
		      WorkerThread.SocketRef.RespondInError(422 , "Invalid path") // unprocessable entity
		      Return
		    end if
		    
		    
		    if not folder.Exists then 
		      try
		        folder.CreateFolder
		        created.Add new FolderItem(folder)
		      Catch e as IOException
		        call infoplastique.DeleteFSitems(created) // try to cleanup, fail silently if unable
		        WorkerThread.SocketRef.RespondInError(422 , "Error creating folder, error " + e.ErrorNumber.ToString) // unprocessable entity
		        Return
		      end try
		      
		    else
		      
		      if not folder.IsFolder then
		        WorkerThread.SocketRef.RespondInError(422 , "Path points to file") // unprocessable entity
		        Return
		      end if
		      
		    end if
		    
		  next i 
		  
		  
		  WorkerThread.SocketRef.RespondOK
		  
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
		  
		  // complete path has to exist, let's build it
		  
		  for i as Integer = 1 to RqPath.LastIndex
		    
		    folder = folder.Child(RqPath(i) , false) // do not follow aliases for security reasons
		    
		    if IsNull(folder) then 
		      WorkerThread.SocketRef.RespondInError(422 , "Invalid path") // unprocessable entity
		      Return
		    end if
		    
		    if not folder.Exists then 
		      WorkerThread.SocketRef.RespondInError(422 , "Folder does not exist") // unprocessable entity
		      Return
		    else
		      if not folder.IsFolder then
		        WorkerThread.SocketRef.RespondInError(422 , "Path points to file") // unprocessable entity
		        Return
		      end if
		    end if
		    
		  next i 
		  
		  // we have the final folderitem to rename
		  
		  dim newFoldername as String = RqParams.Value("newname").StringValue.Trim
		  dim oldFoldername as String = folder.Name
		  
		  try
		    
		    folder.Name = newFoldername
		    
		    WorkerThread.SocketRef.RespondOK
		    
		  Catch e as IOException
		    WorkerThread.SocketRef.RespondInError(403 , "Error renaming """ + oldFoldername + """ to """ + newFoldername + """ , error code " + e.ErrorNumber.ToString)
		  end try
		  
		  
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private folder As FolderItem
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
