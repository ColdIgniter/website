<!---
 * Class BaseCast
 *
 * The casts return the value as it is, unless they define get() or set().
 *
 * Difference: the original checks the type of a value with is_string(),
 * is_int(), is_float() and is_bool() and throws for another type. Here a
 * scalar is text whatever its type was (see the notes of BaseModel), so
 * those checks can only tell a simple value from a list, a map or an
 * object: that is what the casts check, with isSimple_(). The check of
 * every cast has a Difference comment.
--->
<cfcomponent output="no" extends="CastInterface" hint="Base for the DataCaster casts">

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfreturn arguments.value>
	</cffunction>

	<cffunction name="set" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfreturn arguments.value>
	</cffunction>

	<!---
	 * Throws the exception for a value of a type that the cast does not
	 * take.
	 *
	 * Difference: the type is the one of get_debug_type() that can be told
	 * apart here: "array", the class of an object, "bool" and "string".
	 * Not "protected": it is a public method here, as a private function
	 * of a parent is not seen by the child.
	--->
	<cffunction name="invalidTypeValueError" access="public" returntype="void" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfset var type = "string">
		<cfset var message = "">

		<cfif IsObject(arguments.value)>
			<cfset type = GetMetaData(arguments.value).name>
		<cfelseif IsArray(arguments.value) OR IsStruct(arguments.value)>
			<cfset type = "array">
		<cfelseif is_bool(arguments.value)>
			<cfset type = "bool">
		</cfif>

		<cfset message = "[" & GetMetaData(this).name & "] Invalid value type: " & type>

		<cfif IsSimpleValue(arguments.value)>
			<cfset message = message & ", and its value: '" & arguments.value & "'">
		</cfif>

		<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="#message#">
	</cffunction>

	<!---
	 * Is the value a simple value (not a list, a map or an object)?
	 * Not in the original: it stands in for the type checks, see above.
	--->
	<cffunction name="isSimple_" access="public" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfreturn IsSimpleValue(arguments.value)>
	</cffunction>
</cfcomponent>
