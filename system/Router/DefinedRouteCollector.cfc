<!---
 * Collect all defined routes for display.
 *
 * Difference: HTTP_METHODS is a property here (it is a constant of the
 * Router in the original), and a handler is always a string, because a
 * closure cannot be stored, so there is no (Closure) or (View) handler.
--->
<cfcomponent output="no" hint="Collect all defined routes for display">

	<cfset this.HTTP_METHODS = ArrayNew(1)>
	<cfset ArrayAppend(this.HTTP_METHODS, "GET")>
	<cfset ArrayAppend(this.HTTP_METHODS, "HEAD")>
	<cfset ArrayAppend(this.HTTP_METHODS, "POST")>
	<cfset ArrayAppend(this.HTTP_METHODS, "PATCH")>
	<cfset ArrayAppend(this.HTTP_METHODS, "PUT")>
	<cfset ArrayAppend(this.HTTP_METHODS, "DELETE")>
	<cfset ArrayAppend(this.HTTP_METHODS, "OPTIONS")>
	<cfset ArrayAppend(this.HTTP_METHODS, "TRACE")>
	<cfset ArrayAppend(this.HTTP_METHODS, "CONNECT")>
	<cfset ArrayAppend(this.HTTP_METHODS, "CLI")>

	<cfset this.routeCollection = "">

	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="routeCollection" type="any" required="yes">

		<cfset this.routeCollection = arguments.routeCollection>

		<cfreturn this>
	</cffunction>

	<!---
	 * @return A list of maps with the keys method, route, name and handler
	--->
	<cffunction name="collect" access="public" returntype="any" output="no">
		<cfset var result = ArrayNew(1)>
		<cfset var methods = this.HTTP_METHODS>
		<cfset var routes = "">
		<cfset var options = "">
		<cfset var it = "">
		<cfset var route = "">
		<cfset var handler = "">
		<cfset var routeName = "">
		<cfset var m = 0>

		<cfloop from="1" to="#ArrayLen(methods)#" index="m">
			<cfset routes = this.routeCollection.getRoutes(methods[m])>
			<cfset it = routes.keySet().iterator()>

			<cfloop condition="it.hasNext()">
				<cfset route = it.next() & "">
				<cfset handler = routes.get(route)>

				<cfif IsSimpleValue(handler)>
					<cfset options = this.routeCollection.getRoutesOptions(route, methods[m])>
					<cfset routeName = route>
					<cfif StructKeyExists(options, "as")>
						<cfset routeName = options["as"]>
					</cfif>

					<cfset ArrayAppend(result, array_(
						"method", methods[m],
						"route", route,
						"name", routeName,
						"handler", handler
					))>
				</cfif>
			</cfloop>
		</cfloop>

		<cfreturn result>
	</cffunction>

</cfcomponent>
