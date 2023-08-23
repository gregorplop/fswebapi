#tag Module
Protected Module infoplastique
	#tag Method, Flags = &h1
		Protected Function DeleteFSitems(byref FSitemsArray() as FolderItem) As integer
		  // starts from finish to start to remove folderitems
		  
		  dim CurrentFolderItem as FolderItem
		  
		  do until FSitemsArray.LastIndex < 0
		    
		    CurrentFolderItem = FSitemsArray(FSitemsArray.LastIndex)
		    
		    try
		      CurrentFolderItem.Remove
		    Catch e as NilObjectException
		      Return -1
		    Catch ee as IOException
		      Return ee.ErrorNumber
		    end try
		    
		    call FSitemsArray.Pop
		    
		  loop
		  
		  
		  Return 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GenerateRandomURLableString(length as integer, optional CanStartWithNumber as Boolean = true) As String
		  dim seq as String = "aAbB1cCdD2eEfFg3GhHiIjJkKl4LmMnN5o6OpPqQ7rR8sStTuUv9VwWxXyYz0Z" + System.Microseconds.ToString.Right(2)
		  dim output(-1) as String
		  
		  seq = seq + seq + seq + seq
		  
		  dim randomBytes as String 
		  
		  do
		    Redim output(-1)
		    randomBytes = Crypto.GenerateRandomBytes(length)
		    for i as integer = 0 to length - 1
		      output.Append seq.Middle(randomBytes.Middle(i,1).Asc , 1)
		    next i
		    output.Shuffle
		  loop until (IsNumeric(output(0)) = false) or CanStartWithNumber
		  
		  Return String.FromArray(output , empty)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ListFolderContents(BaseFolder as FolderItem, byref ContentsList as String) As Boolean
		  // returns a tab-delimited list of files with the following fields
		  // 1=filename , 2=fs object type{file,dir,alias} , 3=size(only for files) , 4=creation timestamp , 5=modification timestamp
		  
		  ContentsList = ""
		  
		  if IsNull(BaseFolder) then Return false
		  if not BaseFolder.IsFolder then return false
		  
		  dim fsobjRecord(4) as String 
		  dim tab as String = Chr(9)
		  dim objtype as string
		  
		  
		  try
		    
		    for each fsobj as FolderItem in BaseFolder.Children
		      
		      
		      fsobjRecord(0) = fsobj.Name
		      
		      if fsobj.IsAlias then
		        fsobjRecord(1) = "alias"
		      ElseIf fsobj.IsFolder then
		        fsobjRecord(1) = "dir"
		      Else 
		        fsobjRecord(1) = "file"
		      end if
		      
		      select case fsobjRecord(1)
		      case "file" , "alias"
		        fsobjRecord(2) = fsobj.Length.ToString
		      case "dir"
		        fsobjRecord(2) = "-"
		      else
		        fsobjRecord(2) = "X"
		      end select
		      
		      fsobjRecord(3) = fsobj.CreationDateTime.SQLDateTime
		      fsobjRecord(4) = fsobj.ModificationDateTime.SQLDateTime
		      
		      ContentsList = ContentsList + String.FromArray(fsobjRecord , tab) + EndOfLine.Windows
		      
		    next 
		    
		  Catch ioe as IOException
		    Return false
		  Catch noe as NilObjectException
		    Return false
		  end try
		  
		  Return true
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function OSTypeString() As string
		  if TargetLinux then Return "Linux"
		  if TargetWindows then Return "Windows"
		  if TargetMacOS then Return "MacOS"
		  if TargetIOS then Return "iOS"
		  
		  Return "unidentified"
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Replace(extends  byref original as string, LookFor as string, ReplaceWith as string)
		  original = original.ReplaceAll(LookFor , ReplaceWith)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub ScanFolderItems(Root as FolderItem, byref Result() as FolderItem, optional IncludeFolders as boolean = false)
		  if IncludeFolders then Result.Add(root)
		  
		  for each fsobj as FolderItem in root.Children
		    
		    if fsobj.IsFolder then
		      
		      ScanFolderItems(fsobj , Result , IncludeFolders)
		      
		    else
		      
		      Result.Add fsobj
		      
		    end if
		    
		  next 
		  
		End Sub
	#tag EndMethod


	#tag Constant, Name = empty, Type = String, Dynamic = False, Default = \"", Scope = Public
	#tag EndConstant

	#tag Constant, Name = MByte, Type = Double, Dynamic = False, Default = \"1048576", Scope = Public
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
