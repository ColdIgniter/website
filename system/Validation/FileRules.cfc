<!---
 * File validation Rules.
 *
 * Difference: this component cannot extend the one in the folder below, so
 * it creates it and calls it. The request is the one of the strict rules.
--->
<cfcomponent output="no" hint="File validation Rules">

	<!--- the strict rules --->
	<cfset this.strictFileRules = "">

	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="no">

		<cfif StructKeyExists(arguments, "request_") AND IsObject(arguments.request_)>
			<cfset this.strictFileRules = new_("ColdIgniter\Validation\StrictRules\FileRules", arguments.request_)>
		<cfelse>
			<cfset this.strictFileRules = new_("ColdIgniter\Validation\StrictRules\FileRules")>
		</cfif>

		<cfreturn this>
	</cffunction>

	<cffunction name="uploaded" access="public" returntype="boolean" output="no">
		<cfargument name="blank" type="any" required="no" default="">
		<cfargument name="name" type="string" required="yes">

		<cfreturn this.strictFileRules.uploaded(arguments.blank, arguments.name)>
	</cffunction>

	<cffunction name="max_size" access="public" returntype="boolean" output="no">
		<cfargument name="blank" type="any" required="no" default="">
		<cfargument name="params" type="string" required="yes">

		<cfreturn this.strictFileRules.max_size(arguments.blank, arguments.params)>
	</cffunction>

	<cffunction name="is_image" access="public" returntype="boolean" output="no">
		<cfargument name="blank" type="any" required="no" default="">
		<cfargument name="params" type="string" required="yes">

		<cfreturn this.strictFileRules.is_image(arguments.blank, arguments.params)>
	</cffunction>

	<cffunction name="mime_in" access="public" returntype="boolean" output="no">
		<cfargument name="blank" type="any" required="no" default="">
		<cfargument name="params" type="string" required="yes">

		<cfreturn this.strictFileRules.mime_in(arguments.blank, arguments.params)>
	</cffunction>

	<cffunction name="ext_in" access="public" returntype="boolean" output="no">
		<cfargument name="blank" type="any" required="no" default="">
		<cfargument name="params" type="string" required="yes">

		<cfreturn this.strictFileRules.ext_in(arguments.blank, arguments.params)>
	</cffunction>

	<cffunction name="max_dims" access="public" returntype="boolean" output="no">
		<cfargument name="blank" type="any" required="no" default="">
		<cfargument name="params" type="string" required="yes">

		<cfreturn this.strictFileRules.max_dims(arguments.blank, arguments.params)>
	</cffunction>

	<cffunction name="min_dims" access="public" returntype="boolean" output="no">
		<cfargument name="blank" type="any" required="no" default="">
		<cfargument name="params" type="string" required="yes">

		<cfreturn this.strictFileRules.min_dims(arguments.blank, arguments.params)>
	</cffunction>

</cfcomponent>
