<!---
 * Honeypot language settings
 *
 * A language file is included by the Language component, and has to
 * set the variable "lines" to a map (see array_()); that stands in for
 * the "return [...]" of the original. The keys keep their order.
--->
<cfset lines = array_()>

<cfset lines["noTemplate"] = "The HTML template for the Honeypot is not configured.">
<cfset lines["noNameField"] = "The name of the Honeypot field is not set.">
<cfset lines["theClientIsABot"] = "The Honeypot client may be a bot.">
