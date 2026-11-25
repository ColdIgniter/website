<!---
 * Number language settings
 *
 * A language file is included by the Language component, and has to
 * set the variable "lines" to a map (see array_()); that stands in for
 * the "return [...]" of the original. The keys keep their order.
--->
<cfset lines = array_()>

<cfset lines["terabyteAbbr"] = "TB">
<cfset lines["gigabyteAbbr"] = "GB">
<cfset lines["megabyteAbbr"] = "MB">
<cfset lines["kilobyteAbbr"] = "KB">
<cfset lines["bytes"] = "Bytes">

<!--- don't forget the space in front of these! --->
<cfset lines["thousand"] = " thousand">
<cfset lines["million"] = " million">
<cfset lines["billion"] = " billion">
<cfset lines["trillion"] = " trillion">
<cfset lines["quadrillion"] = " quadrillion">
