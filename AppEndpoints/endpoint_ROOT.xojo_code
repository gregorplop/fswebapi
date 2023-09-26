#tag Class
Protected Class endpoint_ROOT
	#tag Method, Flags = &h21
		Private Sub Constructor()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(byref initWorkerThread as ipservercore.ipscConnectionThread, initRootFolder as FolderItem)
		  WorkerThread = initWorkerThread
		  
		  // internal copies to keep code more readable
		  RqVerb = WorkerThread.SocketRef.RequestVerb.Uppercase
		  RqPath = WorkerThread.SocketRef.RequestPathArray
		  RqParams = WorkerThread.SocketRef.RequestParameters
		  folder = new FolderItem(initRootFolder)
		  
		  
		  select case RqVerb // route request
		    
		  case "GET" 
		    GET
		    
		  else
		    WorkerThread.SocketRef.RespondInError(501)  // not implemented
		  end select
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub GET()
		  dim DynamicRoot as String = RootPageTemplate
		  
		  DynamicRoot.Replace("$PAGETIMESTAMP$" , ipservercore.DateToRFC1123)
		  DynamicRoot.Replace("$ROOTFOLDER$" , folder.NativePath)
		  DynamicRoot.Replace("$PORT$" , WorkerThread.SocketRef.ServerRef.Port.ToString)
		  DynamicRoot.Replace("$ACL$" , if(WorkerThread.SocketRef.ServerRef.ACLEnabled , WorkerThread.SocketRef.ServerRef.ACLDatabaseFile.NativePath , "none"))
		  DynamicRoot.Replace("$SSLENABLE$" , WorkerThread.SocketRef.ServerRef.SSLEnabled.ToString)
		  DynamicRoot.Replace("$SSLMODE$" , if(WorkerThread.SocketRef.ServerRef.SSLEnabled , ipservercore.SSLModeString(WorkerThread.SocketRef.ServerRef.SSLConnectionType) , "not applicable"))
		  DynamicRoot.Replace("$SSLKEYCERTFILE$" , if(IsNull(WorkerThread.SocketRef.ServerRef.SSLCertificateFile) , "none" , WorkerThread.SocketRef.ServerRef.SSLCertificateFile.NativePath))
		  DynamicRoot.Replace("$SSLPASSWD$" , if(WorkerThread.SocketRef.ServerRef.SSLCertificatePassword = "" , "none" , "Yes"))
		  DynamicRoot.Replace("$SSLREJFILE$" , if(IsNull(WorkerThread.SocketRef.ServerRef.SSLCertificateRejectionFile) , "none" , WorkerThread.SocketRef.ServerRef.SSLCertificateRejectionFile.NativePath))
		  DynamicRoot.Replace("$DEBUGMODE$" , ipservercore.Debug.ToString)
		  DynamicRoot.Replace("$FSWEBAPIVER$" , app.Version)
		  DynamicRoot.Replace("$IPSERVERCOREVER$" , ipservercore.Version)
		  DynamicRoot.Replace("$OSTYPE$" , infoplastique.OSTypeString)
		  DynamicRoot.Replace("$SERVERSTARTTIME$" , WorkerThread.SocketRef.ServerRef.GetStartTimestamp.SQLDatetime)
		  DynamicRoot.Replace("$SERVERMEM$" , Runtime.MemoryUsed.ToString + "   (" + format(Runtime.MemoryUsed/MByte, "#.##") + " MB)")
		  DynamicRoot.Replace("$SERVEROBJECTS$" , Runtime.ObjectCount.ToString )
		  DynamicRoot.Replace("$SERVERSESSIONS$" , str(WorkerThread.SocketRef.ServerRef.ActiveConnections.LastIndex + 1))
		  
		  
		  WorkerThread.SocketRef.RespondOK(DynamicRoot , "text/html")
		  
		  
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h0
		folder As FolderItem
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


	#tag Constant, Name = RootPageTemplate, Type = String, Dynamic = False, Default = \"<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\r\n<html>\r\n  <head>\r\n    <meta http-equiv\x3D\"content-type\" content\x3D\"text/html; charset\x3Dutf-8\">\r\n    <title>fswebapi Status</title>\r\n    <meta name\x3D\"author\" content\x3D\"Georgios Poulopoulos\">\r\n    <style type\x3D\"text/css\">\r\n#body {\r\n  background-color: #33ccff;\r\n}\r\n\r\n</style></head>\r\n  <body style\x3D\"background-color: azure;\">\r\n    <h1 style\x3D\"text-align: center;\">fswebapi : The Web API file manager</h1>\r\n    <p style\x3D\"text-align: center;\">$PAGETIMESTAMP$<br>\r\n    </p>\r\n    <table style\x3D\"width: 538px; height: 334px;\" align\x3D\"center\" border\x3D\"1\">\r\n      <tbody>\r\n        <tr>\r\n          <td style\x3D\"text-align: left;\"><b>Working with Root folder<br>\r\n            </b></td>\r\n          <td style\x3D\"text-align: left;\">$ROOTFOLDER$</td>\r\n        </tr>\r\n        <tr>\r\n          <td style\x3D\"text-align: left;\"><b>Server listening at port<br>\r\n            </b></td>\r\n          <td style\x3D\"text-align: left;\">$PORT$</td>\r\n        </tr>\r\n        <tr>\r\n          <td style\x3D\"text-align: left;\"><b>ACL File<br>\r\n            </b></td>\r\n          <td style\x3D\"text-align: left;\">$ACL$</td>\r\n        </tr>\r\n        <tr>\r\n          <td style\x3D\"text-align: left;\"><b>SSL Enabled<br>\r\n            </b></td>\r\n          <td style\x3D\"text-align: left;\">$SSLENABLE$</td>\r\n        </tr>\r\n        <tr>\r\n          <td style\x3D\"text-align: left; width: 238.917px;\"><b>SSL Mode<br>\r\n            </b></td>\r\n          <td style\x3D\"text-align: left; width: 283.083px;\">$SSLMODE$</td>\r\n        </tr>\r\n        <tr>\r\n          <td style\x3D\"text-align: left;\"><b>SSL Combined Key/Cert<br>\r\n            </b></td>\r\n          <td style\x3D\"text-align: left;\">$SSLKEYCERTFILE$</td>\r\n        </tr>\r\n        <tr>\r\n          <td style\x3D\"text-align: left;\"><b>SSL Key/Cert password<br>\r\n            </b></td>\r\n          <td style\x3D\"text-align: left;\">$SSLPASSWD$</td>\r\n        </tr>\r\n        <tr>\r\n          <td style\x3D\"text-align: left;\"><b>SSL Rejection File<br>\r\n            </b></td>\r\n          <td style\x3D\"text-align: left;\">$SSLREJFILE$</td>\r\n        </tr>\r\n        <tr>\r\n          <td style\x3D\"text-align: left;\"><b>Debug mode set to<br>\r\n            </b></td>\r\n          <td style\x3D\"text-align: left;\">$DEBUGMODE$</td>\r\n        </tr>\r\n        <tr>\r\n          <td style\x3D\"text-align: left;\"><b>fswebapi version<br>\r\n            </b></td>\r\n          <td style\x3D\"text-align: left;\">$FSWEBAPIVER$</td>\r\n        </tr>\r\n        <tr>\r\n          <td style\x3D\"text-align: left;\"><b>ipservercore version<br>\r\n            </b></td>\r\n          <td style\x3D\"text-align: left;\">$IPSERVERCOREVER$</td>\r\n        </tr>\r\n        <tr>\r\n          <td><b>Server running on</b></td>\r\n          <td>$OSTYPE$</td>\r\n        </tr>\r\n        <tr>\r\n          <td><b>Server running since</b></td>\r\n          <td>$SERVERSTARTTIME$</td>\r\n        </tr>\r\n        <tr>\r\n          <td><b>Server memory usage<br>\r\n            </b></td>\r\n          <td>$SERVERMEM$</td>\r\n        </tr>\r\n        <tr>\r\n          <td><b>Server object count<br>\r\n            </b></td>\r\n          <td>$SERVEROBJECTS$</td>\r\n        </tr>\r\n        <tr>\r\n          <td><strong>Server active sessions</strong></td>\r\n          <td>$SERVERSESSIONS$</td>\r\n        </tr>\r\n      </tbody>\r\n    </table>\r\n    <p style\x3D\"height: 34px; text-align: center;\"><br>\r\n    </p>\r\n    <p style\x3D\"height: 34px; text-align: center;\">Project repository in <a href\x3D\"https://github.com/gregorplop/fswebapi\"\r\n\r\n        title\x3D\"https://github.com/gregorplop/fswebapi\">GitHub</a><br>\r\n    </p>\r\n  </body>\r\n</html>", Scope = Private
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
