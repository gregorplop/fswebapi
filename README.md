# fswebapi
#### Filesystem access & manipulation via an extension of the HTTP protocol

![Status screen](https://raw.githubusercontent.com/gregorplop/fswebapi/main/screenshots/status1.png)

## There are two things of interest in this project:

+ The application itself, doing what it does
+ The ipservercore: a library for use in a threaded web server for building web APIs

## The fswebapi application
As the name suggests, this is a service application implementing a web API to access and manipulate filesystem objects on a specified path.
Most methods are standard HTTP, but there are a few that are not.

There are two main endpoints, one for files and one for folders. There is an additional one for viewing the internal state of the application.
You can see below a table for the methods implemented for each.

| Endpoint   |   Method     | URL parameters required |  Description  |
| ---------- | ------------ | ----------------------- | ------------- |
| /files/{path to file} | GET | none | Download the file |
| /files/{path to file} | POST | none | Upload a file if not already exists |
| /files/{path to file} | PUT | none | Upload a file, overwrite if exists |
| /files/{path to file} | DELETE | none | Delete the file |
| /files/{path to file} | RENAME | **newname** | Rename the file to *newname* value |
| /files/{path to file} | APPEND | **appendeol** | Appends payload to file. Optionally adds EOL at the end, as dictated by the *appendeol* parameter: [native , windows , macos , unix] |
| /files/{path to file} | INFO | none | Returns a JSON list with file information |
| /folders/{path to folder} | POST | none | Create the folder |
| /folders/{path to folder} | LIST | none | Receive a tab-delimited list of the folder contents |
| /folders/{path to folder} | DELETE | **deletemode** | Delete the folder. Delete modes are: simple=delete folder if empy(default). recursive=delete all contents, recursively. clear=delete contents recursively, but leave folder |
| /folders/{path to folder} | RENAME | **newname** | Rename the folder to *newname* value |
| /introspection/opensockets | GET | none | Returns a list of open sockets at the time of execution |

### Server command line parameters
Minimally, the application needs to know two things: the root folder that's going to make accessible and the port it's going to be listening to. Optionally, it can be put in verbose (or debug) mode, printing messages when internal events occur.  
There are additional options for enabling SSL support.

| Parameter | Mandatory | Description |
| ------- | --------| -------- |
| --rootfolder={absolute folder path} | Yes | Makes anything /files or /folders refer to, relative to this folder |
| --port={port number} | Yes | Server listens to this port |
| --debug | No | Verbose mode |
| --sslenable | No | Enables SSL support, requires the key/certificate file to be set |
| --sslcert={absolute path to key/cert file} | Yes if --sslenable has been set | Points to the combined key/certificate file |
| --sslmode={tls1,tls11,tls12} | No | Sets the TLS mode. Default is TLS 1.2 |
| --sslreject={absolute path to SSL Rejection file} | No | Points to the certificate rejection file, if used |
| --sslkeypass={password} | No | If the private key is encrypted, sets the decryption password. Plaintext value! |

### Examples
For a server that has started with the following parameters:  --rootfolder=C:\Shared --port=8080   
...running a GET on */files/subfolder1/subfolder2/file.txt* will download the file located at C:\Shared\subfolder1\subfolder2\file.txt   
...running a RENAME on */files/sample.zip?newname=newsample.zip* will rename the file C:\Shared\sample.zip to newsample.zip

### SSL Support
There is support for HTTPS requests. Minimally, you enable it with the --sselenable parameter, having set the location of a combined key/certificate file.
This file should contain both the key and the certificate in the following order:

> -----BEGIN RSA PRIVATE KEY-----  
> ...Certificate Data Here...  
> -----END RSA PRIVATE KEY-----  
>  
> -----BEGIN CERTIFICATE-----  
> ...Certificate Data Here...  
> -----END CERTIFICATE-----  

### Notable architectural characteristics
+ Each request is processed in its own thread. Code that runs on the main thread has been limited to the absolutely necessary.
+ File upload/download operations do not accumulate the entirety of the file content before doing their read/write to disk. Data is processed immediatelly in chunks, one-stream-to-another, therefore memory overhead always remains low.

### Notices, warnings, todo
At this point, note the following:
+ SSL Support is still not thoroughly tested, there might be some edge cases causing certain requests to fail
+ There is no authentication mechanism implemented
+ The application has only been tested on Windows
+ It is uncertain how the application behaves on unstable connections and heavy simultaneous loads
+ At this moment, root folders containing spaces are not allowed in the --rootfolder parameter

## The ipservercore library
The application is based on an implementation of the HTTP/1.1 protocol from scratch, the ipservercore. There is no reliance on the Xojo Web Framework. This allows for higher performance and more flexibility when implementing a specific application's logic, but at the cost of less-than-airtight abstraction from the underlying protocol.
In this way, the ipservercore library is by no means a framework operating on [the Hollywood principle](https://en.wikipedia.org/wiki/Inversion_of_control) , like the Xojo Web Frameworks 1&2. It is just a template providing a skeleton implementation of HTTPS, around which you can build your application's business logic. A similar (but more elaborate) effort, was Tim Dietrich's Aloe Express project, which is unfortunately long defunct.

### Main features
+ Each successfully recognized incoming request maintains an open socket and fires up a thread with access to that socket. This is the Worker.
+ The Worker is like an empty canvas for the application developer: She decides how and when the request is going to be parsed and responded to.
+ As a consequence, ipservercore does not force a program flow paradigm: you can do things synchronously or asynchronously if you plan carefully.

**Essentially, the fswebapi application is a playground/tutorial on how to use ipservercore, as well as a testbed on which the library's shortcomings will come to the surface!**    
Ah, and by the way, the ip- in the name, it's not Internet Protocol. It's something else :)

## Contributing
All this is just a test for something bigger to come. As well as work that there was no point in keeping to myself. I'd be more than happy if you:
+ Find your uses for fswebapi.
+ Report bugs that you came across, I'll try to fix them.
+ Suggest improvements, make comments, especially on ipservercore. I'll listen carefully.
+ Fork the project and do whatever you want with it!

