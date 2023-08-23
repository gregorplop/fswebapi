#tag Module
Protected Module ipservercore
	#tag Method, Flags = &h1, CompatibilityFlags = (TargetConsole and (Target32Bit or Target64Bit)) or  (TargetWeb and (Target32Bit or Target64Bit)) or  (TargetDesktop and (Target32Bit or Target64Bit)) or  (TargetIOS and (Target64Bit))
		Protected Function DateToRFC1123(TheDate As DateTime = Nil) As Text
		  // Returns a  in RFC 822 / 1123 format.
		  // Example: Mon, 27 Nov 2017 13:27:26 GMT
		  // Special thanks to Norman Palardy.
		  // See: https://forum.xojo.com/42908-current-date-time-stamp-in-rfc-822-1123-format
		  
		  Dim tmp As Text
		  
		  If TheDate = Nil Then
		    Dim GMTTZ As New TimeZone( 0 )
		    TheDate = New DateTime( DateTime.Now.SecondsFrom1970, GMTTZ )
		  End If
		  
		  Select Case TheDate.DayOfWeek
		  Case 1
		    tmp = tmp + "Sun"
		  Case 2
		    tmp = tmp + "Mon"
		  Case 3
		    tmp = tmp + "Tue"
		  Case 4
		    tmp = tmp + "Wed"
		  Case 5
		    tmp = tmp + "Thu"
		  Case 6
		    tmp = tmp + "Fri"
		  Case 7
		    tmp = tmp + "Sat"
		  End Select
		  
		  tmp = tmp + ", "
		  
		  tmp = tmp + If(TheDate.Day < 10, "0", "" ) + TheDate.Day.ToText
		  
		  tmp = tmp + " "
		  
		  Select Case TheDate.Month
		  Case 1
		    tmp = tmp + "Jan" 
		  Case 2
		    tmp = tmp + "Feb" 
		  Case 3
		    tmp = tmp + "Mar"
		  Case 4
		    tmp = tmp + "Apr"
		  Case 5
		    tmp = tmp + "May" 
		  Case 6
		    tmp = tmp + "Jun" 
		  Case 7
		    tmp = tmp + "Jul" 
		  Case 8
		    tmp = tmp + "Aug"
		  Case 9
		    tmp = tmp + "Sep" 
		  Case 10
		    tmp = tmp + "Oct"
		  Case 11
		    tmp = tmp + "Nov" 
		  Case 12
		    tmp = tmp + "Dec"
		  End Select
		  
		  tmp = tmp + " "
		  
		  tmp = tmp + TheDate.Year.ToText
		  tmp = tmp + " "
		  
		  tmp = tmp + If(TheDate.Hour < 10, "0", "" ) + TheDate.Hour.ToText
		  tmp = tmp + ":"
		  
		  tmp = tmp + If(TheDate.Minute < 10, "0", "" ) + TheDate.Minute.ToText
		  tmp = tmp + ":"
		  
		  tmp = tmp + If(TheDate.Second < 10, "0", "" ) + TheDate.Second.ToText
		  tmp = tmp + " "
		  
		  tmp = tmp + "GMT"
		  
		  Return tmp
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DebugMsg(Message as string, CallingMethod as string, PrintMsg as Boolean = false)
		  if Debug then
		    dim intMilliseconds as Integer = System.Microseconds / 1000
		    dim msg as String = CallingMethod + " : " + intMilliseconds.ToString + " : " + Message
		    System.DebugLog(msg)
		    if PrintMsg then Print msg
		  end if
		  
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function HTTP_ErrorMessage(ErrorCode as integer) As String
		  select case ErrorCode
		  case 100
		    return "Continue"
		  case 101
		    return "Switching Protocols"
		  case 102
		    return "Processing"
		  case 200
		    return "OK"
		  case 201
		    return "Created"
		  case 202
		    return "Accepted"
		  case 203
		    return "Non-authoritative Information"
		  case 204
		    return "No Content"
		  case 205
		    return "Reset Content"
		  case 206
		    return "Partial Content"
		  case 207
		    return "Multi-Status"
		  case 208
		    return "Already Reported"
		  case 226
		    return "IM Used"
		  case 300
		    return "Multiple Choices"
		  case 301
		    return "Moved Permanently"
		  case 302
		    return "Found"
		  case 303
		    return "See Other"
		  case 304
		    return "Not Modified"
		  case 305
		    return "Use Proxy"
		  case 307
		    return "Temporary Redirect"
		  case 308
		    return "Permanent Redirect"
		  case 400
		    return "Bad Request"
		  case 401
		    return "Unauthorized"
		  case 402
		    return "Payment Required"
		  case 403
		    return "Forbidden"
		  case 404
		    return "Not Found"
		  case 405
		    return "Method Not Allowed"
		  case 406
		    return "Not Acceptable"
		  case 407
		    return "Proxy Authentication Required"
		  case 408
		    return "Request Timeout"
		  case 409
		    return "Conflict"
		  case 410
		    return "Gone"
		  case 411
		    return "Length Required"
		  case 412
		    return "Precondition Failed"
		  case 413
		    return "Payload Too Large"
		  case 414
		    return "Request-URI Too Long"
		  case 415
		    return "Unsupported Media Type"
		  case 416
		    return "Requested Range Not Satisfiable"
		  case 417
		    return "Expectation Failed"
		  case 418
		    return "I'm a teapot"
		  case 421
		    return "Misdirected Request"
		  case 422
		    return "Unprocessable Entity"
		  case 423
		    return "Locked"
		  case 424
		    return "Failed Dependency"
		  case 426
		    return "Upgrade Required"
		  case 428
		    return "Precondition Required"
		  case 429
		    return "Too Many Requests"
		  case 431
		    return "Request Header Fields Too Large"
		  case 444
		    return "Connection Closed Without Response"
		  case 451
		    return "Unavailable For Legal Reasons"
		  case 499
		    return "Client Closed Request"
		  case 500
		    return "Internal Server Error"
		  case 501
		    return "Not Implemented"
		  case 502
		    return "Bad Gateway"
		  case 503
		    return "Service Unavailable"
		  case 504
		    return "Gateway Timeout"
		  case 505
		    return "HTTP Version Not Supported"
		  case 506
		    return "Variant Also Negotiates"
		  case 507
		    return "Insufficient Storage"
		  case 508
		    return "Loop Detected"
		  case 510
		    return "Not Extended"
		  case 511
		    return "Network Authentication Required"
		  case 599
		    return "Network Connect Timeout Error"
		  else
		    Return "Invalid Error Code"
		  end select
		  
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function SSLModeString(mode as SSLSocket.SSLConnectionTypes) As string
		  select case mode
		  case SSLSocket.SSLConnectionTypes.SSLv23
		    Return "SSLv23"
		  case SSLSocket.SSLConnectionTypes.TLSv1
		    Return "TLSv1.0"
		  case SSLSocket.SSLConnectionTypes.TLSv11
		    Return "TLSv1.1"
		  case SSLSocket.SSLConnectionTypes.TLSv12
		    Return "TLSv1.2"
		  else
		    Return "Invalid"
		  end select
		  
		End Function
	#tag EndMethod


	#tag Property, Flags = &h1
		Protected Debug As Boolean = false
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected TimeoutOnReceive As Integer = 60
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected TimeoutOnSend As Integer = 60
	#tag EndProperty


	#tag Constant, Name = SocketChunkSize, Type = Double, Dynamic = False, Default = \"1048576", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Version, Type = String, Dynamic = False, Default = \"1.5", Scope = Protected
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
End Module
#tag EndModule
