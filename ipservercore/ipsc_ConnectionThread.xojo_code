#tag Class
Protected Class ipsc_ConnectionThread
Inherits Thread
	#tag Event
		Sub Run()
		  Fired = true  // for use by thread trash collector
		  DebugMsg("started for connection " + SocketRef.Handle.ToString , CurrentMethodName , true)
		  
		  // do what you want from this point on. everything you call runs on this thread
		  // usually you'd want to route the request first
		  
		  
		  // the following block is for testing different strategies mentioned in
		  // https://forum.xojo.com/t/multiple-sslsocket-i-o-in-threads-the-slowest-connection-universally-sets-the-pace-for-all-connections/64891
		  // you can just remove it and go on with app.RouteRequest(self)
		  
		  dim endpoint as String = SocketRef.RequestPath.NthField("/" , 2).Lowercase
		  
		  if endpoint.Left(14) = "file-get-tests" then
		    
		    dim file as new FolderItem("c:\shared\2G.zip" , FolderItem.PathModes.Native)
		    dim stream as BinaryStream
		    dim n as Integer = 4
		    
		    if IsNull(file) then 
		      SocketRef.RespondInError(422)
		      Return
		    ElseIf not IsNull(file) and not file.Exists then
		      SocketRef.RespondInError(422)
		      Return
		    end if
		    
		    stream = BinaryStream.Open(file)
		    
		    // ========================
		    
		    SocketRef.PrepareResponseHeaders_SendBinaryFile(file.Length , file.Name)
		    SocketRef.RespondOK(true)
		    
		    while not stream.EndOfFile
		      
		      Socketref.write(stream.read(ipsc_Lib.SocketChunkSize * n))  // n=4
		      
		      if endpoint.IndexOf("flush") > 0 then
		        SocketRef.Flush
		      end if
		      
		      Self.sleep(10)
		      
		    wend
		    
		    stream.Close
		    while SocketRef.IsConnected and SocketRef.BytesLeftToSend > 0
		      YieldToNext
		    wend
		    
		    SocketRef.Disconnect
		    SocketRef.Close
		    
		    
		  else
		    app.RouteRequest(self)
		  end if
		  
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h21
		Private Sub Constructor()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(byref socket as ipsc_Connection)
		  SocketRef = socket
		  Priority = 1  // adjust to taste, empirically lower for better concurrency
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetReceiveBufferChunks() As Integer
		  Return ReceiveBuffer.LastIndex + 1
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetReceiveBufferSize() As Integer
		  dim TotalBytes as Integer = 0
		  
		  For Each chunk as string in ReceiveBuffer
		    TotalBytes = TotalBytes + chunk.Bytes 
		  next
		  
		  Return TotalBytes
		  
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		BytesReceived As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		BytesSent As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		#tag Note
			Flag to indicate that the thread has run.
		#tag EndNote
		Fired As Boolean = false
	#tag EndProperty

	#tag Property, Flags = &h0
		Kill As Boolean = false
	#tag EndProperty

	#tag Property, Flags = &h0
		ReceiveBuffer(-1) As string
	#tag EndProperty

	#tag Property, Flags = &h0
		SocketRef As ipsc_Connection
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
			InitialValue=""
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
			Name="Priority"
			Visible=true
			Group="Behavior"
			InitialValue="5"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="StackSize"
			Visible=true
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Kill"
			Visible=false
			Group="Behavior"
			InitialValue="false"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="BytesSent"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="BytesReceived"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Fired"
			Visible=false
			Group="Behavior"
			InitialValue="false"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
