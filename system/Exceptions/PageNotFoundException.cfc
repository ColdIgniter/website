<!---
 * Not ported yet: the messages come from the language files in the
 * original (HTTP.pageNotFound and the others); they are written out
 * here until the language service is ported.
 *
 * An exception is not an object here. The methods throw the exception
 * themselves, with the type "ColdIgniter.Exceptions.PageNotFoundException":
 *
 *     <cfset static_("ColdIgniter\Exceptions\PageNotFoundException").forPageNotFound()>
 *
 * stands in for "throw PageNotFoundException::forPageNotFound()".
--->
<cfcomponent output="no" hint="Page not found">

	<!---
	 * HTTP status code
	--->
	<cfset this.code = 404>

	<cffunction name="forPageNotFound" access="public" returntype="void" output="no">
		<cfargument name="message" type="string" required="no" default="">

		<cfif is_null(arguments.message)>
			<cfset arguments.message = "Page Not Found">
		</cfif>

		<cfthrow type="ColdIgniter.Exceptions.PageNotFoundException" errorcode="#this.code#" message="#arguments.message#">
	</cffunction>

	<cffunction name="forEmptyController" access="public" returntype="void" output="no">
		<cfthrow type="ColdIgniter.Exceptions.PageNotFoundException" errorcode="#this.code#" message="No Controller specified.">
	</cffunction>

	<cffunction name="forControllerNotFound" access="public" returntype="void" output="no">
		<cfargument name="controller" type="string" required="yes">
		<cfargument name="method" type="string" required="yes">

		<cfthrow type="ColdIgniter.Exceptions.PageNotFoundException" errorcode="#this.code#" message="Controller or its method is not found: #arguments.controller#::#arguments.method#">
	</cffunction>

	<cffunction name="forMethodNotFound" access="public" returntype="void" output="no">
		<cfargument name="method" type="string" required="yes">

		<cfthrow type="ColdIgniter.Exceptions.PageNotFoundException" errorcode="#this.code#" message="Controller method is not found: #arguments.method#">
	</cffunction>

</cfcomponent>
