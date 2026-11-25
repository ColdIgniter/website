<!---
 * Class DataConverter
 *
 * Converts data from the database to the values of the types, and the
 * other way round, with a DataCaster, and builds the objects of a return
 * type from a row.
 *
 * Difference: an array of the original is a map (see array_()), and a null
 * is an empty string (the reconstructor, the extractor and the helper are
 * an empty string when there is none). The reconstructor and the extractor
 * are the name of a method of the class or the object, or a function (a
 * Closure in the original).
 *
 * Difference: the original has no reflection to avoid; here an object that
 * is not an Entity is given the values with its keys, as a map is (there is
 * no property that is private to a class), and it is read back with its
 * toRawArray() method, or the call throws "Not ported yet".
 *
 * Difference: the original class is final and readonly; here the types,
 * the helper, the reconstructor, the extractor and the data caster are
 * properties that nothing else changes.
 *
 * Difference: a value that is a null marker (see NullValue of the Database)
 * is a null on its way to the database, so toDataSource() leaves it alone.
--->
<cfcomponent output="no" hint="Converts data from and to the database with the casts of its fields">

	<cfset this.types = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.helper = "">
	<cfset this.reconstructor = "reconstruct">
	<cfset this.extractor = "">
	<cfset this.dataCaster_ = "">

	<!---
	 * @param types         [field => type]
	 * @param castHandlers  Custom handlers, [type => class]
	 * @param helper        Helper object, for example a Connection
	 * @param reconstructor The name of a method, or a function
	 * @param extractor     The name of a method, or a function
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="types" type="any" required="yes">
		<cfargument name="castHandlers" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">
		<cfargument name="reconstructor" type="any" required="no" default="reconstruct">
		<cfargument name="extractor" type="any" required="no" default="">

		<cfset this.types = arguments.types>
		<cfset this.helper = arguments.helper>
		<cfset this.reconstructor = arguments.reconstructor>
		<cfset this.extractor = arguments.extractor>
		<cfset this.dataCaster_ = new_("ColdIgniter\DataCaster\DataCaster", arguments.castHandlers, arguments.types, arguments.helper)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Converts data from the database to the values of the types.
	 *
	 * @param data Data from the database. The map is not changed.
	 *
	 * @return array<string, mixed>
	--->
	<cffunction name="fromDataSource" access="public" returntype="any" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfset var keys = array_keys(this.types)>
		<cfset var i = 0>
		<cfset var result = CreateObject("java", "java.util.LinkedHashMap").init(arguments.data)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfif array_key_exists(keys[i], result)>
				<cfset result[keys[i]] = this.dataCaster_.castAs(result[keys[i]], keys[i], "get")>
			</cfif>
		</cfloop>

		<cfreturn result>
	</cffunction>

	<!---
	 * Converts the values of the types to data for the database.
	 *
	 * Difference: the argument is named valueData.
	 *
	 * @param valueData The values. The map is not changed.
	 *
	 * @return array<string, mixed>
	--->
	<cffunction name="toDataSource" access="public" returntype="any" output="no">
		<cfargument name="valueData" type="any" required="yes">
		<cfset var keys = array_keys(this.types)>
		<cfset var i = 0>
		<cfset var result = CreateObject("java", "java.util.LinkedHashMap").init(arguments.valueData)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfif array_key_exists(keys[i], result)>
				<!--- a null marker is a null, which is not cast --->
				<cfif NOT (IsObject(result[keys[i]]) AND instanceof_(result[keys[i]], "NullValue"))>
					<cfset result[keys[i]] = this.dataCaster_.castAs(result[keys[i]], keys[i], "set")>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn result>
	</cffunction>

	<!---
	 * Creates an object of the class from a row of the database.
	 *
	 * @param classname The class of the object
	 * @param row       Raw data from the database
	 *
	 * @return object
	--->
	<cffunction name="reconstruct" access="public" returntype="any" output="no">
		<cfargument name="classname" type="string" required="yes">
		<cfargument name="row" type="any" required="yes">
		<cfset var valueData = fromDataSource(arguments.row)>
		<cfset var class_ = "">
		<cfset var closure = "">
		<cfset var classObj = "">
		<cfset var keys = "">
		<cfset var i = 0>

		<!--- use the reconstruct method of the class --->
		<cfif IsSimpleValue(this.reconstructor) AND NOT is_null(this.reconstructor)>
			<cfset class_ = static_(arguments.classname)>

			<cfif method_exists(class_, this.reconstructor)>
				<cfreturn Evaluate("class_.#this.reconstructor#(valueData)")>
			</cfif>
		</cfif>

		<!--- use the function to reconstruct --->
		<cfif IsCustomFunction(this.reconstructor)>
			<cfset closure = this.reconstructor>

			<cfreturn closure(valueData)>
		</cfif>

		<cfset classObj = new_(arguments.classname)>

		<cfif instanceof_(classObj, "Entity")>
			<cfset classObj.injectRawData(valueData)>
			<cfset classObj.syncOriginal()>

			<cfreturn classObj>
		</cfif>

		<cfset keys = array_keys(valueData)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset classObj[keys[i]] = valueData[keys[i]]>
		</cfloop>

		<cfreturn classObj>
	</cffunction>

	<!---
	 * Extracts the values of an object as a row for the database.
	 *
	 * @param object      The object
	 * @param onlyChanged Only the values that have changed
	 * @param recursive   If true, inner entities will be cast as array as well
	 *
	 * @return array<string, mixed>
	--->
	<cffunction name="extract" access="public" returntype="any" output="no">
		<cfargument name="object" type="any" required="yes">
		<cfargument name="onlyChanged" type="boolean" required="no" default="false">
		<cfargument name="recursive" type="boolean" required="no" default="false">
		<cfset var row = "">
		<cfset var closure = "">

		<!--- use the extractor method --->
		<cfif IsSimpleValue(this.extractor) AND NOT is_null(this.extractor) AND method_exists(arguments.object, this.extractor)>
			<cfset row = Evaluate("arguments.object.#this.extractor#(arguments.onlyChanged, arguments.recursive)")>

			<cfreturn toDataSource(row)>
		</cfif>

		<!--- use the function to extract --->
		<cfif IsCustomFunction(this.extractor)>
			<cfset closure = this.extractor>
			<cfset row = closure(arguments.object, arguments.onlyChanged, arguments.recursive)>

			<cfreturn toDataSource(row)>
		</cfif>

		<cfif instanceof_(arguments.object, "Entity") OR method_exists(arguments.object, "toRawArray")>
			<cfset row = arguments.object.toRawArray(arguments.onlyChanged, arguments.recursive)>

			<cfreturn toDataSource(row)>
		</cfif>

		<cfthrow type="ColdIgniter.LogicException" message="Not ported yet: reading the properties of an object without a toRawArray() method.">
	</cffunction>
</cfcomponent>
