<!---
 * Security language settings
 *
 * A language file is included by the Language component, and has to
 * set the variable "lines" to a map (see array_()); that stands in for
 * the "return [...]" of the original. The keys keep their order.
--->
<cfset lines = array_()>

<cfset lines["disallowedAction"] = "The action you requested is not allowed.">
<cfset lines["insecureCookie"] = "Attempted to send a secure cookie over a non-secure connection.">
<cfset lines["invalidSameSite"] = "The SameSite value must be None, Lax, Strict, or a blank string. Given: ""{0}""">
