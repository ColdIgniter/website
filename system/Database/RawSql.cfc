<!---
 * Raw SQL string.
 *
 * Difference: there is no Stringable, so a caller that needs the text of
 * a RawSql calls __toString() itself.
 * There is no clone, so with() makes a new object.
--->
<cfcomponent output="no" hint="Raw SQL string">

	<!---
	 * @var string Raw SQL string
	--->
	<cfset this.string = "">

	<!---
	 * Difference: there is no spl_object_id(), so an id made when the object
	 * is created stands in for it (see getBindingKey).
	--->
	<cfset this.id = "">

	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="sqlString" type="string" required="yes">

		<cfset this.string = arguments.sqlString>
		<cfset this.id = object_id_()>

		<cfreturn this>
	</cffunction>

	<cffunction name="__toString" access="public" returntype="string" output="no">

		<cfreturn this.string>
	</cffunction>

	<!---
	 * Create new instance with new SQL string
	--->
	<cffunction name="with" access="public" returntype="any" output="no">
		<cfargument name="newSqlString" type="string" required="yes">
		<cfset var clone_ = new_("ColdIgniter\Database\RawSql", arguments.newSqlString)>

		<cfreturn clone_>
	</cffunction>

	<!---
	 * Returns unique id for binding key
	 *
	 * Difference: there is no spl_object_id(), so the id of the object
	 * stands in for it.
	--->
	<cffunction name="getBindingKey" access="public" returntype="string" output="no">

		<cfreturn "RawSql" & this.id>
	</cffunction>

</cfcomponent>
