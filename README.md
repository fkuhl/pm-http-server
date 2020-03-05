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
Cannot create separate Member, only as part of a Household.
response is BADREQUEST

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
request: Member
response is NOTFOUND if ID not found; or OK and updated Member
*NOTE:* The update is not allowed to change the Member's Household!

## URL = "/Members/drop"
Cannot drop Members. 
response is BADREQUEST

## URL = "/Households/create"
method POST
request: HouseholdDocument object with blank id
response: new document ID

## URL = "/Households/read"
query parameter: id. So URL looks like "/Members/read?id=123456789abcdef"
method GET
request body is empty
response is HouseholdDocument or  NOTFOUND

## URL = "/Households/readAll"
method GET
request body is empty
response is (possibly empty) array of HouseholdDocument

## URL = "/Households/update"
method POST
request: HouseholdDocument
response is NOTFOUND if ID not found; or OK or updated HouseholdDocument

## URL = "/Households/drop"
method POST
request: empty (ignored)
response is OK
