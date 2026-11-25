<!---
 * Request router.
 *
 * Not ported yet: auto-routing, closures as handlers, redirect routes,
 * the {locale} placeholder, route attributes.
--->
<cfcomponent output="no" hint="Request router">

	<!---
	 * A RouteCollection instance.
	--->
	<cfset this.collection = "">

	<!---
	 * Sub-directory that contains the requested controller class.
	 * Primarily used by 'autoroute'.
	 *
	 * Named with an underscore, because directory() is a method.
	--->
	<cfset this.directory_ = "">

	<!---
	 * The name of the controller class.
	--->
	<cfset this.controller = "">

	<!---
	 * The name of the method to use.
	--->
	<cfset this.method = "">

	<!---
	 * An array of binds that were collected
	 * so they can be sent to closure routes.
	 *
	 * Named with an underscore, because params() is a method.
	--->
	<cfset this.params_ = ArrayNew(1)>

	<!---
	 * The name of the front controller.
	--->
	<cfset this.indexPage = "index.cfm">

	<!---
	 * Whether dashes in URI's should be converted
	 * to underscores when determining method names.
	--->
	<cfset this.translateURIDashes = false>

	<!---
	 * The route that was matched for this request.
	--->
	<cfset this.matchedRoute = "">

	<!---
	 * The options set for the matched route.
	--->
	<cfset this.matchedRouteOptions = "">

	<!---
	 * The locale that was detected in a route.
	--->
	<cfset this.detectedLocale = "">

	<!---
	 * The filter info from Route Collection
	 * if the matched route should be filtered.
	--->
	<cfset this.filtersInfo = ArrayNew(1)>

	<!---
	 * Permitted URI chars
	 *
	 * The default value is `''` (do not check) for backward compatibility.
	--->
	<cfset this.permittedURIChars = "">

	<!---
	 * Stores a reference to the RouteCollection object.
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="routes" type="any" required="yes">
		<cfargument name="request_" type="any" required="no" default="">
		<cfset var config = variables.config("Config\App")>

		<cfset this.permittedURIChars = config.permittedURIChars>

		<cfset this.collection = arguments.routes>

		<!--- These are only for auto-routing --->
		<cfset this.controller = this.collection.getDefaultController()>
		<cfset this.method = this.collection.getDefaultMethod()>

		<cfif arguments.request_.getMethod() EQ "">
			<cfset this.collection.setHTTPVerb(service("superglobals").server("REQUEST_METHOD"))>
		<cfelse>
			<cfset this.collection.setHTTPVerb(arguments.request_.getMethod())>
		</cfif>

		<cfset this.translateURIDashes = this.collection.shouldTranslateURIDashes()>

		<!--- Not ported yet: the auto router --->

		<cfreturn this>
	</cffunction>

	<!---
	 * Finds the controller corresponding to the URI.
	 *
	 * @param uri URI path relative to baseURL
	 *
	 * @return Controller classname
	--->
	<cffunction name="handle" access="public" returntype="any" output="no">
		<cfargument name="uri" type="string" required="no" default="">

		<!--- If we cannot find a URI to match against, then set it to root (`/`). --->
		<cfif arguments.uri EQ "">
			<cfset arguments.uri = "/">
		</cfif>

		<!--- Decode URL-encoded string --->
		<cfset arguments.uri = URLDecode(arguments.uri)>

		<cfset checkDisallowedChars(arguments.uri)>

		<!--- Restart filterInfo --->
		<cfset this.filtersInfo = ArrayNew(1)>

		<!--- Checks defined routes --->
		<cfif checkRoutes(arguments.uri)>
			<cfif this.collection.isFiltered(this.matchedRoute[1])>
				<cfset this.filtersInfo = this.collection.getFiltersForRoute(this.matchedRoute[1])>
			</cfif>

			<!--- Not ported yet: route attributes --->

			<cfreturn this.controller>
		</cfif>

		<!---
		 Still here? Then we can try to match the URI against
		 Controllers/directories, but the application may not
		 want this, like in the case of API's.
		--->
		<cfif NOT this.collection.shouldAutoRoute()>
			<cfthrow type="ColdIgniter.Exceptions.PageNotFoundException" errorcode="404" message="Can't find a route for '#this.collection.getHTTPVerb()#: #arguments.uri#'.">
		</cfif>

		<!--- Not ported yet: auto routes --->
		<cfthrow type="ColdIgniter.Exceptions.PageNotFoundException" errorcode="404" message="Can't find a route for '#this.collection.getHTTPVerb()#: #arguments.uri#'.">
	</cffunction>

	<!---
	 * Returns the filter info for the matched route, if any.
	--->
	<cffunction name="getFilters" access="public" returntype="array" output="no">
		<cfreturn this.filtersInfo>
	</cffunction>

	<!---
	 * Returns the name of the matched controller or closure.
	 *
	 * @return Controller classname
	--->
	<cffunction name="controllerName" access="public" returntype="any" output="no">
		<cfif this.translateURIDashes>
			<cfreturn Replace(this.controller, "-", "_", "all")>
		</cfif>

		<cfreturn this.controller>
	</cffunction>

	<!---
	 * Returns the name of the method in the controller to run.
	--->
	<cffunction name="methodName" access="public" returntype="string" output="no">
		<cfif this.translateURIDashes>
			<cfreturn Replace(this.method, "-", "_", "all")>
		</cfif>

		<cfreturn this.method>
	</cffunction>

	<!---
	 * Returns the 404 Override settings from the Collection.
	 * If the override is a string, will split to controller/index array.
	 *
	 * @return An array of controller and method, or an empty string if there is no override
	--->
	<cffunction name="get404Override" access="public" returntype="any" output="no">
		<cfset var route = this.collection.get404Override()>
		<cfset var routeArray = "">
		<cfset var result = ArrayNew(1)>

		<cfif IsSimpleValue(route) AND route NEQ "">
			<cfset routeArray = explode("::", route)>

			<cfset ArrayAppend(result, routeArray[1])> <!--- Controller --->
			<cfif ArrayLen(routeArray) GT 1>
				<cfset ArrayAppend(result, routeArray[2])> <!--- Method --->
			<cfelse>
				<cfset ArrayAppend(result, "index")>
			</cfif>

			<cfreturn result>
		</cfif>

		<cfreturn "">
	</cffunction>

	<!---
	 * Returns the binds that have been matched and collected
	 * during the parsing process as an array, ready to send to
	 * instance.method(...params).
	--->
	<cffunction name="params" access="public" returntype="array" output="no">
		<cfreturn this.params_>
	</cffunction>

	<!---
	 * Returns the name of the sub-directory the controller is in,
	 * if any. Relative to APPPATH.'Controllers'.
	 *
	 * Only used when auto-routing is turned on.
	--->
	<cffunction name="directory" access="public" returntype="string" output="no">
		<cfreturn "">
	</cffunction>

	<!---
	 * Returns the routing information that was matched for this
	 * request, if a route was defined.
	 *
	 * @return An array of route key and handler, or an empty string
	--->
	<cffunction name="getMatchedRoute" access="public" returntype="any" output="no">
		<cfreturn this.matchedRoute>
	</cffunction>

	<!---
	 * Returns all options set for the matched route
	--->
	<cffunction name="getMatchedRouteOptions" access="public" returntype="any" output="no">
		<cfreturn this.matchedRouteOptions>
	</cffunction>

	<!---
	 * Sets the value that should be used to match the index.cfm file. Defaults
	 * to index.cfm but this allows you to modify it in case you are using
	 * something like mod_rewrite to remove the page. This allows you to set
	 * it a blank.
	--->
	<cffunction name="setIndexPage" access="public" returntype="any" output="no">
		<cfargument name="page" type="string" required="yes">

		<cfset this.indexPage = arguments.page>

		<cfreturn this>
	</cffunction>

	<!---
	 * Returns true/false based on whether the current route contained
	 * a {locale} placeholder.
	--->
	<cffunction name="hasLocale" access="public" returntype="boolean" output="no">
		<cfreturn this.detectedLocale NEQ "">
	</cffunction>

	<!---
	 * Returns the detected locale, if any, or an empty string.
	--->
	<cffunction name="getLocale_" access="public" returntype="string" output="no">
		<cfreturn this.detectedLocale>
	</cffunction>

	<!---
	 * Checks Defined Routes.
	 *
	 * Compares the uri string against the routes that the
	 * RouteCollection class defined for us, attempting to find a match.
	 * This method will modify this.controller, etal as needed.
	 *
	 * @param uri The URI path to compare against the routes
	 *
	 * @return Whether the route was matched or not.
	--->
	<cffunction name="checkRoutes" access="private" returntype="boolean" output="no">
		<cfargument name="uri" type="string" required="yes">
		<cfset var routes = this.collection.getRoutes(this.collection.getHTTPVerb())>
		<cfset var key = "">
		<cfset var routeKey = "">
		<cfset var matchedKey = "">
		<cfset var handler = "">
		<cfset var matcher = "">
		<cfset var controller = "">
		<cfset var methodAndParams = "">
		<cfset var segments = "">

		<!--- Don't waste any time --->
		<cfif StructCount(routes) EQ 0>
			<cfreturn false>
		</cfif>

		<cfif arguments.uri NEQ "/">
			<cfset arguments.uri = trim_(arguments.uri, "/ ")>
		</cfif>

		<!--- Loop through the route array looking for wildcards --->
		<cfloop collection="#routes#" item="key">
			<cfset handler = routes[key]>

			<cfif key EQ "/">
				<cfset routeKey = key>
			<cfelse>
				<!---
				 routeKey may be int, because it is an array key,
				 and the URI `/1` is valid. The leading `/` is removed.
				--->
				<cfset routeKey = REReplace(key, "^[/ ]+", "")>
			</cfif>

			<cfset matchedKey = routeKey>

			<!--- Not ported yet: {locale} --->

			<!--- Does the RegEx match? --->
			<cfset regex_guard_(arguments.uri)>
			<cfset matcher = CreateObject("java", "java.util.regex.Pattern").compile("^" & routeKey & "$").matcher(arguments.uri)>
			<cfif matcher.matches()>
				<!--- Not ported yet: redirect routes, closures --->

				<cfif Find("::", handler) GT 0>
					<cfset segments = explode("::", handler)>
					<cfset controller = segments[1]>
					<cfset methodAndParams = segments[2]>
				<cfelse>
					<cfset controller = handler>
					<cfset methodAndParams = "">
				</cfif>

				<!--- Checks `/` in controller name --->
				<cfif Find("/", controller) GT 0>
					<cfthrow type="ColdIgniter.Router.Exceptions.RouterException" message="The namespace delimiter is a backslash (\), not a slash (/). Route handler: ""#handler#""">
				</cfif>

				<cfif Find("$", handler) GT 0 AND Find("(", routeKey) GT 0>
					<!--- Checks dynamic controller --->
					<cfif Find("$", controller) GT 0>
						<cfthrow type="ColdIgniter.Router.Exceptions.RouterException" message="A dynamic controller is not allowed for security reasons. Route handler: ""#handler#""">
					</cfif>

					<!--- Not ported yet: multipleSegmentsOneParam --->

					<!--- Using back-references --->
					<cfset segments = explode("/", matcher.replaceAll(Replace(handler, "\", "\\", "all")))>
				<cfelse>
					<cfset segments = explode("/", handler)>
				</cfif>

				<cfset setRequest(segments)>

				<cfset setMatchedRoute(matchedKey, handler)>

				<cfreturn true>
			</cfif>
		</cfloop>

		<cfreturn false>
	</cffunction>

	<!---
	 * Set request route
	 *
	 * Takes an array of URI segments as input and sets the class/method
	 * to be called.
	 *
	 * @param segments URI segments
	--->
	<cffunction name="setRequest" access="private" returntype="void" output="no">
		<cfargument name="segments" type="array" required="no" default="#ArrayNew(1)#">
		<cfset var parts = "">
		<cfset var params = ArrayNew(1)>
		<cfset var i = 0>

		<!--- If we don't have any segments - use the default controller; --->
		<cfif ArrayLen(arguments.segments) EQ 0>
			<cfreturn>
		</cfif>

		<cfset parts = explode("::", arguments.segments[1], 2)>

		<cfset this.controller = parts[1]>

		<!---
		 this.method already contains the default method name,
		 so don't overwrite it with emptiness.
		--->
		<cfif ArrayLen(parts) GT 1 AND parts[2] NEQ "">
			<cfset this.method = parts[2]>
		</cfif>

		<!--- array_shift: the array is not changed in place, the rest is copied --->
		<cfloop from="2" to="#ArrayLen(arguments.segments)#" index="i">
			<cfset ArrayAppend(params, arguments.segments[i])>
		</cfloop>

		<cfset this.params_ = params>
	</cffunction>

	<!---
	 * @param handler Handler
	--->
	<cffunction name="setMatchedRoute" access="private" returntype="void" output="no">
		<cfargument name="route" type="string" required="yes">
		<cfargument name="handler" type="any" required="yes">

		<cfset this.matchedRoute = ArrayNew(1)>
		<cfset ArrayAppend(this.matchedRoute, arguments.route)>
		<cfset ArrayAppend(this.matchedRoute, arguments.handler)>

		<cfset this.matchedRouteOptions = this.collection.getRoutesOptions(arguments.route)>
	</cffunction>

	<!---
	 * Checks disallowed characters
	--->
	<cffunction name="checkDisallowedChars" access="private" returntype="void" output="no">
		<cfargument name="uri" type="string" required="yes">
		<cfset var segments = explode("/", arguments.uri)>
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(segments)#" index="i">
			<cfif segments[i] NEQ "" AND this.permittedURIChars NEQ ""
				AND NOT CreateObject("java", "java.util.regex.Pattern").matches("(?i)\A[" & this.permittedURIChars & "]+\z", segments[i])>
				<cfthrow type="ColdIgniter.HTTP.Exceptions.BadRequestException" errorcode="400" message="The URI you submitted has disallowed characters: ""#segments[i]#""">
			</cfif>
		</cfloop>
	</cffunction>

</cfcomponent>
