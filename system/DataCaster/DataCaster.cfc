<!---
 * Class DataCaster
 *
 * Casts the values of a field to a type, and back, with the cast handler
 * of the type.
 *
 * Difference: an array of the original is a map (see array_()), the types
 * and the cast handlers included, and a null is an empty string. The
 * handlers are called through static_() (the one object that stands in for
 * a class with static methods), and the check that a handler implements
 * CastInterface finds the interface by the short name (see instanceof_()).
 * The methods of the original are called with the arguments value, params
 * and helper; the dispatch is by the name, "get" or "set".
 *
 * Difference: a handler that does not implement the interface is looked up
 * by the extends chain; the one of the entity casts and the one of the
 * DataCaster casts are both CastInterface.
 *
 * Difference: the original class is final and its handlers and helper are
 * read-only; here they are properties that nothing else changes.
--->
<cfcomponent output="no" hint="Casts the values of a field to a type and back">

	<!---
	 * @var array<string, string> [field => type]
	--->
	<cfset this.types = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * @var array<string, class-string> [type => class]
	--->
	<cfset this.castHandlers = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Helper object, for example a Connection.
	--->
	<cfset this.helper = "">

	<!---
	 * Strict mode.
	--->
	<cfset this.strict = true>

	<!---
	 * @param castHandlers Custom handlers, for the types of this list and the default ones. An empty string is none.
	 * @param types        [field => type]. An empty string is none.
	 * @param helper       Helper object, for example a Connection. An empty string is none.
	 * @param strict       Strict mode, which checks the handlers in the constructor.
	 *
	 * Difference: in strict mode, a null does not throw "Field is not
	 * nullable, but null was passed": a null and an empty string are the
	 * same value here, and an empty string is a value that fields often have.
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="castHandlers" type="any" required="no" default="">
		<cfargument name="types" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">
		<cfargument name="strict" type="boolean" required="no" default="true">
		<cfset var keys = "">
		<cfset var i = 0>
		<cfset var handler = "">

		<!--- the default handlers --->
		<cfset this.castHandlers["array"] = "ColdIgniter\DataCaster\Cast\ArrayCast">
		<cfset this.castHandlers["bool"] = "ColdIgniter\DataCaster\Cast\BooleanCast">
		<cfset this.castHandlers["boolean"] = "ColdIgniter\DataCaster\Cast\BooleanCast">
		<cfset this.castHandlers["csv"] = "ColdIgniter\DataCaster\Cast\CSVCast">
		<cfset this.castHandlers["datetime"] = "ColdIgniter\DataCaster\Cast\DatetimeCast">
		<cfset this.castHandlers["double"] = "ColdIgniter\DataCaster\Cast\FloatCast">
		<cfset this.castHandlers["float"] = "ColdIgniter\DataCaster\Cast\FloatCast">
		<cfset this.castHandlers["int"] = "ColdIgniter\DataCaster\Cast\IntegerCast">
		<cfset this.castHandlers["integer"] = "ColdIgniter\DataCaster\Cast\IntegerCast">
		<cfset this.castHandlers["int-bool"] = "ColdIgniter\DataCaster\Cast\IntBoolCast">
		<cfset this.castHandlers["json"] = "ColdIgniter\DataCaster\Cast\JsonCast">
		<cfset this.castHandlers["timestamp"] = "ColdIgniter\DataCaster\Cast\TimestampCast">
		<cfset this.castHandlers["uri"] = "ColdIgniter\DataCaster\Cast\URICast">

		<cfset this.helper = arguments.helper>
		<cfset this.strict = arguments.strict>

		<cfif IsStruct(arguments.castHandlers)>
			<cfset keys = array_keys(arguments.castHandlers)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset this.castHandlers[keys[i]] = arguments.castHandlers[keys[i]]>
			</cfloop>
		</cfif>

		<cfif IsStruct(arguments.types)>
			<cfset setTypes(arguments.types)>
		</cfif>

		<cfif this.strict>
			<cfset keys = array_keys(this.castHandlers)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset handler = this.castHandlers[keys[i]]>

				<cfif NOT instanceof_(static_(handler), "CastInterface")>
					<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Invalid class type. It must implement CastInterface. class: #handler#">
				</cfif>
			</cfloop>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * This method is necessary for the Entity class to set the types
	 * after the cast handlers have been created.
	 *
	 * @param types [field => type]
	--->
	<cffunction name="setTypes" access="public" returntype="any" output="no">
		<cfargument name="types" type="any" required="yes">

		<cfset this.types = arguments.types>

		<cfreturn this>
	</cffunction>

	<!---
	 * Provides the ability to cast an item as a specific data type.
	 * Add ? at the beginning of the type (i.e. ?string) to get an empty
	 * string (null) instead of casting value when value is null.
	 *
	 * @param value  Data
	 * @param field  Field name
	 * @param method Allowed to "get" and "set"
	 *
	 * @return mixed
	--->
	<cffunction name="castAs" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="field" type="string" required="yes">
		<cfargument name="method" type="string" required="no" default="get">
		<cfset var type = "">
		<cfset var isNullable = false>
		<cfset var params = ArrayNew(1)>
		<cfset var found = "">
		<cfset var parts = "">
		<cfset var i = 0>
		<cfset var handler = "">
		<cfset var cast = "">

		<cfif Compare(arguments.method, "get") NEQ 0 AND Compare(arguments.method, "set") NEQ 0>
			<cfset static_("ColdIgniter\Entity\Exceptions\CastException").forInvalidMethod(arguments.method)>
		</cfif>

		<!--- if the type is not defined, return as it is --->
		<cfif NOT array_key_exists(arguments.field, this.types)>
			<cfreturn arguments.value>
		</cfif>

		<cfset type = this.types[arguments.field]>

		<!--- is nullable? --->
		<cfif Len(type) GT 0 AND Compare(Left(type, 1), "?") EQ 0>
			<cfset isNullable = true>

			<cfif is_null(arguments.value)>
				<cfreturn "">
			</cfif>

			<cfset type = Mid(type, 2, Len(type) - 1)>
		</cfif>

		<!--- in order not to create a separate handler for the json-array type, we transform the required one --->
		<cfif Compare(type, "json-array") EQ 0>
			<cfset type = "json[array]">
		</cfif>

		<!--- attempt to retrieve additional parameters if specified: type[param, param2,param3] --->
		<cfset found = REFind("^(.+)\[(.+)\]$", type, 1, true)>

		<cfif found.pos[1] GT 0>
			<cfset parts = explode(",", Mid(type, found.pos[3], found.len[3]))>
			<cfset type = Mid(type, found.pos[2], found.len[2])>

			<cfloop from="1" to="#ArrayLen(parts)#" index="i">
				<cfset ArrayAppend(params, Trim(parts[i]))>
			</cfloop>
		</cfif>

		<cfif isNullable AND NOT this.strict>
			<cfset ArrayAppend(params, "nullable")>
		</cfif>

		<cfset type = REReplace(type, "^[\[\]]+|[\[\]]+$", "", "all")>

		<cfif NOT array_key_exists(type, this.castHandlers)>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="No such handler for ""#arguments.field#"". Invalid type: #type#">
		</cfif>

		<cfset handler = this.castHandlers[type]>
		<cfset cast = static_(handler)>

		<cfif NOT this.strict AND NOT instanceof_(cast, "CastInterface")>
			<cfset static_("ColdIgniter\Entity\Exceptions\CastException").forInvalidInterface(handler)>
		</cfif>

		<cfif Compare(arguments.method, "get") EQ 0>
			<cfreturn cast.get(arguments.value, params, this.helper)>
		</cfif>

		<cfreturn cast.set(arguments.value, params, this.helper)>
	</cffunction>
</cfcomponent>
