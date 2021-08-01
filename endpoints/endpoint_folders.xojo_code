#tag Class
Protected Class endpoint_folders
	#tag Method, Flags = &h21
		Private Sub Constructor()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(byref initWorkerThread as ipsc_ConnectionThread, initRootFolder as FolderItem)
		  WorkerThread = initWorkerThread
		  
		  WorkerThread.BytesReceived = 0
		  WorkerThread.BytesSent = 0
		  
		  dim path() as String = WorkerThread.SocketRef.RequestPath.Split("/")
		  path.RemoveAt(0) // remove empty
		  path.RemoveAt(0) // remove /folders endpoint
		  
		  if path.LastIndex < 0 then  // it was just /folders
		    WorkerThread.SocketRef.RespondInError(422)  // unprocessable entity
		    Return
		  end if
		  
		  dim verb as string = WorkerThread.SocketRef.RequestVerb.Uppercase
		  
		  folder = new FolderItem(initRootFolder)
		  
		  for i as Integer = 0 to path.LastIndex - 1 // let's build the target folder, one level at a time
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
		  
		  folder = folder.Child(path(path.LastIndex))
		  
		  if folder.Exists then
		    if not folder.IsFolder then
		      WorkerThread.SocketRef.RespondInError(422 , "Alleged folder is actually an existing file") // unprocessable entity
		      Return
		    end if
		  end if
		  
		  // ========== setup complete: we know what folderitem we are referring to now ===========
		  
		  select case verb
		  case "POST" // creates the folder if not exist
		    POST
		  case "LIST"  // non-standard HTTP , gets folder contents
		    LIST
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
		  fileError = DeleteFSobject(folder)
		  
		  if fileError = 0 then
		    WorkerThread.SocketRef.PrepareResponseHeaders_MethodExecuted
		    WorkerThread.SocketRef.RespondOK(false)
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
		Private Sub LIST()
		  // returns a tab-delimited list of files with the following fields
		  // 1=filename , 2=fs object type{file,dir,alias} , 3=size(only for files) , 4=creation timestamp , 5=modification timestamp
		  
		  dim fsobjRecord(4) as String 
		  dim ListContent as String
		  dim tab as String = Chr(9)
		  dim objtype as string
		  dim fsobj as FolderItem
		  
		  if not folder.Exists then
		    WorkerThread.SocketRef.RespondInError(404 , "Folder does not exist")
		    Return
		  end if
		  
		  dim fsobjectCount as Integer = folder.Count
		  
		  if fsobjectCount = 0 then
		    WorkerThread.SocketRef.PrepareResponseHeaders_MethodExecuted
		    WorkerThread.SocketRef.RespondOK(false)
		    Return
		  end if
		  
		  try
		    
		    for i as Integer = 0 to fsobjectCount - 1
		      
		      fsobj = new FolderItem(folder.ChildAt(i , false))
		      
		      fsobjRecord(0) = fsobj.Name
		      
		      if fsobj.IsAlias then
		        fsobjRecord(1) = "alias"
		      ElseIf fsobj.IsFolder then
		        fsobjRecord(1) = "dir"
		      Else 
		        fsobjRecord(1) = "file"
		      end if
		      
		      fsobjRecord(2) = if(fsobjRecord(1) = "file" , fsobj.Length.ToString , "")
		      
		      fsobjRecord(3) = fsobj.CreationDateTime.SQLDateTime
		      fsobjRecord(4) = fsobj.ModificationDateTime.SQLDateTime
		      
		      ListContent = ListContent + String.FromArray(fsobjRecord , tab) + EndOfLine.Windows
		      
		    next i
		    
		  Catch e as IOException
		    WorkerThread.SocketRef.RespondInError(422 , "Error compiling file list, code " + e.ErrorNumber.ToString)
		    Return
		  Catch ee as NilObjectException
		    WorkerThread.SocketRef.RespondInError(422 , "Error compiling file list, FS object not accessible")
		    Return
		  end try
		  
		  WorkerThread.SocketRef.PrepareResponseHeaders_SendTextReply(ListContent.Bytes)
		  WorkerThread.SocketRef.RespondOK(true)
		  
		  WorkerThread.SocketRef.Write(ListContent)
		  WorkerThread.SocketRef.LastDataPacket2Send = true
		  
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub POST()
		  try
		    
		    folder.CreateFolder
		    
		    WorkerThread.SocketRef.PrepareResponseHeaders_MethodExecuted
		    WorkerThread.SocketRef.RespondOK(false)
		    
		  Catch e as IOException
		    
		    WorkerThread.SocketRef.RespondInError(422 , "Error when creating folder, code " + e.ErrorNumber.ToString) // unprocessable entity
		    
		  end try
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub RENAME()
		  if not WorkerThread.SocketRef.RequestParameters.HasKey("newname") then
		    WorkerThread.SocketRef.RespondInError(400 , "newname URL parameter missing")
		    Return
		  end if
		  
		  dim newFoldername as String = WorkerThread.SocketRef.RequestParameters.Value("newname").StringValue
		  dim oldFoldername as String = folder.Name
		  
		  if not folder.Exists then
		    WorkerThread.SocketRef.RespondInError(404 , "Folder not found") // not found
		    Return
		  end if
		  
		  try
		    
		    folder.Name = newFoldername
		    
		    WorkerThread.SocketRef.PrepareResponseHeaders_MethodExecuted
		    WorkerThread.SocketRef.RespondOK(false)
		    
		  Catch e as IOException
		    WorkerThread.SocketRef.RespondInError(403 , "Error renaming """ + oldFoldername + """ to """ + newFoldername + """ , error code " + e.ErrorNumber.ToString)
		  end try
		  
		  
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private FileError As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private folder As FolderItem
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
