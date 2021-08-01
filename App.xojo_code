#tag Class
Protected Class App
Inherits ServiceApplication
	#tag Event
		Sub Pause()
		  // Only gets called on Windows. We should pause.
		End Sub
	#tag EndEvent

	#tag Event
		Sub Resume()
		  // Only gets called on Windows. We should resume.
		End Sub
	#tag EndEvent

	#tag Event
		Function Run(args() as String) As Integer
		  // This is the apps's main execution point.
		  // Note that on Windows, exiting the Run event
		  // does NOT terminate a service application. The
		  // service won't terminate until the Stop event
		  // occurs. So to be consistent, let's just call 
		  // quit with our exit code.
		  
		  RootFolder = new FolderItem("C:\Shared" , FolderItem.PathModes.Native)
		  
		  
		  ipsc_lib.debug = true
		  Server = new ipsc_Server 
		  
		  Server.Port = 8080
		  Server.Listen
		  
		  print "Server started - listening at " + Server.Port.ToString
		  
		  do // main loop
		    
		    DoEvents
		    
		  loop Until kill  = true
		  
		  
		  Quit(0)
		End Function
	#tag EndEvent

	#tag Event
		Sub Stop(shuttingDown as Boolean)
		  // This gets called on all platforms (but the
		  // shuttingDown parameter is only valid on Windows).
		  // We should do our cleanup here.
		End Sub
	#tag EndEvent

	#tag Event
		Function UnhandledException(error As RuntimeException) As Boolean
		  DebugMsg(error.Message , CurrentMethodName , true)
		  
		End Function
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub RouteRequest(WorkerThread as ipsc_ConnectionThread)
		  select case WorkerThread.SocketRef.RequestPath.NthField("/" , 2).Lowercase
		    
		  case "files"
		    
		    dim files as new endpoint_files(WorkerThread , RootFolder)
		    
		  case "folders"
		    
		    dim folders as new endpoint_folders(WorkerThread , RootFolder)
		    
		  else
		    WorkerThread.SocketRef.RespondInError(501)  // not implemented
		  end select
		  
		End Sub
	#tag EndMethod


	#tag Note, Name = MIT License
		MIT License
		===============================================================================
		Copyright (c) 2021 Georgios Poulopoulos
		
		Permission is hereby granted, free of charge, to any person obtaining 
		a copy of this software and associated documentation files (the "Software"), 
		to deal in the Software without restriction, including without limitation 
		the rights to use, copy, modify, merge, publish, distribute, sublicense, 
		and/or sell copies of the Software, and to permit persons to whom the 
		Software is furnished to do so, subject to the following conditions:
		
		The above copyright notice and this permission notice shall be included 
		in all copies or substantial portions of the Software.
		
		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
		OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
		THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
		THE SOFTWARE.
		
	#tag EndNote


	#tag Property, Flags = &h0
		Kill As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		RootFolder As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h0
		Server As ipsc_Server
	#tag EndProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="Kill"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
