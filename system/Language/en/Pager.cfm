<!---
 * Pager language settings
 *
 * A language file is included by the Language component, and has to
 * set the variable "lines" to a map (see array_()); that stands in for
 * the "return [...]" of the original. The keys keep their order.
--->
<cfset lines = array_()>

<cfset lines["pageNavigation"] = "Page navigation">
<cfset lines["first"] = "First">
<cfset lines["previous"] = "Previous">
<cfset lines["next"] = "Next">
<cfset lines["last"] = "Last">
<cfset lines["older"] = "Older">
<cfset lines["newer"] = "Newer">
<cfset lines["invalidTemplate"] = """{0}"" is not a valid Pager template.">
<cfset lines["invalidPaginationGroup"] = """{0}"" is not a valid Pagination group.">
