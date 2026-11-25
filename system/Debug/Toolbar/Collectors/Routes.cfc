<!---
 * Routes collector
 *
 * Not ported yet: the names and default values of the parameters of the
 * controller method (there is no reflection), so each parameter is shown as
 * $paramN with the value that was given. The routes that are closures do
 * not exist, as a closure cannot be stored.
--->
<cfcomponent output="no" extends="BaseCollector" hint="Routes collector">

	<!---
	 * Whether this collector has data that can
	 * be displayed in the Timeline.
	--->
	<cfset this.hasTimeline = false>

	<!---
	 * Whether this collector needs to display
	 * content in a tab or not.
	--->
	<cfset this.hasTabContent = true>

	<!---
	 * The 'title' of this Collector.
	 * Used to name things in the toolbar HTML.
	--->
	<cfset this.title = "Routes">

	<!---
	 * Returns the data of this collector to be formatted in the toolbar
	 *
	 * @return A map with the keys matchedRoute (a list of maps with the keys
	 *         directory, controller, method, paramCount, truePCount and params)
	 *         and routes (a list of maps with the keys method, route and handler)
	--->
	<cffunction name="display" access="public" returntype="any" output="no">
		<cfset var rawRoutes = service("routes", true)>
		<cfset var router = service("router", "", "", true)>
		<cfset var routerParams = router.params()>
		<cfset var params = ArrayNew(1)>
		<cfset var matchedRoute = ArrayNew(1)>
		<cfset var routes = ArrayNew(1)>
		<cfset var definedRouteCollector = "">
		<cfset var defined = "">
		<cfset var route = "">
		<cfset var i = 0>

		<!--- If we're here, page cache is returned. The router is not executed. --->
		<cfif NOT IsSimpleValue(router.controllerName()) OR router.controllerName() EQ "">
			<cfreturn array_("matchedRoute", ArrayNew(1), "routes", ArrayNew(1))>
		</cfif>

		<cfloop from="1" to="#ArrayLen(routerParams)#" index="i">
			<cfset ArrayAppend(params, array_(
				"name", "$param" & i & " = ",
				"value", routerParams[i]
			))>
		</cfloop>

		<cfset ArrayAppend(matchedRoute, array_(
			"directory", router.directory(),
			"controller", router.controllerName(),
			"method", router.methodName(),
			"paramCount", ArrayLen(routerParams),
			"truePCount", ArrayLen(params),
			"params", params
		))>

		<!--- Defined Routes --->
		<cfset definedRouteCollector = new_("ColdIgniter\Router\DefinedRouteCollector", rawRoutes)>
		<cfset defined = definedRouteCollector.collect()>

		<cfloop from="1" to="#ArrayLen(defined)#" index="i">
			<cfset route = defined[i]>

			<!--- filter for strings, as callbacks aren't displayable --->
			<cfif Compare(route["handler"], "(Closure)") NEQ 0>
				<cfset ArrayAppend(routes, array_(
					"method", UCase(route["method"]),
					"route", route["route"],
					"handler", route["handler"]
				))>
			</cfif>
		</cfloop>

		<cfreturn array_("matchedRoute", matchedRoute, "routes", routes)>
	</cffunction>

	<!---
	 * Returns a count of all the routes in the system.
	--->
	<cffunction name="getBadgeValue" access="public" returntype="any" output="no">
		<cfset var rawRoutes = service("routes", true)>

		<cfreturn rawRoutes.getRoutes().size()>
	</cffunction>

	<!---
	 * Display the icon.
	 *
	 * Icon from https://icons8.com - 1em package
	--->
	<cffunction name="icon" access="public" returntype="string" output="no">
		<cfreturn "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAFDSURBVEhL7ZRNSsNQFIUjVXSiOFEcuQIHDpzpxC0IGYeE/BEInbWlCHEDLsSiuANdhKDjgm6ggtSJ+l25ldrmmTwIgtgDh/t37r1J+16cX0dRFMtpmu5pWAkrvYjjOB7AETzStBFW+inxu3KUJMmhludQpoflS1zXban4LYqiO224h6VLTHr8Z+z8EpIHFF9gG78nDVmW7UgTHKjsCyY98QP+pcq+g8Ku2s8G8X3f3/I8b038WZTp+bO38zxfFd+I6YY6sNUvFlSDk9CRhiAI1jX1I9Cfw7GG1UB8LAuwbU0ZwQnbRDeEN5qqBxZMLtE1ti9LtbREnMIuOXnyIf5rGIb7Wq8HmlZgwYBH7ORTcKH5E4mpjeGt9fBZcHE2GCQ3Vt7oTNPNg+FXLHnSsHkw/FR+Gg2bB8Ptzrst/v6C/wrH+QB+duli6MYJdQAAAABJRU5ErkJggg==">
	</cffunction>

</cfcomponent>
