<!---
 * Base class for transforming resources into arrays.
 * Fulfills common functionality of the TransformerInterface,
 * and provides helper methods for conditional inclusion/exclusion of values.
 *
 * Supports the following query variables from the request:
 * - fields: Comma-separated list of fields to include in the response
 *      (e.g., ?fields=id,name,email)
 *      If not provided, all fields from toArray() are included.
 * - include: Comma-separated list of related resources to include
 *      (e.g., ?include=posts,comments)
 *      This looks for methods named `include{Resource}()` on the transformer,
 *      and calls them to get the related data, which are added as a new key to the output.
 *
 * Example:
 *
 * <cfcomponent output="no" parent="ColdIgniter\API\BaseTransformer">
 *
 *     <cffunction name="toArray" access="public" returntype="any" output="no">
 *         <cfargument name="resource" type="any" required="yes">
 *         <cfset var data = StructNew()>
 *
 *         <cfset data["id"] = arguments.resource["id"]>
 *         <cfset data["name"] = arguments.resource["name"]>
 *
 *         <cfreturn data>
 *     </cffunction>
 *
 *     <cffunction name="includePosts" access="private" returntype="any" output="no">
 *         <cfset var posts = model("PostModel").where("user_id", this.resource["id"]).findAll()>
 *
 *         <cfreturn new_("App\Transformers\PostTransformer").transformMany(posts)>
 *     </cffunction>
 *
 * </cfcomponent>
 *
 * Difference: a null is an empty string (see is_null()), so a query
 * variable "fields" or "include" that is empty counts as not given (the
 * original reads "?fields=" as the list of one empty name, which leaves
 * no field), and a value that is neither a string nor a list is ignored.
 * transformMany() takes a list only.
 *
 * Difference: the include methods are called by name with Evaluate(),
 * after the name has been checked to be letters, digits and underscores.
 * A try with finally does not exist; the depth is put back by hand.
 *
 * Difference: the static property $depth is the property depth of the
 * shared object of static_().
 *
 * Difference: the keys of the data are compared as they are written
 * (case-sensitive), so a key of a struct written with a dot is in upper
 * case; write the keys with brackets (see array_()).
--->
<cfcomponent output="no" extends="TransformerInterface" hint="Base class for transforming resources into arrays">

	<!---
	 * Nesting depth of the transformation currently in progress (0 = root).
	--->
	<cfset this.depth = 0>

	<!---
	 * @var list<string>|null
	--->
	<cfset this.fields = "">

	<!---
	 * @var list<string>|null
	--->
	<cfset this.includes = "">

	<cfset this.resource = "">

	<!---
	 * The request. Named with an underscore, because "request" is a scope.
	--->
	<cfset this.request_ = "">

	<!---
	 * @param request_ An IncomingRequest, an empty string is the shared one
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="no" default="">
		<cfset var explicitRequest = NOT is_null(arguments.request_)>
		<cfset var shared = "">

		<!---
		 An explicitly provided request is always honored - its scope is
		 intentional. Only the implicit global fallback is suppressed for
		 nested transformers, which is the actual leak vector.
		--->
		<cfif explicitRequest>
			<cfset this.request_ = arguments.request_>
		<cfelse>
			<cfset this.request_ = service("request")>
		</cfif>

		<cfset shared = static_("ColdIgniter\API\BaseTransformer")>

		<cfif explicitRequest OR shared.depth EQ 0>
			<cfset this.fields = listFromQuery(this.request_.getGet("fields"))>
			<cfset this.includes = listFromQuery(this.request_.getGet("include"))>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Reads a query variable as a list of names: a string is split at the
	 * commas and each name is trimmed; a list is kept; anything else is null.
	--->
	<cffunction name="listFromQuery" access="private" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfset var names = "">
		<cfset var i = 0>

		<cfif IsArray(arguments.value)>
			<cfreturn arguments.value>
		</cfif>

		<cfif NOT IsSimpleValue(arguments.value) OR arguments.value EQ "">
			<cfreturn "">
		</cfif>

		<cfset names = explode(",", arguments.value)>

		<cfloop from="1" to="#ArrayLen(names)#" index="i">
			<cfset names[i] = Trim(names[i])>
		</cfloop>

		<cfreturn names>
	</cffunction>

	<!---
	 * Transforms the given resource into an array using
	 * the $this->toArray().
	 *
	 * @param resource A map, a component or an empty string (null)
	 *
	 * @return A map
	--->
	<cffunction name="transform" access="public" returntype="any" output="no">
		<cfargument name="resource" type="any" required="no" default="">
		<cfset var data = "">

		<!--- Store the resource so include methods can access it --->
		<cfset this.resource = arguments.resource>

		<cfif is_null(arguments.resource)>
			<cfset data = toArray("")>
		<cfelseif IsObject(arguments.resource) AND method_exists(arguments.resource, "toArray")>
			<cfset data = toArray(arguments.resource.toArray())>
		<cfelse>
			<cfset data = toArray(arguments.resource)>
		</cfif>

		<cfset data = limitFields(data)>

		<cfreturn insertIncludes(data)>
	</cffunction>

	<!---
	 * Transforms a collection of resources using $this->transform() on each item.
	 *
	 * If the request's 'fields' query variable is set, only those fields will be included
	 * in the transformed output.
	--->
	<cffunction name="transformMany" access="public" returntype="any" output="no">
		<cfargument name="resources" type="array" required="yes">
		<cfset var result = ArrayNew(1)>
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(arguments.resources)#" index="i">
			<cfset ArrayAppend(result, transform(arguments.resources[i]))>
		</cfloop>

		<cfreturn result>
	</cffunction>

	<!---
	 * Define which fields can be requested via the 'fields' query parameter.
	 * Override in child classes to restrict available fields.
	 * Return an empty string (null) to allow all fields from toArray().
	 *
	 * @return A list of names, or an empty string (null)
	--->
	<cffunction name="getAllowedFields" access="private" returntype="any" output="no">

		<cfreturn "">
	</cffunction>

	<!---
	 * Define which related resources can be included via the 'include' query parameter.
	 * Override in child classes to restrict available includes.
	 * Return an empty string (null) to allow all includes that have corresponding methods.
	 * Return an empty list to disable all includes.
	 *
	 * @return A list of names, or an empty string (null)
	--->
	<cffunction name="getAllowedIncludes" access="private" returntype="any" output="no">

		<cfreturn "">
	</cffunction>

	<!---
	 * Limits the given data array to only the fields specified
	 *
	 * @param data A map
	 *
	 * @return A map
	 *
	 * @throws ApiException
	--->
	<cffunction name="limitFields" access="private" returntype="any" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfset var allowedFields = "">
		<cfset var invalidFields = ArrayNew(1)>
		<cfset var result = array_()>
		<cfset var keys = "">
		<cfset var key = "">
		<cfset var i = 0>

		<cfif is_null(this.fields) OR ArrayLen(this.fields) EQ 0>
			<cfreturn arguments.data>
		</cfif>

		<cfset allowedFields = getAllowedFields()>

		<!--- If whitelist is defined, validate against it --->
		<cfif NOT is_null(allowedFields)>
			<cfloop from="1" to="#ArrayLen(this.fields)#" index="i">
				<cfif NOT in_array(this.fields[i], allowedFields)>
					<cfset ArrayAppend(invalidFields, this.fields[i])>
				</cfif>
			</cfloop>

			<cfif ArrayLen(invalidFields) GT 0>
				<cfset static_("ColdIgniter\API\ApiException").forInvalidFields(implode(", ", invalidFields))>
			</cfif>
		</cfif>

		<!--- array_intersect_key(): the keys of the data that are fields, in the order of the data --->
		<cfset keys = CreateObject("java", "java.util.ArrayList").init(arguments.data.keySet())>

		<cfloop from="0" to="#keys.size() - 1#" index="i">
			<cfset key = keys.get(JavaCast("int", i))>

			<cfif in_array(key, this.fields)>
				<cfset result[key] = arguments.data[key]>
			</cfif>
		</cfloop>

		<cfreturn result>
	</cffunction>

	<!---
	 * Checks the request for 'include' query variable, and if present,
	 * calls the corresponding include{Resource} methods to add related data.
	 *
	 * @param data A map
	 *
	 * @return A map
	--->
	<cffunction name="insertIncludes" access="private" returntype="any" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfset var copy = "">
		<cfset var allowedIncludes = "">
		<cfset var invalidIncludes = ArrayNew(1)>
		<cfset var shared = "">
		<cfset var include = "">
		<cfset var method = "">
		<cfset var i = 0>

		<cfif is_null(this.includes)>
			<cfreturn arguments.data>
		</cfif>

		<cfset allowedIncludes = getAllowedIncludes()>

		<cfif IsArray(allowedIncludes) AND ArrayLen(allowedIncludes) EQ 0>
			<cfreturn arguments.data> <!--- No includes allowed --->
		</cfif>

		<!--- If whitelist is defined, filter the requested includes --->
		<cfif NOT is_null(allowedIncludes)>
			<cfloop from="1" to="#ArrayLen(this.includes)#" index="i">
				<cfif NOT in_array(this.includes[i], allowedIncludes)>
					<cfset ArrayAppend(invalidIncludes, this.includes[i])>
				</cfif>
			</cfloop>

			<cfif ArrayLen(invalidIncludes) GT 0>
				<cfset static_("ColdIgniter\API\ApiException").forInvalidIncludes(implode(", ", invalidIncludes))>
			</cfif>
		</cfif>

		<cfset shared = static_("ColdIgniter\API\BaseTransformer")>
		<cfset shared.depth = shared.depth + 1>

		<!--- a shallow copy, so the map that toArray() returned (it may be the resource itself) is not changed --->
		<cfset copy = CreateObject("java", "java.util.LinkedHashMap").init(arguments.data)>

		<cftry>
			<cfloop from="1" to="#ArrayLen(this.includes)#" index="i">
				<cfset include = this.includes[i]>
				<cfset method = "include" & ucfirst(include)>

				<cfif REFind("^[A-Za-z0-9_]+$", include) AND StructKeyExists(variables, method) AND IsCustomFunction(variables[method])>
					<cfset copy[include] = Evaluate("#method#()")>
				<cfelse>
					<cfset static_("ColdIgniter\API\ApiException").forMissingInclude(include)>
				</cfif>
			</cfloop>

			<cfcatch type="any">
				<cfset shared.depth = shared.depth - 1>
				<cfrethrow>
			</cfcatch>
		</cftry>

		<cfset shared.depth = shared.depth - 1>

		<cfreturn copy>
	</cffunction>

</cfcomponent>
