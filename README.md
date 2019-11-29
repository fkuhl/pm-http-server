# pm-http-server

Attempt at an HTTP server for Peri Meleon, using SwiftNIO and a bit of Vapor.

Server expects basic HTTP messages with JSON bodies.
The HTTP method is ignored.
The URL specifies the operation.
The operand, if any, is in JSON; operand varies by operation.

The response is JSON. If the HTTP status return is anything but OK, the response takes the form:
{"error": <string from bowels of the applicatiopn>, "response": <string that might tell you something>  }
If the HTTP status is OK, the response will be JSON whose form depends on the operation.

## URL = "/member/create"
request is Member minus ID
response is ID

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
response is NOTFOUND if ID not found, or ID of deleted Member
_THIS DOES NOT HANDLE REFERENCES!_

## URL = "/member/drop"
request is  {} (needs to be not just nothing )
response is mere happiness

## On return:
1. Cut down Member to match the fields in pm-http-client and test current version with client.
2. Create generic version of MemberProcessor.
3. Generalize MemberProcessor to handle Households and Addresses.
4. Begin building test client with UI.
