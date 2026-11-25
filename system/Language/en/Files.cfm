<!---
 * Files language settings
 *
 * A language file is included by the Language component, and has to
 * set the variable "lines" to a map (see array_()); that stands in for
 * the "return [...]" of the original. The keys keep their order.
--->
<cfset lines = array_()>

<cfset lines["fileNotFound"] = "File not found: ""{0}""">
<cfset lines["cannotMove"] = "Could not move file ""{0}"" to ""{1}"". Reason: {2}">
<cfset lines["expectedDirectory"] = "{0} expects a valid directory.">
<cfset lines["expectedFile"] = "{0} expects a valid file.">
