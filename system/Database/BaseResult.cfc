<!---
 * Base class for the results of a query.
 *
 * Difference: there is no abstract class, so fetchAssoc(), fetchObject()
 * and the methods of ResultInterface that only a driver can do
 * (getFieldCount(), getFieldNames(), getFieldData(), freeResult() and
 * dataSeek()) are methods that throw "The class does not define X()."
 * and the result of the driver that extends this component defines them.
 *
 * Difference: a row is a map (see array_()), for both the array and the
 * object type, as there is no stdClass. A null is an empty string. The
 * lists that are returned are the lists that the result keeps, not copies,
 * so a caller must not change them. fetchAssoc() and fetchObject() give a
 * map, and the text "false" or an empty string when there is no more.
 *
 * Difference: the result of a query is a query object (cfquery) and not a
 * resource or an object, so a result is valid when it is an object, a
 * query or a map.
 *
 * Difference: is_null(x) is written out as (IsSimpleValue(x) AND x EQ "")
 * in this file, which is the body of is_null() without the call of the
 * function. Each result is asked these tests several times on a page
 * (the rows, a field, the count), and the test costs a tenth of the call
 * of the function.
 *
 * Difference: the result objects of a class (getCustomResultObject() and
 * getCustomRowObject()) are components created with new_(). The values of a
 * row that is already read are given to an Entity with __set() (as the
 * original does with the property), and to any other class as keys; a row
 * that is read from the result is made by fetchObject(className).
 *
 * @template TConnection
 * @template TResult
--->
<cfcomponent output="no" extends="ResultInterface" hint="Base class for the results of a query">

	<!---
	 * @var TConnection
	--->
	<cfset this.connID = "">

	<!---
	 * @var false|TResult
	--->
	<cfset this.resultID = "false">

	<!---
	 * @var list<array>
	--->
	<cfset this.resultArray = ArrayNew(1)>

	<!---
	 * @var list<object>
	--->
	<cfset this.resultObject = ArrayNew(1)>

	<!---
	 * @var array<class-string, list<object>>
	--->
	<cfset this.customResultObject = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Current row index
	 *
	 * @var int
	--->
	<cfset this.currentRow = 0>

	<!---
	 * The number of records in the query result
	 *
	 * @var int|null
	--->
	<cfset this.numRows = "">

	<!---
	 * @var array<string, mixed>|null
	--->
	<cfset this.rowData = "">

	<!---
	 * @param TConnection $connID
	 * @param TResult     $resultID
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="connID" type="any" required="yes">
		<cfargument name="resultID" type="any" required="yes">

		<cfset this.connID = arguments.connID>
		<cfset this.resultID = arguments.resultID>

		<cfreturn this>
	</cffunction>

	<!---
	 * Retrieve the results of the query. Typically an array of
	 * individual data rows, which can be either an 'array', an
	 * 'object', or a custom class name.
	 *
	 * @param string $type The row type. Either 'array', 'object', or a class name to use
	--->
	<cffunction name="getResult" access="public" returntype="any" output="no">
		<cfargument name="type" type="string" required="no" default="object">

		<cfif Compare(arguments.type, "array") EQ 0>
			<cfreturn this.getResultArray()>
		</cfif>

		<cfif Compare(arguments.type, "object") EQ 0>
			<cfreturn this.getResultObject()>
		</cfif>

		<cfreturn this.getCustomResultObject(arguments.type)>
	</cffunction>

	<!---
	 * Returns the results as an array of custom objects.
	 *
	 * @param class-string $className
	 *
	 * @return array
	--->
	<cffunction name="getCustomResultObject" access="public" returntype="any" output="no">
		<cfargument name="className" type="string" required="yes">
		<cfset var list = ArrayNew(1)>
		<cfset var source = "">
		<cfset var obj = "">
		<cfset var row = "">
		<cfset var keys = "">
		<cfset var isEntity = false>
		<cfset var i = 0>
		<cfset var j = 0>

		<cfif StructKeyExists(this.customResultObject, arguments.className)>
			<cfreturn this.customResultObject[arguments.className]>
		</cfif>

		<!---
		 * In the event that query caching is on, the result_id variable
		 * will not be a valid resource so we'll simply return an empty
		 * array.
		--->
		<cfif NOT isValidResultId()>
			<cfreturn ArrayNew(1)>
		</cfif>

		<!--- don't fetch the result set again if we already have it --->
		<cfif ArrayLen(this.resultArray) GT 0>
			<cfset source = this.resultArray>
		<cfelseif ArrayLen(this.resultObject) GT 0>
			<cfset source = this.resultObject>
		</cfif>

		<cfif IsArray(source)>
			<cfloop from="1" to="#ArrayLen(source)#" index="i">
				<cfset obj = new_(arguments.className)>
				<cfset isEntity = instanceof_(obj, "Entity")>
				<cfset keys = array_keys(source[i])>

				<cfloop from="1" to="#ArrayLen(keys)#" index="j">
					<cfif isEntity>
						<cfset obj.__set(keys[j], source[i][keys[j]])>
					<cfelse>
						<cfset obj[keys[j]] = source[i][keys[j]]>
					</cfif>
				</cfloop>

				<cfset ArrayAppend(list, obj)>
			</cfloop>

			<cfset this.customResultObject[arguments.className] = list>

			<cfreturn list>
		</cfif>

		<cfif NOT (IsSimpleValue(this.rowData) AND this.rowData EQ "")>
			<cfset this.dataSeek()>
		</cfif>

		<cfset row = fetchObject(arguments.className)>

		<cfloop condition="IsObject(row)">
			<cfif NOT instanceof_(row, "Entity") AND method_exists(row, "syncOriginal")>
				<cfset row.syncOriginal()>
			</cfif>

			<cfset ArrayAppend(list, row)>
			<cfset row = fetchObject(arguments.className)>
		</cfloop>

		<cfset this.customResultObject[arguments.className] = list>

		<cfreturn list>
	</cffunction>

	<!---
	 * Returns the results as an array of arrays.
	 *
	 * If no results, an empty array is returned.
	--->
	<cffunction name="getResultArray" access="public" returntype="array" output="no">
		<cfset var row = "">
		<cfset var i = 0>

		<cfif ArrayLen(this.resultArray) GT 0>
			<cfreturn this.resultArray>
		</cfif>

		<!---
		 * In the event that query caching is on, the result_id variable
		 * will not be a valid resource so we'll simply return an empty
		 * array.
		--->
		<cfif NOT isValidResultId()>
			<cfreturn ArrayNew(1)>
		</cfif>

		<cfif ArrayLen(this.resultObject) GT 0>
			<cfloop from="1" to="#ArrayLen(this.resultObject)#" index="i">
				<cfset ArrayAppend(this.resultArray, copyRow(this.resultObject[i]))>
			</cfloop>

			<cfreturn this.resultArray>
		</cfif>

		<cfif NOT (IsSimpleValue(this.rowData) AND this.rowData EQ "")>
			<cfset this.dataSeek()>
		</cfif>

		<cfset row = fetchAssoc()>

		<cfloop condition="isRow(row)">
			<cfset ArrayAppend(this.resultArray, row)>
			<cfset row = fetchAssoc()>
		</cfloop>

		<cfreturn this.resultArray>
	</cffunction>

	<!---
	 * Returns the results as an array of objects.
	 *
	 * If no results, an empty array is returned.
	 *
	 * Difference: the objects are maps, so there is no syncOriginal().
	--->
	<cffunction name="getResultObject" access="public" returntype="array" output="no">
		<cfset var row = "">
		<cfset var i = 0>

		<cfif ArrayLen(this.resultObject) GT 0>
			<cfreturn this.resultObject>
		</cfif>

		<!---
		 * In the event that query caching is on, the result_id variable
		 * will not be a valid resource so we'll simply return an empty
		 * array.
		--->
		<cfif NOT isValidResultId()>
			<cfreturn ArrayNew(1)>
		</cfif>

		<cfif ArrayLen(this.resultArray) GT 0>
			<cfloop from="1" to="#ArrayLen(this.resultArray)#" index="i">
				<cfset ArrayAppend(this.resultObject, copyRow(this.resultArray[i]))>
			</cfloop>

			<cfreturn this.resultObject>
		</cfif>

		<cfif NOT (IsSimpleValue(this.rowData) AND this.rowData EQ "")>
			<cfset this.dataSeek()>
		</cfif>

		<cfset row = fetchObject()>

		<cfloop condition="isRow(row)">
			<cfset ArrayAppend(this.resultObject, row)>
			<cfset row = fetchObject()>
		</cfloop>

		<cfreturn this.resultObject>
	</cffunction>

	<!---
	 * Wrapper object to return a row as either an array, an object, or
	 * a custom class.
	 *
	 * If row doesn't exist, returns null.
	 *
	 * @param int|string $n    The index of the results to return, or a column name
	 * @param string     $type The type of result object. 'array', 'object' or a class name.
	 *
	 * @return array|object|stdClass|null
	 *
	 * Difference: the data of the row is a copy of the map.
	--->
	<cffunction name="getRow" access="public" returntype="any" output="no">
		<cfargument name="n" type="any" required="no" default="0">
		<cfargument name="type" type="string" required="no" default="object">

		<!--- $n is a column name. --->
		<cfif NOT IsNumeric(arguments.n)>
			<!--- We cache the row data for subsequent uses --->
			<cfif NOT isMap(this.rowData)>
				<cfset this.rowData = copyRow(this.getRowArray())>
			</cfif>

			<!--- StructKeyExists() instead of a test of the value to allow for NULL values --->
			<cfif NOT isMap(this.rowData) OR NOT StructKeyExists(this.rowData, arguments.n)>
				<cfreturn "">
			</cfif>

			<cfreturn this.rowData[arguments.n]>
		</cfif>

		<cfif Compare(arguments.type, "object") EQ 0>
			<cfreturn this.getRowObject(arguments.n)>
		</cfif>

		<cfif Compare(arguments.type, "array") EQ 0>
			<cfreturn this.getRowArray(arguments.n)>
		</cfif>

		<cfreturn this.getCustomRowObject(arguments.n, arguments.type)>
	</cffunction>

	<!---
	 * Returns a row as a custom class instance.
	 *
	 * If row doesn't exist, returns null.
	 *
	 * @return array|null
	--->
	<cffunction name="getCustomRowObject" access="public" returntype="any" output="no">
		<cfargument name="n" type="numeric" required="yes">
		<cfargument name="className" type="string" required="yes">
		<cfset var list = this.getCustomResultObject(arguments.className)>

		<cfif ArrayLen(list) EQ 0>
			<cfreturn "">
		</cfif>

		<cfif arguments.n NEQ this.currentRow AND rowExists(list, arguments.n)>
			<cfset this.currentRow = arguments.n>
		</cfif>

		<cfreturn rowAt(list, this.currentRow)>
	</cffunction>

	<!---
	 * Returns a single row from the results as an array.
	 *
	 * If row doesn't exist, returns null.
	 *
	 * @return array|null
	--->
	<cffunction name="getRowArray" access="public" returntype="any" output="no">
		<cfargument name="n" type="numeric" required="no" default="0">
		<cfset var result = this.getResultArray()>

		<cfif ArrayLen(result) EQ 0>
			<cfreturn "">
		</cfif>

		<cfif arguments.n NEQ this.currentRow AND rowExists(result, arguments.n)>
			<cfset this.currentRow = arguments.n>
		</cfif>

		<cfreturn rowAt(result, this.currentRow)>
	</cffunction>

	<!---
	 * Returns a single row from the results as an object.
	 *
	 * If row doesn't exist, returns null.
	 *
	 * @return object|stdClass|null
	--->
	<cffunction name="getRowObject" access="public" returntype="any" output="no">
		<cfargument name="n" type="numeric" required="no" default="0">
		<cfset var result = this.getResultObject()>

		<cfif ArrayLen(result) EQ 0>
			<cfreturn "">
		</cfif>

		<cfif arguments.n NEQ this.currentRow AND rowExists(result, arguments.n)>
			<cfset this.currentRow = arguments.n>
		</cfif>

		<cfreturn rowAt(result, this.currentRow)>
	</cffunction>

	<!---
	 * Assigns an item into a particular column slot.
	 *
	 * @param array|object|string $key
	 * @param mixed               $value
	 *
	 * @return void
	 *
	 * Difference: the key is a string or a map, and a null value is an
	 * empty string.
	--->
	<cffunction name="setRow" access="public" returntype="void" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfargument name="value" type="any" required="no" default="">
		<cfset var keys = "">
		<cfset var i = 0>

		<!--- We cache the row data for subsequent uses --->
		<cfif NOT isMap(this.rowData)>
			<cfset this.rowData = copyRow(this.getRowArray())>
		</cfif>

		<!--- a row that does not exist is a new one --->
		<cfif NOT isMap(this.rowData)>
			<cfset this.rowData = array_()>
		</cfif>

		<cfif isMap(arguments.key)>
			<cfset keys = array_keys(arguments.key)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset this.rowData[keys[i]] = arguments.key[keys[i]]>
			</cfloop>

			<cfreturn>
		</cfif>

		<cfif Len(arguments.key) GT 0 AND NOT (IsSimpleValue(arguments.value) AND arguments.value EQ "")>
			<cfset this.rowData[arguments.key] = arguments.value>
		</cfif>
	</cffunction>

	<!---
	 * Returns the "first" row of the current results.
	 *
	 * @return array|object|null
	--->
	<cffunction name="getFirstRow" access="public" returntype="any" output="no">
		<cfargument name="type" type="string" required="no" default="object">
		<cfset var result = this.getResult(arguments.type)>

		<cfif ArrayLen(result) EQ 0>
			<cfreturn "">
		</cfif>

		<cfreturn result[1]>
	</cffunction>

	<!---
	 * Returns the "last" row of the current results.
	 *
	 * @return array|object|null
	--->
	<cffunction name="getLastRow" access="public" returntype="any" output="no">
		<cfargument name="type" type="string" required="no" default="object">
		<cfset var result = this.getResult(arguments.type)>

		<cfif ArrayLen(result) EQ 0>
			<cfreturn "">
		</cfif>

		<cfreturn result[ArrayLen(result)]>
	</cffunction>

	<!---
	 * Returns the "next" row of the current results.
	 *
	 * @return array|object|null
	--->
	<cffunction name="getNextRow" access="public" returntype="any" output="no">
		<cfargument name="type" type="string" required="no" default="object">
		<cfset var result = this.getResult(arguments.type)>

		<cfif ArrayLen(result) EQ 0>
			<cfreturn "">
		</cfif>

		<cfif rowExists(result, this.currentRow + 1)>
			<cfset this.currentRow = this.currentRow + 1>

			<cfreturn rowAt(result, this.currentRow)>
		</cfif>

		<cfreturn "">
	</cffunction>

	<!---
	 * Returns the "previous" row of the current results.
	 *
	 * @return array|object|null
	--->
	<cffunction name="getPreviousRow" access="public" returntype="any" output="no">
		<cfargument name="type" type="string" required="no" default="object">
		<cfset var result = this.getResult(arguments.type)>

		<cfif ArrayLen(result) EQ 0>
			<cfreturn "">
		</cfif>

		<cfif rowExists(result, this.currentRow - 1)>
			<cfset this.currentRow = this.currentRow - 1>
		</cfif>

		<cfreturn rowAt(result, this.currentRow)>
	</cffunction>

	<!---
	 * Returns an unbuffered row and move the pointer to the next row.
	 *
	 * @return array|object|null
	--->
	<cffunction name="getUnbufferedRow" access="public" returntype="any" output="no">
		<cfargument name="type" type="string" required="no" default="object">

		<cfif Compare(arguments.type, "array") EQ 0>
			<cfreturn fetchAssoc()>
		</cfif>

		<cfif Compare(arguments.type, "object") EQ 0>
			<cfreturn fetchObject()>
		</cfif>

		<cfreturn fetchObject(arguments.type)>
	</cffunction>

	<!---
	 * Number of rows in the result set; checks for previous count, falls
	 * back on counting resultArray or resultObject, finally fetching resultArray
	 * if nothing was previously fetched
	--->
	<cffunction name="getNumRows" access="public" returntype="numeric" output="no">

		<cfif NOT (IsSimpleValue(this.numRows) AND this.numRows EQ "")>
			<cfreturn this.numRows>
		</cfif>

		<cfif ArrayLen(this.resultArray) GT 0>
			<cfset this.numRows = ArrayLen(this.resultArray)>

			<cfreturn this.numRows>
		</cfif>

		<cfif ArrayLen(this.resultObject) GT 0>
			<cfset this.numRows = ArrayLen(this.resultObject)>

			<cfreturn this.numRows>
		</cfif>

		<cfset this.numRows = ArrayLen(this.getResultArray())>

		<cfreturn this.numRows>
	</cffunction>

	<!---
	 * Gets the number of fields in the result set.
	 *
	 * Overridden by driver classes.
	--->
	<cffunction name="getFieldCount" access="public" returntype="numeric" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getFieldCount().">
	</cffunction>

	<!---
	 * Generates an array of column names in the result set.
	 *
	 * Overridden by driver classes.
	--->
	<cffunction name="getFieldNames" access="public" returntype="array" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getFieldNames().">
	</cffunction>

	<!---
	 * Generates an array of objects representing field meta-data.
	 *
	 * Overridden by driver classes.
	--->
	<cffunction name="getFieldData" access="public" returntype="array" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getFieldData().">
	</cffunction>

	<!---
	 * Frees the current result.
	 *
	 * Overridden by driver classes.
	--->
	<cffunction name="freeResult" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define freeResult().">
	</cffunction>

	<!---
	 * Moves the internal pointer to the desired offset. This is called
	 * internally before fetching results to make sure the result set
	 * starts at zero.
	 *
	 * Overridden by driver classes.
	--->
	<cffunction name="dataSeek" access="public" returntype="any" output="no">
		<cfargument name="n" type="numeric" required="no" default="0">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define dataSeek().">
	</cffunction>

	<!---
	 * Tells if the result of the query can be read: a resource or an
	 * object in the original.
	--->
	<cffunction name="isValidResultId" access="private" returntype="boolean" output="no">

		<cfreturn IsObject(this.resultID) OR IsQuery(this.resultID) OR IsStruct(this.resultID)>
	</cffunction>

	<!---
	 * Returns the result set as an array.
	 *
	 * Overridden by driver classes.
	 *
	 * @return array<string, mixed>|false|null
	--->
	<cffunction name="fetchAssoc" access="private" returntype="any" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define fetchAssoc().">
	</cffunction>

	<!---
	 * Returns the result set as an object.
	 *
	 * Overridden by driver classes.
	 *
	 * @param class-string $className
	 *
	 * @return false|object
	--->
	<cffunction name="fetchObject" access="private" returntype="any" output="no">
		<cfargument name="className" type="string" required="no" default="">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define fetchObject().">
	</cffunction>

	<!---
	 * Tells if a row that was fetched is a row: a map with a key. The
	 * original loops while the row is not false, null or an empty array.
	 *
	 * Not in the original.
	--->
	<cffunction name="isRow" access="private" returntype="boolean" output="no">
		<cfargument name="row" type="any" required="yes">

		<cfif NOT isMap(arguments.row)>
			<cfreturn false>
		</cfif>

		<cfreturn arguments.row.size() GT 0>
	</cffunction>

	<!---
	 * Tells if a value is a map (not a component), so a row.
	 *
	 * Not in the original.
	--->
	<cffunction name="isMap" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfreturn IsStruct(arguments.value) AND NOT IsObject(arguments.value)>
	</cffunction>

	<!---
	 * Copies a row, so that a change of one does not change the other,
	 * as an array does in the original. A null stays a null.
	 *
	 * Not in the original.
	--->
	<cffunction name="copyRow" access="private" returntype="any" output="no">
		<cfargument name="row" type="any" required="yes">
		<cfset var copy = "">
		<cfset var keys = "">
		<cfset var i = 0>

		<cfif NOT isMap(arguments.row)>
			<cfreturn arguments.row>
		</cfif>

		<cfset copy = array_()>
		<cfset keys = array_keys(arguments.row)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset copy[keys[i]] = arguments.row[keys[i]]>
		</cfloop>

		<cfreturn copy>
	</cffunction>

	<!---
	 * Tells if the list has a row at a position that starts at 0, as the
	 * original does with isset().
	 *
	 * Not in the original.
	--->
	<cffunction name="rowExists" access="private" returntype="boolean" output="no">
		<cfargument name="result" type="array" required="yes">
		<cfargument name="n" type="numeric" required="yes">

		<cfreturn arguments.n GTE 0 AND arguments.n LT ArrayLen(arguments.result)>
	</cffunction>

	<!---
	 * Gives the row at a position that starts at 0, or null.
	 *
	 * Not in the original.
	--->
	<cffunction name="rowAt" access="private" returntype="any" output="no">
		<cfargument name="result" type="array" required="yes">
		<cfargument name="n" type="numeric" required="yes">

		<cfif NOT rowExists(arguments.result, arguments.n)>
			<cfreturn "">
		</cfif>

		<cfreturn arguments.result[arguments.n + 1]>
	</cffunction>

</cfcomponent>
