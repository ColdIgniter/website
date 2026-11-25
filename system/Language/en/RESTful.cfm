<!---
 * RESTful language settings
 *
 * A language file is included by the Language component, and has to
 * set the variable "lines" to a map (see array_()); that stands in for
 * the "return [...]" of the original. The keys keep their order.
 *
 * Only the lines of the pagination are used so far (by ResponseTrait).
--->
<cfset lines = array_()>

<cfset lines["notImplemented"] = """{0}"" action not implemented.">
<cfset lines["cannotPaginate"] = "Unable to retrieve paginated data.">
<cfset lines["paginateError"] = "An error occurred while paginating results.">
