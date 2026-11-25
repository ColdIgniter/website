<!---
 * Format language settings
 *
 * A language file is included by the Language component, and has to
 * set the variable "lines" to a map (see array_()); that stands in for
 * the "return [...]" of the original. The keys keep their order.
--->
<cfset lines = array_()>

<cfset lines["invalidFormatter"] = """{0}"" is not a valid Formatter class.">
<cfset lines["invalidJSON"] = "Failed to parse JSON string. Error: {0}">
<cfset lines["invalidMime"] = "No Formatter defined for mime type: ""{0}"".">
<cfset lines["invalidXMLValue"] = "Cannot convert the value of type ""{0}"" to a string for XML output.">
<cfset lines["missingExtension"] = "The SimpleXML extension is required to format XML.">
