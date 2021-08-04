#tag Class
Protected Class ipsc_Server
Inherits ServerSocket
	#tag Event
		Function AddSocket() As TCPSocket
		  DebugMsg("new connection requested - open sockets: " + str(ActiveConnections.Ubound + 1) , CurrentMethodName , true)
		  
		  dim NewConnection as new ipsc_Connection(self)
		  
		  Return NewConnection
		  
		End Function
	#tag EndEvent

	#tag Event
		Sub Error(ErrorCode As Integer, err As RuntimeException)
		  DebugMsg("code = " + ErrorCode.ToString + " - message = " + err.Message , CurrentMethodName , true)
		  
		  RaiseEvent ipscError(ErrorCode , err)
		  
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub Constructor()
		  Workers = new Dictionary
		  
		  MinimumSocketsAvailable = 4
		  MaximumSocketsConnected = 32
		  
		  CleanupTimer = new Timer
		  CleanupTimer.RunMode = Timer.RunModes.Off
		  CleanupTimer.Period = 1000
		  AddHandler CleanupTimer.Action , AddressOf HandlerCleanupTimerAction
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HandlerCleanupTimerAction(sender as Timer)
		  // should run periodically and cleanup any idle workers who have finished executing
		  dim WorkerHandles() as variant = Workers.Keys
		  
		  try
		    
		    for i as Integer = 0 to WorkerHandles.LastIndex
		      if ipsc_ConnectionThread(Workers.Value(WorkerHandles(i).IntegerValue)).ThreadState = Thread.ThreadStates.NotRunning and _
		        ipsc_ConnectionThread(Workers.Value(WorkerHandles(i).IntegerValue)).Fired then
		        Workers.Remove(WorkerHandles(i).IntegerValue)
		      end if
		    next i
		    
		  Catch e as KeyNotFoundException
		    Return  // error due to edge case timing, no problem
		  Catch ee as NilObjectException
		    Return  // same as the above
		  end try
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Listen()
		  CleanupTimer.RunMode = Timer.RunModes.Multiple
		  
		  // Calling the overridden superclass method.
		  Super.Listen()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub StopListening()
		  CleanupTimer.RunMode = Timer.RunModes.Off
		  
		  // Calling the overridden superclass method.
		  Super.StopListening()
		  
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event ipscError(ErrorCode as integer, err as RuntimeException)
	#tag EndHook


	#tag Property, Flags = &h21
		Private CleanupTimer As Timer
	#tag EndProperty

	#tag Property, Flags = &h0
		SSLCertificateFile As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h0
		SSLCertificatePassword As String
	#tag EndProperty

	#tag Property, Flags = &h0
		SSLCertificateRejectionFile As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h0
		SSLConnectionType As SSLSocket.SSLConnectionTypes
	#tag EndProperty

	#tag Property, Flags = &h0
		SSLEnabled As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		Workers As Dictionary
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
			Name="Port"
			Visible=true
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="MinimumSocketsAvailable"
			Visible=true
			Group="Behavior"
			InitialValue="2"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="MaximumSocketsConnected"
			Visible=true
			Group="Behavior"
			InitialValue="10"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
