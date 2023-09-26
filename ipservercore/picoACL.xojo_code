#tag Class
Protected Class picoACL
	#tag Method, Flags = &h21
		Private Sub AppendItemToList_Unique(byref Item2Append as Integer, byref TargetList() as Integer)
		  if TargetList.IndexOf(Item2Append) < 0 then TargetList.Add Item2Append
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function AuthenticateUser(UserName as String, password as string) As Boolean
		  // generates runtime exception if error
		  
		  try
		    
		    dbReconnect
		    
		    dim rows as RowSet = db.SelectSQL("SELECT rowid FROM roles WHERE name = ? AND passwdhash = ? AND loginrole = TRUE AND active = TRUE" , UserName , HashPlaintextPasswd(UserName , password))
		    
		    dim rowCount as Integer = rows.RowCount
		    
		    db.Close
		    
		    if rowCount = 1 then
		      Return true
		    else
		      Return False
		    end if
		    
		  Catch e as DatabaseException
		    db.Close
		    Raise new RuntimeException("Error Authenticating User: " + e.Message , 9)
		  end try
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function AuthoriseUser4Resource(UserName as String, Service as String, Right as String, Resource as string) As Boolean
		  dim UserID as Integer
		  dim RoleIDs2InheritFrom() as Integer
		  dim rows as RowSet
		  dim RightIDs() as String //directly to string, so we won't have to convert
		  dim Allow , Deny as Boolean
		  
		  try
		    
		    dbReconnect
		    
		    // look for the user ID
		    rows = db.SelectSQL("SELECT rowid FROM roles WHERE name = ? AND loginrole = TRUE AND active = TRUE" , UserName)
		    
		    if rows.RowCount <> 1 then 
		      db.Close
		      Raise new RuntimeException("Role not resolved." , 4)
		    end if
		    
		    UserID = rows.Column("rowid").IntegerValue
		    
		    // we have the User ID
		    // let's look if the appropriate righs are registered
		    
		    rows = db.SelectSQL("SELECT rowid FROM rights WHERE service = ? AND (right = ? OR right = ?)" , Service , Right , ANY_RIGHT)
		    
		    for each row as DatabaseRow in rows
		      RightIDs.Add row.Column("rowid").StringValue
		    next 
		    
		    if RightIDs.LastIndex < 0 then 
		      db.Close
		      Raise new RuntimeException("Right not resolved." , 7)
		    end if
		    
		    // we have the list of rights to look for in the ACL
		    // next, we compile a list of role IDs this user ID inherits from:
		    // recursively and taking role active status into account
		    
		    SurveyMembershipsOfRole(RoleIDs2InheritFrom , UserID)
		    
		    // we have the list of roles
		    
		    dim SurveyACLquery as String = "SELECT COUNT(*) FROM acl WHERE roleid IN (" + String.FromArray(IntList2StringList(RoleIDs2InheritFrom) , ",") + ") AND rightid IN (" + String.FromArray(RightIDs , ",") + ") AND (resource = ? OR resource = ?) AND deny = ?"
		    
		    rows = db.SelectSQL(SurveyACLquery , Resource , ANY_RESOURCE , False) // look for grants (deny=false)
		    Allow = if(rows.ColumnAt(0).IntegerValue = 0 , false , true)
		    
		    rows = db.SelectSQL(SurveyACLquery , Resource , ANY_RESOURCE , true) // look for inverse grants (deny=true)
		    Deny = if(rows.ColumnAt(0).IntegerValue = 0 , False , true)
		    
		    db.Close
		    
		  Catch e as DatabaseException
		    db.Close
		    Raise new RuntimeException("Authorization Error: " + e.Message , 15)
		  end try
		  
		  
		  if Allow and not Deny then 
		    Return true
		  else
		    Return False
		  end if
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Constructor()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(ACLFile as FolderItem, optional passwd as string = "")
		  dbFile = ACLFile
		  dbPasswd = passwd
		  
		  db = new SQLiteDatabase
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub CreateACL(Service as String, Right as string, Resource as String, RoleName as string, optional Deny as Boolean = false)
		  // an ACL is assigning a RIGHT to a ROLE, 
		  // for a RESOURCE, made available through a SERVICE
		  
		  // null RESOURCE means ALL RESOURCES
		  
		  dim rows as RowSet
		  dim RoleID as Integer
		  dim RightID as Integer
		  dim NullableResource as Variant
		  
		  if Resource.Trim <> "" then NullableResource = Resource
		  
		  try
		    
		    dbReconnect
		    
		    // look for the role
		    rows = db.SelectSQL("SELECT rowid FROM roles WHERE name = ?" , RoleName)
		    
		    if rows.RowCount <> 1 then 
		      db.Close
		      Raise new RuntimeException("Role not resolved." , 4)
		    end if
		    
		    roleID = rows.Column("rowid").IntegerValue
		    
		    // we have the role id, go on to find right id
		    
		    rows = db.SelectSQL("SELECT rowid FROM rights WHERE service = ? AND right = ?" , Service , Right)
		    
		    if rows.RowCount <> 1 then 
		      db.Close
		      Raise new RuntimeException("Right not resolved." , 7)
		    end if
		    
		    RightID = rows.Column("rowid").IntegerValue
		    
		    // create the ACL record 
		    
		    db.ExecuteSQL("INSERT INTO acl (roleid , rightid , resource , deny) VALUES (? , ? , ? , ?)" , RoleID , RightID , NullableResource , Deny)
		    
		    db.Close
		    
		    
		  Catch e as DatabaseException
		    db.Close
		    Raise new RuntimeException("Error creating ACL: " + e.Message , 8)
		  end try
		  
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Shared Function CreateACLFile(byref ErrorMsg as String, file as folderitem, optional passwd as string = "") As Boolean
		  ErrorMsg = ""
		  
		  if IsNull(file) then 
		    ErrorMsg = "Invalid ACL file"
		    Return False
		  end if
		  
		  if file.Exists then
		    ErrorMsg = "ACL file already exists at " + file.NativePath
		    Return False
		  end if
		  
		  dim newdb as new SQLiteDatabase
		  newdb.DatabaseFile = file
		  newdb.EncryptionKey = passwd
		  
		  try
		    
		    newdb.CreateDatabase
		    newdb.ExecuteSQL(InitStatements)
		    
		    newdb.Close
		    
		  Catch e as IOException
		    ErrorMsg = "Error on ACL file create: " + e.Message
		    Return False
		    
		  Catch ee as DatabaseException
		    ErrorMsg = "Error on ACL file init: " + ee.Message
		    newdb.Close
		    file.Remove
		    Return false
		  end try
		  
		  
		  
		  Return true
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub CreateGroup(GroupName as string, optional Active as Boolean = true)
		  try
		    
		    dbReconnect
		    db.ExecuteSQL("INSERT INTO roles (name , active , loginrole , passwdhash) VALUES (? , ? , FALSE , NULL)" , GroupName , Active)
		    db.Close
		    
		  Catch e as DatabaseException
		    db.Close
		    Raise new RuntimeException("Error creating Group: " + e.Message , 3)
		  end try
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub CreateMembership(UserName as string, GroupName as string)
		  dim rows as RowSet
		  dim userID as Integer
		  dim groupID as Integer
		  dim groupLoginRole as Boolean
		  
		  try
		    
		    dbReconnect
		    
		    // look for related records
		    rows = db.SelectSQL("SELECT rowid , loginrole , name FROM roles WHERE name = ? OR name = ?" , UserName , GroupName)
		    
		    if rows.RowCount <> 2 then 
		      db.Close
		      Raise new RuntimeException("Role not resolved." , 4)
		    end if
		    
		    for each row as DatabaseRow in rows
		      select case row.Column("name").StringValue
		      case UserName
		        userID = row.Column("rowid").IntegerValue
		      case GroupName
		        groupID = row.Column("rowid").IntegerValue
		        groupLoginRole = row.Column("loginrole").BooleanValue
		      end select
		    next
		    
		    if groupLoginRole then // group is a login role: you cannot assign a role as member of a user
		      db.Close
		      raise new RuntimeException("Invalid role assignment." , 5)
		    end if
		    
		    // create the membership record
		    
		    db.ExecuteSQL("INSERT INTO memberships (roleid , memberof_roleid) VALUES (? , ?)" , userID , groupID)
		    
		    db.Close
		    
		  Catch e as DatabaseException
		    db.Close
		    Raise new RuntimeException("Error Assigning Membership: " + e.Message , 6)
		  end try
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub CreateRight(Service as string, Right as String)
		  try
		    
		    dbReconnect
		    db.ExecuteSQL("INSERT INTO rights (service , right) VALUES (?,?)" , Service , Right)
		    db.Close
		    
		  Catch e as DatabaseException
		    db.Close
		    Raise new RuntimeException("Error creating Right: " + e.Message , 1)
		  end try
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub CreateUser(UserName as string, Passwd as string, optional Active as Boolean = true)
		  dim passhash as String = HashPlaintextPasswd(UserName , Passwd)
		  
		  try
		    dbReconnect
		    db.ExecuteSQL("INSERT INTO roles (name , active , loginrole , passwdhash) VALUES (? , ? , TRUE , ?)" , UserName , Active , passhash)
		    db.Close
		    
		  Catch e as DatabaseException
		    db.Close
		    Raise new RuntimeException("Error creating User: " + e.Message , 2)
		  end try
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub dbReconnect()
		  db.DatabaseFile = dbFile
		  db.EncryptionKey = dbPasswd
		  db.Connect
		  db.ExecuteSQL("PRAGMA foreign_keys = ON")
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DeleteACLRecord(ACLRecordID as Integer)
		  dim rows as RowSet
		  
		  try
		    
		    dbReconnect
		    
		    // look if the ACL record exists - unlike a single DELETE, we want to fail if it doesn't exist
		    rows = db.SelectSQL("SELECT COUNT(*) FROM acl WHERE rowid  = ?" , ACLRecordID)
		    
		    if rows.ColumnAt(0).IntegerValue <> 1 then
		      db.Close
		      Raise new RuntimeException("ACL Record not resolved." , 18)
		    end if
		    
		    // let's delete the ACL record
		    
		    db.ExecuteSQL("DELETE FROM acl WHERE rowid = ?" , ACLRecordID)
		    
		    db.Close
		    
		  Catch e as DatabaseException
		    db.Close
		    Raise new RuntimeException("Error Deleting ACL record: " + e.Message , 19)
		  end try
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DeleteRight(Service as String, Right as string)
		  dim rightID as Integer
		  dim rows as RowSet
		  
		  try
		    
		    dbReconnect
		    
		    // look for the right
		    rows = db.SelectSQL("SELECT rowid FROM rights WHERE service = ? AND right = ?" , Service , Right)
		    
		    if rows.RowCount <> 1 then 
		      db.Close
		      Raise new RuntimeException("Right not resolved." , 7)
		    end if
		    
		    RightID = rows.Column("rowid").IntegerValue
		    
		    // let's delete the right
		    
		    db.ExecuteSQL("DELETE FROM rights WHERE rowid = ?" , rightID)
		    
		    db.Close
		    
		    
		  Catch e as DatabaseException
		    db.Close
		    Raise new RuntimeException("Error Deleting Right: " + e.Message , 16)
		  end try
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DeleteRole(RoleName as String)
		  dim roleID as Integer
		  dim rows as RowSet
		  
		  try
		    
		    dbReconnect
		    
		    // look for the role
		    rows = db.SelectSQL("SELECT rowid FROM roles WHERE name = ?" , RoleName)
		    
		    if rows.RowCount <> 1 then 
		      db.Close
		      Raise new RuntimeException("Role not resolved." , 4)
		    end if
		    
		    roleID = rows.Column("rowid").IntegerValue
		    
		    // let's delete the role
		    
		    db.ExecuteSQL("DELETE FROM roles WHERE rowid = ?" , roleID)
		    
		    db.Close
		    
		    
		  Catch e as DatabaseException
		    db.Close
		    Raise new RuntimeException("Error Deleting Role: " + e.Message , 12)
		  end try
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetRolenameFromID(RoleID as Integer) As String
		  dim rows as RowSet
		  dim RoleName as String
		  
		  try
		    
		    dbReconnect
		    
		    // look for the role
		    rows = db.SelectSQL("SELECT name FROM roles WHERE rowid = ?" , RoleID)
		    
		    if rows.RowCount <> 1 then 
		      db.Close
		      Raise new RuntimeException("Role not resolved." , 4)
		    end if
		    
		    RoleName = rows.Column("name").StringValue
		    
		    db.Close
		    
		  Catch e as DatabaseException
		    db.Close
		    Raise new RuntimeException("Error Finding Role Name: " + e.Message , 17)
		  end try
		  
		  Return RoleName
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function HashPlaintextPasswd(UserName as String, PlaintextPasswd as String) As String
		  dim passhash as String
		  
		  passhash = UserName.Lowercase.Trim + ":" + PlaintextPasswd 
		  passhash = EncodeHex(Crypto.SHA3_256(passhash))
		  
		  Return passhash
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function IntList2StringList(IntList() as Integer) As String()
		  dim StringList() as String
		  
		  for each item as Integer in IntList
		    StringList.Add item.ToString
		  next
		  
		  Return StringList
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RemoveMembership(MemberRole as string, GroupRole as string)
		  dim rows as RowSet
		  dim memberID as Integer
		  dim groupID as Integer
		  dim membershipID as Integer
		  
		  try
		    
		    dbReconnect
		    
		    // look for role records
		    rows = db.SelectSQL("SELECT rowid , name FROM roles WHERE name = ? OR name = ?" , MemberRole , GroupRole)
		    
		    if rows.RowCount <> 2 then 
		      db.Close
		      Raise new RuntimeException("Role not resolved." , 4)
		    end if
		    
		    for each row as DatabaseRow in rows
		      select case row.Column("name").StringValue
		      case MemberRole
		        memberID = row.Column("rowid").IntegerValue
		      case GroupRole
		        groupID = row.Column("rowid").IntegerValue
		      end select
		    next
		    
		    
		    // look for the membership record
		    
		    rows = db.SelectSQL("SELECT rowid FROM memberships WHERE roleid = ? AND memberof_roleid = ?" , memberID , groupID)
		    
		    if rows.RowCount <> 1 then
		      db.Close
		      Raise new RuntimeException("Membership not resolved." , 14)
		    end if
		    
		    membershipID = rows.Column("rowid").IntegerValue
		    
		    // remove membership record
		    
		    db.ExecuteSQL("DELETE FROM memberships WHERE rowid = ?" , membershipID)
		    
		    
		    db.Close
		    
		  Catch e as DatabaseException
		    db.Close
		    Raise new RuntimeException("Error Removing Membership: " + e.Message , 13)
		  end try
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetRoleActiveStatus(RoleName as String, ActiveFlag as Boolean)
		  dim roleID as Integer
		  dim rows as RowSet
		  
		  try
		    
		    dbReconnect
		    
		    // look for the role
		    rows = db.SelectSQL("SELECT rowid FROM roles WHERE name = ?" , RoleName)
		    
		    if rows.RowCount <> 1 then 
		      db.Close
		      Raise new RuntimeException("Role not resolved." , 4)
		    end if
		    
		    roleID = rows.Column("rowid").IntegerValue
		    
		    // let's set the active flag
		    
		    db.ExecuteSQL("UPDATE roles SET active = ? WHERE rowid = ?" , ActiveFlag , roleID)
		    
		    db.Close
		    
		    
		  Catch e as DatabaseException
		    db.Close
		    Raise new RuntimeException("Error setting Active Flag: " + e.Message , 10)
		  end try
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SurveyMembershipsOfRole(byref IDs2InheritFrom() as Integer, RoleID as Integer, optional IgnoreActiveFlag as Boolean = false)
		  // For internal class use: assumes db is open and unoccupied, does not handle databaseExceptions
		  AppendItemToList_Unique(RoleID , IDs2InheritFrom)
		  
		  dim rows as RowSet
		  
		  if IgnoreActiveFlag then
		    rows = db.SelectSQL("SELECT * FROM memberships WHERE roleid = ? ORDER BY memberof_roleid ASC" , RoleID)
		  else
		    rows = db.SelectSQL("SELECT memberships.* FROM memberships INNER JOIN (SELECT * FROM roles WHERE active = TRUE) activeroles ON memberships.memberof_roleid = activeroles.rowid WHERE memberships.roleid = ?" , RoleID)
		  end if
		  
		  for each row as DatabaseRow in rows
		    SurveyMembershipsOfRole(IDs2InheritFrom , row.Column("memberof_roleid").IntegerValue , IgnoreActiveFlag)
		  next
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub UpdateUserPassword(UserName as String, Passwd as String)
		  dim passhash as String = HashPlaintextPasswd(UserName , Passwd)
		  dim rows as RowSet
		  dim roleID as Integer
		  
		  try
		    
		    dbReconnect
		    
		    rows = db.SelectSQL("SELECT rowid FROM roles WHERE name = ? AND loginrole = TRUE" , UserName)
		    
		    if rows.RowCount <> 1 then 
		      db.Close
		      Raise new RuntimeException("Role not resolved." , 4)
		    end if
		    
		    roleID = rows.Column("rowid").IntegerValue
		    
		    // let's set the active flag
		    
		    db.ExecuteSQL("UPDATE roles SET passwdhash = ? WHERE rowid = ?" , passhash , roleID)
		    
		    db.Close
		    
		  Catch e as DatabaseException
		    db.Close
		    Raise new RuntimeException("Error Updating Password: " + e.Message , 11)
		  end try
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Validate() As Boolean
		  // is it a readable database?
		  
		  try
		    
		    dbReconnect
		    
		  Catch e as DatabaseException
		    
		    Return false
		    
		  end try
		  
		  db.Close
		  
		  Return true
		  
		End Function
	#tag EndMethod


	#tag Note, Name = Error Codes
		Error codes of RuntimeExceptions
		
		1  Error Creating Right
		2  Error Creating User
		3  Error Creating User Group
		4  Role not resolved
		5  Invalid Role Assignment
		6  Error Assigning Membership
		7  Right not resolved
		8  Error creating ACL
		9  Error Authenticating User
		10 Error setting Role Active Flag
		11 Error Updating Password
		12 Error Deleting Role
		13 Error Removing Membership
		14 Membership not resolved
		15 Authorization Error
		16 Error Deleting Right
		17 Error Finding Role Name
		18 ACL Record not resolved
		19 Error Deleting ACL record
		
		
	#tag EndNote

	#tag Note, Name = License
		MIT LICENSE
		
		Copyright (c) 2023 Georgios Poulopoulos
		
		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:
		
		The above copyright notice and this permission notice shall be included in all
		copies or substantial portions of the Software.
		
		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
		SOFTWARE.
	#tag EndNote


	#tag Property, Flags = &h21
		Private db As SQLiteDatabase
	#tag EndProperty

	#tag Property, Flags = &h21
		Private dbFile As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h21
		Private dbPasswd As String
	#tag EndProperty


	#tag Constant, Name = ANY_RESOURCE, Type = String, Dynamic = False, Default = \"<ANYRESOURCE>", Scope = Public
	#tag EndConstant

	#tag Constant, Name = ANY_RIGHT, Type = String, Dynamic = False, Default = \"<ANYRIGHT>", Scope = Public
	#tag EndConstant

	#tag Constant, Name = InitStatements, Type = String, Dynamic = False, Default = \"CREATE TABLE roles ( rowid INTEGER PRIMARY KEY AUTOINCREMENT \x2C name TEXT UNIQUE NOT NULL \x2C active BOOLEAN NOT NULL DEFAULT TRUE \x2C loginrole BOOLEAN NOT NULL DEFAULT TRUE \x2C passwdhash TEXT \x2C CHECK((loginrole \x3D TRUE AND passwdhash IS NOT NULL) OR (loginrole \x3D FALSE AND passwdhash IS NULL))\x2C CHECK(name !\x3D \'\') \x2C CHECK(passwdhash !\x3D \'\'));\r\nCREATE TABLE memberships ( rowid INTEGER PRIMARY KEY AUTOINCREMENT \x2C roleid INTEGER NOT NULL \x2C memberof_roleid INTEGER NOT NULL \x2C FOREIGN KEY(roleid) REFERENCES roles(rowid) \x2C FOREIGN KEY(memberof_roleid) REFERENCES roles(rowid) \x2C UNIQUE(roleid \x2C memberof_roleid) \x2C CHECK(roleid !\x3D memberof_roleid));\r\nCREATE TABLE rights ( rowid INTEGER PRIMARY KEY AUTOINCREMENT \x2C service TEXT NOT NULL \x2C right TEXT NOT NULL \x2C UNIQUE (service \x2C right) \x2C CHECK(service !\x3D \'\') \x2C CHECK(right !\x3D \'\'));\r\nCREATE TABLE acl ( rowid INTEGER PRIMARY KEY AUTOINCREMENT \x2C roleid INTEGER NOT NULL \x2C resource TEXT NOT NULL \x2C rightid INTEGER NOT NULL \x2C deny BOOLEAN NOT NULL DEFAULT FALSE \x2C FOREIGN KEY(roleid) REFERENCES roles(rowid) \x2C FOREIGN KEY(rightid) REFERENCES rights(rowid) \x2C UNIQUE(roleid \x2C resource \x2C rightid) \x2C CHECK(resource !\x3D \'\'));", Scope = Private
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
