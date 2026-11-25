<!---
 * An extendable controller to provide a RESTful API for a resource.
 *
 * The trait ResponseTrait is included, so this.format_ and the methods
 * respond() and fail() are there (see API/ResponseTrait.cfm).
--->
<cfcomponent output="no" extends="BaseResource" hint="An extendable controller to provide a RESTful API for a resource">

	<cfinclude template="../API/ResponseTrait.cfm">

	<!---
	 * Return an array of resource objects, themselves in array format.
	--->
	<cffunction name="index" access="public" returntype="any" output="no">
		<cfset var args = ArrayNew(1)>

		<cfset ArrayAppend(args, "index")>

		<cfreturn fail(lang("RESTful.notImplemented", args), 501)>
	</cffunction>

	<!---
	 * Return the properties of a resource object.
	 *
	 * @param id The id of the resource; an empty string (null) for none
	--->
	<cffunction name="show" access="public" returntype="any" output="no">
		<cfargument name="id" type="any" required="no" default="">
		<cfset var args = ArrayNew(1)>

		<cfset ArrayAppend(args, "show")>

		<cfreturn fail(lang("RESTful.notImplemented", args), 501)>
	</cffunction>

	<!---
	 * Return a new resource object, with default properties.
	--->
	<cffunction name="new" access="public" returntype="any" output="no">
		<cfset var args = ArrayNew(1)>

		<cfset ArrayAppend(args, "new")>

		<cfreturn fail(lang("RESTful.notImplemented", args), 501)>
	</cffunction>

	<!---
	 * Create a new resource object, from "posted" parameters.
	--->
	<cffunction name="create" access="public" returntype="any" output="no">
		<cfset var args = ArrayNew(1)>

		<cfset ArrayAppend(args, "create")>

		<cfreturn fail(lang("RESTful.notImplemented", args), 501)>
	</cffunction>

	<!---
	 * Return the editable properties of a resource object.
	 *
	 * @param id The id of the resource; an empty string (null) for none
	--->
	<cffunction name="edit" access="public" returntype="any" output="no">
		<cfargument name="id" type="any" required="no" default="">
		<cfset var args = ArrayNew(1)>

		<cfset ArrayAppend(args, "edit")>

		<cfreturn fail(lang("RESTful.notImplemented", args), 501)>
	</cffunction>

	<!---
	 * Add or update a model resource, from "posted" properties.
	 *
	 * @param id The id of the resource; an empty string (null) for none
	--->
	<cffunction name="update" access="public" returntype="any" output="no">
		<cfargument name="id" type="any" required="no" default="">
		<cfset var args = ArrayNew(1)>

		<cfset ArrayAppend(args, "update")>

		<cfreturn fail(lang("RESTful.notImplemented", args), 501)>
	</cffunction>

	<!---
	 * Delete the designated resource object from the model.
	 *
	 * @param id The id of the resource; an empty string (null) for none
	--->
	<cffunction name="delete" access="public" returntype="any" output="no">
		<cfargument name="id" type="any" required="no" default="">
		<cfset var args = ArrayNew(1)>

		<cfset ArrayAppend(args, "delete")>

		<cfreturn fail(lang("RESTful.notImplemented", args), 501)>
	</cffunction>

	<!---
	 * Set/change the expected response representation for returned objects.
	 * Does nothing for a format other than json or xml.
	 *
	 * @param format json or xml
	--->
	<cffunction name="setFormat" access="public" returntype="void" output="no">
		<cfargument name="format" type="string" required="no" default="json">

		<cfif ListFind("json,xml", arguments.format)>
			<cfset this.format_ = arguments.format>
		</cfif>
	</cffunction>

</cfcomponent>
