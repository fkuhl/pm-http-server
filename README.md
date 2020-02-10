# pm-http-server

Attempt at an HTTP server for Peri Meleon, using SwiftNIO and a bit of Vapor.

Server expects basic HTTP messages with JSON bodies.
The HTTP method is ignored.
The URL specifies the operation.
The operand, if any, is in JSON; operand varies by operation.

The response is JSON. If the HTTP status return is anything but OK, the response takes the form:
{"error": <string from bowels of the applicatiopn>, "response": <string that might tell you something>  }
If the HTTP status is OK, the response will be JSON whose form depends on the operation.

## URL = "/Members/create"
method POST
request body is Member minus ID (MemberValue), 
response is ID

## URL = "/Members/read"
query parameter: id. So URL looks like "/Members/read?id=123456789abcdef"
method GET
request body is empty
response is Member or  NOTFOUND

## URL = "/Members/readAll"
method GET
request body is empty
response is (possibly empty) array of Member

## URL = "/Members/update"
method POST
request: Member, consisting of ID and MemberValue
response is NOTFOUND if ID not found, or updated Member

## URL = "/Members/delete"
method DELETE
query parameter: id. So URL looks like "/Members/delete?id=123456789abcdef"
request body is empty
response is NOTFOUND if ID not found, or ID of deleted Member
_THIS DOES NOT HANDLE REFERENCES!_
That is, references to the Member in Household aren't cleaned up by this step.

## URL = "/Members/drop"
method POST
request body is empty
response is mere happiness

## For the other document types, replace "Members" with "Households" or "Addresses"
