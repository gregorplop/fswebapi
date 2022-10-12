#tag Class
Protected Class endpoint_introspection
	#tag Method, Flags = &h21
		Private Sub Constructor()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(byref initWorkerThread as ipsc_ConnectionThread)
		  WorkerThread = initWorkerThread
		  
		  dim path() as String = WorkerThread.SocketRef.RequestPath.Split("/")
		  path.RemoveAt(0) // remove empty
		  path.RemoveAt(0) // remove /introspection
		  
		  if path.LastIndex < 0 then   // url was /introspection
		    
		    WorkerThread.SocketRef.RespondOK(AvailableEndpoints)
		    
		  else
		    
		    select case path(0)
		      
		    case "" // url was /introspection/
		      
		      WorkerThread.SocketRef.RespondOK(AvailableEndpoints)
		      
		    case "opensockets"
		      
		      opensocketsGET
		      
		    else
		      WorkerThread.SocketRef.RespondInError(501)  // not implemented
		    end select
		    
		  end if
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub opensocketsGET()
		  if WorkerThread.SocketRef.RequestVerb <> "GET" then
		    WorkerThread.SocketRef.RespondInError(501)  // not implemented
		    Return
		  end if
		  
		  dim sockets() as TCPSocket = WorkerThread.SocketRef.ServerRef.ActiveConnections
		  dim SocketHandles as String = "Active socket handles at " + DateTime.Now.SQLDateTime + EndOfLine + EndOfLine
		  
		  for i as Integer = 0 to Sockets.Ubound
		    SocketHandles = SocketHandles + Sockets(i).Handle.ToString + if(sockets(i).Handle = WorkerThread.SocketRef.Handle , " (this request)" , "")
		    SocketHandles = SocketHandles + EndOfLine.Windows
		  next i
		  
		  WorkerThread.SocketRef.RespondOK(SocketHandles)
		  
		  
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private WorkerThread As ipsc_ConnectionThread
	#tag EndProperty


	#tag Constant, Name = AvailableEndpoints, Type = String, Dynamic = False, Default = \"Available endpoints:\r\n\r\n/introspection/opensockets\r\n", Scope = Public
	#tag EndConstant


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
