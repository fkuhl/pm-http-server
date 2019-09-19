# pm-http-server

Attempt at an HTTP server for Peri Meleon, using SwiftNIO and a bit of Vapor.

Server expects basic HTTP messages with JSON bodies.
The HTTP method is ignored.
The URL specifies the operation.
The operand, if any, is in JSON; operand varies by operation.

The response is JSON. If the HTTP status return is anything but OK, the response takes for form:
{"error": <string from bowels of the applicatiopn>, "response": <string that might tell you something>  }
If the HTTP status is OK, the response will be JSON whose form depends on the operation.

## URL = "/member/create"
request is Member minus ID
response is Member with ID

## URL = "/member/read"
request is {"id":<id of Member to read>}
response is Member or  NOTFOUND

## URL = "/member/readAll"
request is {} (needs to be not just nothing )
response is (possibly empty) array of Member

## URL = "/member/update"
request is updated Member with ID
response is NOTFOUND if ID not found, or updated Member

## URL = "/member/delete"
request is  {"id":<id of Member to delete>}
response is NOTFOUND if ID not found, or deleted Member

