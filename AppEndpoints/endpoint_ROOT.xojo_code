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


	#tag Constant, Name = RootPageTemplate, Type = String, Dynamic = False, Default = \"<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\r<html>\r  <head>\r    <meta http-equiv\x3D\"content-type\" content\x3D\"text/html; charset\x3Dutf-8\">\r    <title>fswebapi Status</title>\r    <meta name\x3D\"author\" content\x3D\"Georgios Poulopoulos\">\r    <style type\x3D\"text/css\">\r#body {\r  background-color: #33ccff;\r}\r\r</style></head>\r  <body style\x3D\"background-color: azure;\">\r    <h1 style\x3D\"text-align: center;\">fswebapi : The Web API file manager</h1>\r    <p style\x3D\"text-align: center;\">$PAGETIMESTAMP$<br>\r    </p>\r    <table style\x3D\"width: 538px; height: 334px;\" align\x3D\"center\" border\x3D\"1\">\r      <tbody>\r        <tr>\r          <td style\x3D\"text-align: left;\"><b>Working with Root folder<br>\r            </b></td>\r          <td style\x3D\"text-align: left;\">$ROOTFOLDER$</td>\r        </tr>\r        <tr>\r          <td style\x3D\"text-align: left;\"><b>Server listening at port<br>\r            </b></td>\r          <td style\x3D\"text-align: left;\">$PORT$</td>\r        </tr>\r        <tr>\r          <td style\x3D\"text-align: left;\"><b>SSL Enabled<br>\r            </b></td>\r          <td style\x3D\"text-align: left;\">$SSLENABLE$</td>\r        </tr>\r        <tr>\r          <td style\x3D\"text-align: left; width: 238.917px;\"><b>SSL Mode<br>\r            </b></td>\r          <td style\x3D\"text-align: left; width: 283.083px;\">$SSLMODE$</td>\r        </tr>\r        <tr>\r          <td style\x3D\"text-align: left;\"><b>SSL Combined Key/Cert<br>\r            </b></td>\r          <td style\x3D\"text-align: left;\">$SSLKEYCERTFILE$</td>\r        </tr>\r        <tr>\r          <td style\x3D\"text-align: left;\"><b>SSL Key/Cert password<br>\r            </b></td>\r          <td style\x3D\"text-align: left;\">$SSLPASSWD$</td>\r        </tr>\r        <tr>\r          <td style\x3D\"text-align: left;\"><b>SSL Rejection File<br>\r            </b></td>\r          <td style\x3D\"text-align: left;\">$SSLREJFILE$</td>\r        </tr>\r        <tr>\r          <td style\x3D\"text-align: left;\"><b>Debug mode set to<br>\r            </b></td>\r          <td style\x3D\"text-align: left;\">$DEBUGMODE$</td>\r        </tr>\r        <tr>\r          <td style\x3D\"text-align: left;\"><b>fswebapi version<br>\r            </b></td>\r          <td style\x3D\"text-align: left;\">$FSWEBAPIVER$</td>\r        </tr>\r        <tr>\r          <td style\x3D\"text-align: left;\"><b>ipservercore version<br>\r            </b></td>\r          <td style\x3D\"text-align: left;\">$IPSERVERCOREVER$</td>\r        </tr>\r        <tr>\r          <td><b>Server running on</b></td>\r          <td>$OSTYPE$</td>\r        </tr>\r        <tr>\r          <td><b>Server running since</b></td>\r          <td>$SERVERSTARTTIME$</td>\r        </tr>\r        <tr>\r          <td><b>Server memory usage<br>\r            </b></td>\r          <td>$SERVERMEM$</td>\r        </tr>\r        <tr>\r          <td><b>Server object count<br>\r            </b></td>\r          <td>$SERVEROBJECTS$</td>\r        </tr>\r        <tr>\r          <td><strong>Server active sessions</strong></td>\r          <td>$SERVERSESSIONS$</td>\r        </tr>\r      </tbody>\r    </table>\r    <p style\x3D\"height: 34px; text-align: center;\"><br>\r    </p>\r    <p style\x3D\"height: 34px; text-align: center;\">Project repository in <a href\x3D\"https://github.com/gregorplop/fswebapi\"\r\r        title\x3D\"https://github.com/gregorplop/fswebapi\">GitHub</a><br>\r    </p>\r  </body>\r</html>", Scope = Private
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
