<!---
 * Representation of an incoming, server-side HTTP request.
 *
 * Not ported yet: withMethod (see OutgoingRequest).
--->
<cfcomponent output="no" extends="OutgoingRequest" hint="Representation of an incoming, server-side HTTP request">

	<!--- use RequestTrait --->
	<cfinclude template="RequestTrait.cfm">

	<!---
	 * Constructor.
	 *
	 * @param config
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">

		<cfif is_null(arguments.config)>
			<cfset arguments.config = config("Config\App")>
		</cfif>

		<cfset this.config = arguments.config>

		<cfif this.method EQ "">
			<cfset this.method = getServer("REQUEST_METHOD")>
			<cfif is_null(this.method)>
				<cfset this.method = "GET">
			</cfif>
		</cfif>

		<cfif is_null(this.uri)>
			<cfset this.uri = new_("ColdIgniter\HTTP\URI")>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets the request method. Used when spoofing the request.
	--->
	<cffunction name="setMethod" access="public" returntype="any" output="no">
		<cfargument name="method" type="string" required="yes">

		<cfset this.method = arguments.method>

		<cfreturn this>
	</cffunction>

</cfcomponent>
