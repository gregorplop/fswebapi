#tag Class
Protected Class ipsc_Connection
Inherits SSLSocket
	#tag Event
		Sub Connected()
		  DebugMsg("ipsc_connection: new connection - handle = " + Handle.ToString , CurrentMethodName , true)
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub DataAvailable()
		  DebugMsg("connection " + Handle.ToString + " - bytes = " + BytesAvailable.ToString , CurrentMethodName , true)
		  
		  if Lookahead.Bytes = 0 and SSLConnected then // empty data block, more data is needed for decryption
		    StagnantIncomingData = true // according to the SSLSocket documentation
		    Return
		  else
		    StagnantIncomingData = false
		  end if
		  
		  DataAvailableEventsFired = DataAvailableEventsFired + 1
		  DataAvailableLastFired = System.Microseconds
		  
		  dim RecognizeErrorMsg as string
		  
		  if DataAvailableEventsFired = 1 then  // first part of the request: header is here
		    RequestRaw = Read(Lookahead.IndexOf(EndOfLine.Windows + EndOfLine.Windows) + 4).Trim
		    
		    if not RecognizeRequest then  // invalid request, according to the rules implemented in RecognizeRequest
		      
		      RespondInError(400)
		      
		    else // request is valid, create the worker thread
		      
		      ServerRef.Workers.Value(Handle) = new ipsc_ConnectionThread(self)
		      GetWorker.Start
		      
		    end if
		    
		  end if
		  
		  // worker thread should have been created, move data from connection receive buffer to worker buffer
		  
		  try
		    
		    if BytesAvailable > 0  then  
		      GetWorker.ReceiveBuffer.Append(Read(BytesAvailable))  // move incoming data to worker's receive buffer
		    end if
		    
		  Catch e as NilObjectException // worker is not there anymore--nowhere to send data
		    RespondInError(500 , "Worker thread has been terminated")
		  end try
		  
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub Error(err As RuntimeException)
		  DebugMsg("connection " + Handle.ToString + " - code = " + err.ErrorNumber.ToString + " message = " + err.Message, CurrentMethodName , true)
		  
		  select case err.ErrorNumber
		  case 102  // connection lost. might be an error or a completed request
		    // not implemented
		  else
		    // not implemented
		  end select
		  
		  close  // this has proven necessary here, prevents freeze on dropped connection while GET:/files/
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub SendComplete(UserAborted As Boolean)
		  DebugMsg("connection " + Handle.ToString + " - UserAborted = " + UserAborted.ToString, CurrentMethodName , true)
		  
		  if LastDataPacket2Send then
		    
		    if not IsNull(GetWorker) then  // avoid nilobjectexception when sending a lot of text data in the reply
		      if GetWorker.ThreadState = Thread.ThreadStates.NotRunning then
		        ServerRef.Workers.Remove(Handle)
		      Else  // thread might be still running for some reason
		        GetWorker.Kill = true // hope the application code will honor the kill request
		      end if
		    end if
		    
		    if not SSLEnabled then // ssl has its own timing for closing the connection
		      Disconnect
		      close
		    end if
		    
		  end if
		  
		  
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h21
		Private Sub Constructor()
		  // Calling the overridden superclass constructor.
		  // Note that this may need modifications if there are multiple constructor choices.
		  // Possible constructor calls:
		  // Constructor() -- From TCPSocket
		  // Constructor() -- From SocketCore
		  Super.Constructor
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(byref initServerRef as ipsc_Server)
		  // Calling the overridden superclass constructor.
		  // Note that this may need modifications if there are multiple constructor choices.
		  // Possible constructor calls:
		  // Constructor() -- From TCPSocket
		  // Constructor() -- From SocketCore
		  Super.Constructor
		  
		  ServerRef = initServerRef
		  RequestHeaders = new Dictionary
		  ResponseHeaders = new Dictionary
		  RequestParameters = new Dictionary
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetWorker() As ipsc_ConnectionThread
		  try
		    return ipsc_ConnectionThread(ServerRef.Workers.Value(Handle))
		  Catch e as KeyNotFoundException
		    DebugMsg("worker " + Handle.ToString + " already removed" , CurrentMethodName , true)
		    Return nil
		  end try
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub PrepareResponseHeaders_ReceivedData()
		  // prepares default headers for replying to have received data
		  
		  ResponseHeaders = new Dictionary
		  
		  ResponseHeaders.Value("Date") = ipsc_Lib.DateToRFC1123(nil)
		  ResponseHeaders.Value("Server") = "ipscservercore/" + ipsc_Lib.Version
		  ResponseHeaders.Value("Connection") = "close"
		  ResponseHeaders.Value("Cache-Control") = "no-store"
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub PrepareResponseHeaders_SendBinaryFile(ByteSize as Integer, Filename as string)
		  // prepares default headers for sending a binary file
		  
		  ResponseHeaders = new Dictionary
		  
		  ResponseHeaders.Value("Date") = ipsc_Lib.DateToRFC1123(nil)
		  ResponseHeaders.Value("Server") = "ipscservercore/" + ipsc_Lib.Version
		  ResponseHeaders.Value("Connection") = "close"
		  ResponseHeaders.Value("Content-Length") = ByteSize
		  ResponseHeaders.Value("Content-Type") = "application/octet-stream"
		  ResponseHeaders.Value("Content-Disposition") = "attachment; filename=""" + Filename + """"
		  ResponseHeaders.Value("Cache-Control") = "no-store"
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub PrepareResponseHeaders_SendTextReply(ByteSize as Integer)
		  // prepares default headers for sending a binary file
		  
		  ResponseHeaders = new Dictionary
		  
		  ResponseHeaders.Value("Date") = ipsc_Lib.DateToRFC1123(nil)
		  ResponseHeaders.Value("Server") = "ipscservercore/" + ipsc_Lib.Version
		  ResponseHeaders.Value("Connection") = "close"
		  ResponseHeaders.Value("Content-Length") = ByteSize
		  ResponseHeaders.Value("Content-Type") = "text/plain"
		  ResponseHeaders.Value("Cache-Control") = "no-store"
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function RecognizeRequest() As Boolean
		  // takes RequestRaw and tries to fill:
		  // RequestVerb , RequestPath , RequestProtocol , RequestContentLength
		  // if malformed request then returns false
		  // if all ok then returns true
		  
		  dim headerLines(-1) as String = RequestRaw.Split(EndOfLine.Windows)
		  
		  if headerLines(0).CountFields(" ") <> 3 then Return false
		  
		  RequestVerb = headerLines(0).NthField(" " , 1)
		  RequestPath = headerLines(0).NthField(" " , 2)
		  RequestProtocol = headerLines(0).NthField(" " , 3)
		  
		  if RequestPath.IndexOf("?") >= 0 then  // as it is, you cannot have more than a ? in the URL
		    dim parameters(-1) as String = RequestPath.NthField("?" , 2).Split("&")
		    for i as Integer = 0 to Parameters.LastIndex
		      RequestParameters.Value(parameters(i).NthField("=" , 1).Lowercase) = parameters(i).NthField("=" , 2)
		    next i
		    RequestPath = RequestPath.NthField("?" , 1)
		  end if
		  
		  if RequestProtocol <> "HTTP/1.1" then Return False
		  
		  if RequestPath = "/" then RequestPath = "" // just for the aesthetics of it
		  
		  for i as Integer = 1 to headerLines.LastIndex
		    RequestHeaders.Value(headerLines(i).NthField(":" , 1)) = headerLines(i).NthField(":" , 2).Trim
		  next i
		  
		  if RequestHeaders.HasKey("Content-Length") then
		    RequestContentLength = RequestHeaders.Value("Content-Length").IntegerValue
		  else
		    RequestContentLength = 0
		  end if
		  
		  if RequestContentLength = 0 and BytesAvailable > 0 then Return false
		  
		  Return true
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RespondInError(ErrorCode as integer, optional TextContent as String = "")
		  dim response as String = "HTTP/1.1 " + ErrorCode.ToString + " " + ipsc_Lib.HTTP_ErrorMessage(ErrorCode) + EndOfLine.Windows
		  
		  response = response + "Date: " + ipsc_Lib.DateToRFC1123(nil) + EndOfLine.Windows // now
		  Response = response + "Server: ipscservercore/" + ipsc_Lib.Version + EndOfLine.Windows
		  response = response + "Connection: close" + EndOfLine.Windows
		  
		  if TextContent <> "" then
		    response = response + "Content-Type: text/plain" + EndOfLine.Windows
		    response = response + "Content-Length: " + TextContent.Bytes.ToString + EndOfLine.Windows
		  end if
		  
		  response = response + EndOfLine.Windows
		  
		  if TextContent <> "" then
		    response = response + TextContent
		  end if
		  
		  LastDataPacket2Send = true
		  
		  Write(response)
		  Flush
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RespondOK(ContentFollows as Boolean)
		  // requires the appropriate ResponseHeaders 
		  if ResponseHeaders.KeyCount = 0 then
		    Raise new RuntimeException("Tried to respond OK without any response headers set!" , 99)
		    Return
		  end if
		  
		  dim response as String = "HTTP/1.1 200 OK" + EndOfLine.Windows
		  
		  for i as Integer = 0 to ResponseHeaders.KeyCount - 1
		    response = response + ResponseHeaders.Key(i).StringValue + ": " + ResponseHeaders.Value(ResponseHeaders.Key(i).StringValue).StringValue + EndOfLine.Windows
		  next i
		  
		  response = response + EndOfLine.Windows
		  
		  LastDataPacket2Send = not ContentFollows
		  
		  Write(response)
		  
		  if LastDataPacket2Send then Flush
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RespondOK(optional TextContent as string = "")
		  dim response as String = "HTTP/1.1 200 OK" + EndOfLine.Windows
		  
		  response = response + "Date: " + ipsc_Lib.DateToRFC1123(nil) + EndOfLine.Windows // now
		  Response = response + "Server: ipscservercore/" + ipsc_Lib.Version + EndOfLine.Windows
		  response = response + "Connection: close" + EndOfLine.Windows
		  
		  if TextContent <> "" then
		    response = response + "Content-Type: text/plain" + EndOfLine.Windows
		    response = response + "Content-Length: " + TextContent.Bytes.ToString + EndOfLine.Windows
		  end if
		  
		  response = response + EndOfLine.Windows
		  
		  if TextContent <> "" then
		    response = response + TextContent
		  end if
		  
		  LastDataPacket2Send = true
		  
		  Write(response)
		  Flush
		  
		  
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private DataAvailableEventsFired As Integer = 0
	#tag EndProperty

	#tag Property, Flags = &h21
		#tag Note
			System.Microseconds
		#tag EndNote
		Private DataAvailableLastFired As integer = 0
	#tag EndProperty

	#tag Property, Flags = &h0
		#tag Note
			Signal to close the connection after last send
		#tag EndNote
		LastDataPacket2Send As Boolean = false
	#tag EndProperty

	#tag Property, Flags = &h0
		#tag Note
			This is also in RequestHeaders but it's important, so also resides on its own
		#tag EndNote
		RequestContentLength As integer
	#tag EndProperty

	#tag Property, Flags = &h0
		RequestHeaders As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h0
		RequestParameters As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h0
		RequestPath As String
	#tag EndProperty

	#tag Property, Flags = &h0
		RequestPathArray() As string
	#tag EndProperty

	#tag Property, Flags = &h0
		RequestProtocol As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private RequestRaw As String
	#tag EndProperty

	#tag Property, Flags = &h0
		RequestVerb As String
	#tag EndProperty

	#tag Property, Flags = &h0
		ResponseHeaders As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h0
		ServerRef As ipsc_Server
	#tag EndProperty

	#tag Property, Flags = &h0
		StagnantIncomingData As Boolean = false
	#tag EndProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="Address"
			Visible=true
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Port"
			Visible=true
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
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
			Name="SSLConnectionType"
			Visible=true
			Group="Behavior"
			InitialValue="3"
			Type="SSLConnectionTypes"
			EditorType="Enum"
			#tag EnumValues
				"1 - SSLv23"
				"3 - TLSv1"
				"4 - TLSv11"
				"5 - TLSv12"
			#tag EndEnumValues
		#tag EndViewProperty
		#tag ViewProperty
			Name="CertificatePassword"
			Visible=true
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="SSLEnabled"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="SSLConnected"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="SSLConnecting"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="BytesAvailable"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="BytesLeftToSend"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="LastErrorCode"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="LastDataPacket2Send"
			Visible=false
			Group="Behavior"
			InitialValue="false"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="RequestContentLength"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="RequestPath"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="RequestProtocol"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="RequestVerb"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="StagnantIncomingData"
			Visible=false
			Group="Behavior"
			InitialValue="false"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
