<!---
 * HTTP Method List
 *
 * The constants are properties of the object that static_() returns.
--->
<cfcomponent output="no" hint="HTTP Method List">

	<!---
	 * Safe: No
	 * Idempotent: No
	 * Cacheable: No
	 *
	 * @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/CONNECT
	--->
	<cfset this.CONNECT = "CONNECT">

	<!---
	 * Safe: No
	 * Idempotent: Yes
	 * Cacheable: No
	 *
	 * @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/DELETE
	--->
	<cfset this.DELETE = "DELETE">

	<!---
	 * Safe: Yes
	 * Idempotent: Yes
	 * Cacheable: Yes
	 *
	 * @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/GET
	--->
	<cfset this.GET = "GET">

	<!---
	 * Safe: Yes
	 * Idempotent: Yes
	 * Cacheable: Yes
	 *
	 * @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/HEAD
	--->
	<cfset this.HEAD = "HEAD">

	<!---
	 * Safe: Yes
	 * Idempotent: Yes
	 * Cacheable: No
	 *
	 * @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/OPTIONS
	--->
	<cfset this.OPTIONS = "OPTIONS">

	<!---
	 * Safe: No
	 * Idempotent: No
	 * Cacheable: Only if freshness information is included
	 *
	 * @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/PATCH
	--->
	<cfset this.PATCH = "PATCH">

	<!---
	 * Safe: No
	 * Idempotent: No
	 * Cacheable: Only if freshness information is included
	 *
	 * @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/POST
	--->
	<cfset this.POST = "POST">

	<!---
	 * Safe: No
	 * Idempotent: Yes
	 * Cacheable: No
	 *
	 * @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/PUT
	--->
	<cfset this.PUT = "PUT">

	<!---
	 * Safe: Yes
	 * Idempotent: Yes
	 * Cacheable: No
	 *
	 * @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/TRACE
	--->
	<cfset this.TRACE = "TRACE">

	<!---
	 * Returns all HTTP methods.
	 *
	 * @return list of uppercase strings
	--->
	<cffunction name="all" access="public" returntype="array" output="no">
		<cfset var methods = ArrayNew(1)>

		<cfset ArrayAppend(methods, this.CONNECT)>
		<cfset ArrayAppend(methods, this.DELETE)>
		<cfset ArrayAppend(methods, this.GET)>
		<cfset ArrayAppend(methods, this.HEAD)>
		<cfset ArrayAppend(methods, this.OPTIONS)>
		<cfset ArrayAppend(methods, this.PATCH)>
		<cfset ArrayAppend(methods, this.POST)>
		<cfset ArrayAppend(methods, this.PUT)>
		<cfset ArrayAppend(methods, this.TRACE)>

		<cfreturn methods>
	</cffunction>

</cfcomponent>
