<!---
 * Handle a redirect response
--->
<cfcomponent output="no" extends="Response" hint="Handle a redirect response">

	<!---
	 * Sets the URI to redirect to and, optionally, the HTTP status code to use.
	 * If no code is provided it will be automatically determined.
	 *
	 * @param uri  The URI path (relative to baseURL) to redirect to
	 * @param code HTTP status code (an empty string stands for null)
	 *
	 * @return this
	--->
	<cffunction name="to" access="public" returntype="any" output="no">
		<cfargument name="uri" type="string" required="yes">
		<cfargument name="code" type="any" required="no" default="">
		<cfargument name="method" type="string" required="no" default="auto">

		<!---
		 If it appears to be a relative URL, then convert to full URL
		 for better security.
		--->
		<cfif Compare(Left(arguments.uri, 4), "http") NEQ 0>
			<cfset arguments.uri = site_url(arguments.uri)>
		</cfif>

		<cfreturn redirect(arguments.uri, arguments.method, arguments.code)>
	</cffunction>

	<!---
	 * Sets the URI to redirect to but as a reverse-routed or named route
	 * instead of a raw URI.
	 *
	 * Not ported yet: RouteCollection::reverseRoute, so the route is
	 * never found.
	 *
	 * @param route  Route name or Controller::method
	 * @param params Array of int|string
	 *
	 * @return this
	 *
	 * @throws HTTPException
	--->
	<cffunction name="route" access="public" returntype="any" output="no">
		<cfargument name="route" type="string" required="yes">
		<cfargument name="params" type="array" required="no" default="#ArrayNew(1)#">
		<cfargument name="code" type="any" required="no" default="">
		<cfargument name="method" type="string" required="no" default="auto">
		<cfset var namedRoute = arguments.route>

		<!--- Not ported yet: service("routes").reverseRoute(route, params) --->
		<cfset arguments.route = false>

		<cfif NOT arguments.route>
			<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" message="The route for ""#namedRoute#"" cannot be found.">
		</cfif>

		<cfreturn redirect(site_url(arguments.route), arguments.method, arguments.code)>
	</cffunction>

	<!---
	 * Helper function to return to previous page.
	 *
	 * Example:
	 *  return redirect()->back();
	 *
	 * @return this
	--->
	<cffunction name="back" access="public" returntype="any" output="no">
		<cfargument name="code" type="any" required="no" default="">
		<cfargument name="method" type="string" required="no" default="auto">

		<!--- Ensure the session is loaded --->
		<cfset service("session")>

		<cfreturn redirect(previous_url(), arguments.method, arguments.code)>
	</cffunction>

	<!---
	 * Sets any old input (the GET and POST data) in the session as flash
	 * data, and the validation errors with it.
	 *
	 * @return this
	--->
	<cffunction name="withInput" access="public" returntype="any" output="no">
		<cfset var sessionObj = service("session")>
		<cfset var superglobals = service("superglobals")>

		<!--- Differs from the original: the maps are copied, since arrays are not copied on assignment here --->
		<cfset sessionObj.setFlashdata("_ci_old_input", array_("get", array_merge(superglobals.getGetArray()), "post", array_merge(superglobals.getPostArray())))>

		<cfset withErrors()>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets validation errors in the session.
	 *
	 * If the validation has any errors, transmit those back
	 * so they can be displayed when the validation is handled
	 * within a method different than displaying the form.
	 *
	 * @return this
	--->
	<cffunction name="withErrors" access="private" returntype="any" output="no">
		<cfset var validation = service("validation")>
		<cfset var errors = validation.getErrors()>

		<cfif StructCount(errors) GT 0>
			<cfset service("session").setFlashdata("_ci_validation_errors", errors)>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a key and message to the session as Flashdata.
	 *
	 * @param message A string, or a map
	 *
	 * @return this
	--->
	<cffunction name="with" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="message" type="any" required="yes">

		<cfset service("session").setFlashdata(arguments.key, arguments.message)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Copies any cookies from the global Response instance
	 * into this RedirectResponse. Useful when you've just
	 * set a cookie but need ensure that's actually sent
	 * with the response instead of lost.
	 *
	 * Differs from the original: CookieStore takes a list of cookies, so
	 * the map of the response is turned into one.
	 *
	 * @return this
	--->
	<cffunction name="withCookies" access="public" returntype="any" output="no">
		<cfset var cookies = service("response").getCookies()>
		<cfset var list = ArrayNew(1)>
		<cfset var id = "">

		<cfloop collection="#cookies#" item="id">
			<cfset ArrayAppend(list, cookies[id])>
		</cfloop>

		<cfset this.cookieStore = new_("ColdIgniter\Cookie\CookieStore", list)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Copies any headers from the global Response instance
	 * into this RedirectResponse. Useful when you've just
	 * set a header be need to ensure its actually sent
	 * with the redirect response.
	 *
	 * @return this
	--->
	<cffunction name="withHeaders" access="public" returntype="any" output="no">
		<cfset var headers = service("response").headers()>
		<cfset var name = "">
		<cfset var i = 0>

		<cfloop collection="#headers#" item="name">
			<cfif IsArray(headers[name])>
				<cfloop from="1" to="#ArrayLen(headers[name])#" index="i">
					<cfset addHeader(name, headers[name][i].getValue())>
				</cfloop>
			<cfelse>
				<cfset setHeader(name, headers[name].getValue())>
			</cfif>
		</cfloop>

		<cfreturn this>
	</cffunction>

</cfcomponent>
