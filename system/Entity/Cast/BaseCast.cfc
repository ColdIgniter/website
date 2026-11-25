<!---
 * Class BaseCast
 *
 * The casts return the value as it is, unless they define get() or set().
--->
<cfcomponent output="no" extends="CastInterface" hint="Base for the entity casts">

	<!---
	 * @param value  Data
	 * @param params Additional param
	 *
	 * @return mixed
	--->
	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfreturn arguments.value>
	</cffunction>

	<!---
	 * @param value  Data
	 * @param params Additional param
	 *
	 * @return mixed
	--->
	<cffunction name="set" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfreturn arguments.value>
	</cffunction>
</cfcomponent>
