# fswebapi
#### Filesystem access & manipulation via an extension of the HTTP protocol

## There are two things of interest in this project:

+ The application itself, doing what it does
+ The ipservercore: a library for use in a threaded web server for building web APIs

## The fswebapi application
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

#### Server command line parameters
At this point, the application needs to know two things: the root folder that's going to make accessible and the port it's going to be listening to. Optionally, it can be put in verbose (or debug) mode, printing messages when internal events occur.

| Parameter | Mandatory | Description |
| ------- | --------| -------- |
| --rootfolder={absolute folder path} | Yes | Makes anything /files or /folders refer to, relative to this folder |
| --port={port number} | Yes | Server listens to this port |
| --debug | No | Verbose mode |

At this moment, paths with spaces are not allowed.

#### Examples
For a server that has started with the following parameters:  --rootfolder=C:\Shared --port=8080   
...running a GET on */files/subfolder1/subfolder2/file.txt* will download the file located at C:\Shared\subfolder1\subfolder2\file.txt   
...running a RENAME on */files/sample.zip?newname=newsample.zip* will rename the file C:\Shared\sample.zip to newsample.zip

#### Notices, warnings, todo
At this point, note the following:
+ There is no SSL support
+ There is no authentication mechanism implemented
+ The application has only been tested on Windows
+ It is uncertain how the application behaves on unstable connections and heavy simultaneous loads

## The ipservercore library
The application is based on an implementation of the HTTP/1.1 protocol from scratch.

