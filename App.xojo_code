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
		  
		  Server = new ipsc_Server 
		  
		  dim ExitMsg as string
		  dim ExitCode as Integer
		  
		  dim argsdict as Dictionary = ParseCmdLineArgs(args)
		  
		  // process startup parameters
		  if not ProcessCmdLineArgs(argsdict , ExitMsg , ExitCode) then
		    System.DebugLog(ExitMsg + " --The service will now quit!")
		    Print ExitMsg + " --The service will now quit!"
		    Quit(ExitCode)
		  end if
		  
		  Server.Listen
		  
		  print "Working with root folder : " + RootFolder.NativePath
		  print "Server listening at port : " + Server.Port.ToString
		  print "Debug mode set to        : " + ipsc_Lib.Debug.ToString
		  Print "fswebapi version         : " + app.Version
		  Print "ipservercore version     : " + ipsc_Lib.Version
		  Print "======================================================="
		  print ""
		  
		  
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
		Function ParseCmdLineArgs(args() as string) As Dictionary
		  // WARNING: This mechanism has the following limitation:
		  // no single parameter should not contain a space!
		  // example: --debug , --rootfolder=c:\shared : THESE ARE OK
		  // counter-example: --rootfolder = "c:\my shared files" : THIS CANNOT BE PARSED SUCCESSFULLY 
		  
		  dim argDictionary as new Dictionary
		  
		  for i as Integer = 1 to args.LastIndex
		    if args(i) = args(0) then exit for i  // workaround for duplicate args bug
		    if args(i).Left(2) <> "--" then Continue for i // all parameters start with "--"
		    
		    if args(i).CountFields("=") = 1 then  // just the presense of a switch
		      
		      argDictionary.Value(args(i).ReplaceAll("--" , "").Lowercase) = true // switches always carry a boolean true value
		      
		    else // assumes it's a key-value pair that does not contain an "=" as part of the value
		      
		      argDictionary.Value(args(i).NthField("=" , 1).ReplaceAll("--" , "").Lowercase) = args(i).NthField("=" , 2)
		      
		    end if
		    
		  next i
		  
		  Return argDictionary
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ProcessCmdLineArgs(argsdict as Dictionary, byref ErrorMsg as string, byref ExitCode as integer) As Boolean
		  // returns false if a necessary parameter is missing or invalid. Error message on ErrorMsg string
		  // returns true if all okay
		  // sets all appropriate application-level properties according to input parameters+
		  
		  ErrorMsg = ""
		  ExitCode = 0
		  
		  // rootfolder
		  if not argsdict.HasKey("rootfolder") then
		    ErrorMsg =  "No --rootfolder startup parameter found!"
		    ExitCode = 1
		    Return false
		  else
		    RootFolder = new FolderItem(argsdict.Value("rootfolder").StringValue , FolderItem.PathModes.Native)
		    if IsNull(RootFolder) then  // rootfolder is null
		      ErrorMsg = "Rootfolder path is invalid!"
		      ExitCode = 2
		      Return false
		    else
		      if not RootFolder.Exists then  // rootfolder does not exist
		        ErrorMsg = "Rootfolder does not exist!"
		        ExitCode = 3
		        Return false
		      end if
		      if not RootFolder.IsFolder then  //rootfolder is not a folder
		        ErrorMsg = "Defined rootfolder is not a folder!"
		        ExitCode = 4
		        Return false
		      end if
		    end if
		  end if
		  
		  // check for debug mode flag
		  if argsdict.HasKey("debug") then // debug logging mode on --service will be quite verbose on the console and the debug log
		    ipsc_Lib.debug = true
		  else
		    ipsc_Lib.Debug = false
		  end if
		  
		  // server port
		  if not argsdict.HasKey("port") then
		    ErrorMsg =  "No --port startup parameter found!"
		    ExitCode = 5
		    Return false
		  else
		    Server.Port = argsdict.Value("port").IntegerValue
		    if server.Port < 1 or Server.Port > 65535 then
		      ErrorMsg = "Invalid port value!"
		      ExitCode = 6
		      Return False
		    end if
		  end if
		  
		  Return True
		  
		End Function
	#tag EndMethod

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


	#tag Note, Name = Endpoints
		implemented endpoints:
		
		/files/(full filename path)
		/folders/(folder path)
		
		all paths are relative to the root folder defined with the --rootfolder command line parameter
		
		
	#tag EndNote

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
