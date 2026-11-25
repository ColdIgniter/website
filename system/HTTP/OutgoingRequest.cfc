<!---
 * Representation of an outgoing, client-side request.
 *
 * Not ported yet: the constructor, withMethod and withUri.
--->
<cfcomponent output="no" extends="Message" hint="Representation of an outgoing, client-side request">

	<!---
	 * Request method.
	--->
	<cfset this.method = "">

	<!---
	 * A URI instance.
	--->
	<cfset this.uri = "">

	<!---
	 * Retrieves the HTTP method of the request.
	 *
	 * @return Returns the request method (always uppercase)
	--->
	<cffunction name="getMethod" access="public" returntype="string" output="no">
		<cfreturn this.method>
	</cffunction>

	<!---
	 * Retrieves the URI instance.
	 *
	 * @return Returns a URI instance representing the URI of the request
	--->
	<cffunction name="getUri" access="public" returntype="any" output="no">
		<cfreturn this.uri>
	</cffunction>

</cfcomponent>
