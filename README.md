# fswebapi
## Filesystem access & manipulation via an extension of the HTTP protocol

### There are two things of interest in this application:
+ The application itself, doing what it does
+ The ipservercore: a library for use in a threaded web server for building web APIs

### The fswebapi application
As the name suggests, this is a service application implementing a web API to access and manipulate filesystem objects on a specified path.
Most of the methods are standard HTTP, but there are a few that are not.

There are two endpoints, one for files and one for folders. You can see below a table for the methods implemented for each.

| Endpoint   |   Method     | URL parameters required |  Description  |
| ---------- | ------------ | ----------------------- | ------------- |
| /files/{full path to file} | GET | none | Download the file |
| /files/{full path to file} | POST | none | Upload a file if not already exists |
| /files/{full path to file} | PUT | none | Upload a file, overwrite if exists |
| /files/{full path to file} | DELETE | none | Delete the file |
| /files/{full path to file} | RENAME | **newname** | Rename the file to *newname* value |
| /folders/{full path to folder} | POST | none | Create the folder |
| /folders/{full path to folder} | LIST | none | Receive a tab-delimited list of the folder contents |
| /folders/{full path to folder} | DELETE | none | Delete the folder if empty |
| /folders/{full path to folder} | RENAME | **newname** | Rename the folder to *newname* value |
