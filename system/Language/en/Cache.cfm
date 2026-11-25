<!---
 * Cache language settings
 *
 * A language file is included by the Language component, and has to
 * set the variable "lines" to a map (see array_()); that stands in for
 * the "return [...]" of the original. The keys keep their order.
--->
<cfset lines = array_()>

<cfset lines["unableToWrite"] = "Cache unable to write to ""{0}"".">
<cfset lines["invalidHandler"] = "Cache driver ""{0}"" is not a valid cache handler.">
<cfset lines["invalidHandlers"] = "Cache config must have an array of $validHandlers.">
<cfset lines["noBackup"] = "Cache config must have a handler and backupHandler set.">
<cfset lines["handlerNotFound"] = "Cache config has an invalid handler or backup handler specified.">
