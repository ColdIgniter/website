<!---
 * Result for SQLSRV
 *
 * The result is the query that the data source gave (see Connection).
 *
 * Difference: the original extends BaseResult. This class is in another
 * folder, so it is mixed in with parent (see the reference, "How
 * components are located").
 *
 * Difference: a row is a map (see array_()) with the column names in the
 * case of the database. They come from the metadata of the query
 * (getMetaData()). If that fails, they are in upper case, as
 * getColumnNames() gives them.
 *
 * Difference: a NULL and an empty string are the same in a query of 6.1.
 * A NULL is an empty string, and its key is in the row. A value of a date
 * column is what the data source gives, not a text.
 *
 * Difference: getFieldData() reads the metadata of the query with
 * getMetaData(). The type is the JDBC type code, type_name is the name of
 * the type in lower case and max_length is the precision. A value the
 * metadata does not give is an empty string: the metadata of a query of
 * 6.1 has no precision, so max_length is empty (verified on the server). The type constants of the
 * original (SQLSRV_SQLTYPE_*) do not exist.
 *
 * Difference: fetchObject() returns a map when there is no class (or the
 * class stdClass), as there is no stdClass. For an Entity class it returns
 * the object with the raw data injected (injectRawData()), and for any other
 * class an object with the keys of the row set.
--->
<cfcomponent output="no" parent="ColdIgniter\Database\BaseResult" hint="Result for SQLSRV">

	<!---
	 * The number of rows that were read, or skipped.
	 *
	 * Not in the original.
	 *
	 * @var int
	--->
	<cfset this.fetchPosition = 0>

	<!---
	 * The names of the columns, once they were read (see columnNames()).
	 *
	 * Not in the original.
	 *
	 * @var list<string>|string
	--->
	<cfset this.columnNames_ = "">

	<!---
	 * Gets the number of fields in the result set.
	--->
	<cffunction name="getFieldCount" access="public" returntype="numeric" output="no">
		<cfif NOT isValidResultId()>
			<cfreturn 0>
		</cfif>

		<cfreturn ArrayLen(columnNames())>
	</cffunction>

	<!---
	 * Generates an array of column names in the result set.
	 *
	 * @return list<string>
	--->
	<cffunction name="getFieldNames" access="public" returntype="array" output="no">
		<cfif NOT isValidResultId()>
			<cfreturn ArrayNew(1)>
		</cfif>

		<cfreturn columnNames()>
	</cffunction>

	<!---
	 * Generates an array of objects representing field meta-data.
	 *
	 * @return list<stdClass> A list of maps of name, type, type_name and max_length
	--->
	<cffunction name="getFieldData" access="public" returntype="array" output="no">
		<cfset var names = ArrayNew(1)>
		<cfset var retVal = ArrayNew(1)>
		<cfset var meta = "">
		<cfset var obj = "">
		<cfset var type = "">
		<cfset var typeName = "">
		<cfset var size = "">
		<cfset var i = 0>

		<cfif NOT isValidResultId()>
			<cfreturn retVal>
		</cfif>

		<cfset names = columnNames()>

		<cftry>
			<cfset meta = this.resultID.getMetaData()>

			<cfcatch type="any">
				<cfset meta = "">
			</cfcatch>
		</cftry>

		<cfloop from="1" to="#ArrayLen(names)#" index="i">
			<cfset type = "">
			<cfset typeName = "">
			<cfset size = "">

			<cfif NOT IsSimpleValue(meta)>
				<cftry>
					<cfset type = meta.getColumnType(JavaCast("int", i))>
					<cfset typeName = LCase(meta.getColumnTypeName(JavaCast("int", i)))>
					<cfset size = meta.getPrecision(JavaCast("int", i))>

					<cfcatch type="any">
					</cfcatch>
				</cftry>
			</cfif>

			<cfset obj = array_("name", names[i], "type", type, "type_name", typeName, "max_length", size)>
			<cfset ArrayAppend(retVal, obj)>
		</cfloop>

		<cfreturn retVal>
	</cffunction>

	<!---
	 * Frees the current result.
	--->
	<cffunction name="freeResult" access="public" returntype="void" output="no">
		<cfif isValidResultId()>
			<cfset this.resultID = "false">
		</cfif>
	</cffunction>

	<!---
	 * Moves the internal pointer to the desired offset. This is called
	 * internally before fetching results to make sure the result set
	 * starts at zero.
	 *
	 * @return bool
	--->
	<cffunction name="dataSeek" access="public" returntype="any" output="no">
		<cfargument name="n" type="numeric" required="no" default="0">

		<cfif arguments.n GT 0>
			<cfif NOT isValidResultId()>
				<cfreturn false>
			</cfif>

			<cfif this.fetchPosition + arguments.n GT this.resultID.recordCount>
				<cfreturn false>
			</cfif>

			<cfset this.fetchPosition = this.fetchPosition + arguments.n>
		</cfif>

		<cfreturn true>
	</cffunction>

	<!---
	 * Leaves out the first rows of the result. The Builder uses it for an
	 * offset, as SQL Server 2000 has no OFFSET (see Builder).
	 *
	 * Not in the original.
	--->
	<cffunction name="skipRows" access="public" returntype="void" output="no">
		<cfargument name="n" type="numeric" required="yes">

		<cfif NOT isValidResultId() OR arguments.n LTE 0>
			<cfreturn>
		</cfif>

		<cfset this.fetchPosition = Min(arguments.n, this.resultID.recordCount)>
		<cfset this.numRows = this.resultID.recordCount - this.fetchPosition>
	</cffunction>

	<!---
	 * Returns the result set as an array.
	 *
	 * Overridden by driver classes.
	 *
	 * @return A map of the next row, or an empty string
	--->
	<cffunction name="fetchAssoc" access="private" returntype="any" output="no">
		<cfset var names = "">
		<cfset var row = "">
		<cfset var position = this.fetchPosition + 1>
		<cfset var i = 0>

		<cfif NOT isValidResultId()>
			<cfreturn "">
		</cfif>

		<cfif position GT this.resultID.recordCount>
			<cfreturn "">
		</cfif>

		<cfset names = columnNames()>
		<cfset row = array_()>

		<cfloop from="1" to="#ArrayLen(names)#" index="i">
			<cfset row[names[i]] = this.resultID[UCase(names[i])][position]>
		</cfloop>

		<cfset this.fetchPosition = position>

		<cfreturn row>
	</cffunction>

	<!---
	 * Returns the result set as an object.
	 *
	 * Overridden by driver classes.
	 *
	 * @return A map of the next row, or an empty string
	--->
	<cffunction name="fetchObject" access="private" returntype="any" output="no">
		<cfargument name="className" type="string" required="no" default="">
		<cfset var data = fetchAssoc()>
		<cfset var obj = "">
		<cfset var keys = "">
		<cfset var i = 0>

		<cfif NOT isRow(data) OR Len(arguments.className) EQ 0 OR Compare(arguments.className, "stdClass") EQ 0>
			<cfreturn data>
		</cfif>

		<cfset obj = new_(arguments.className)>

		<cfif instanceof_(obj, "Entity")>
			<cfreturn obj.injectRawData(data)>
		</cfif>

		<cfset keys = array_keys(data)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset obj[keys[i]] = data[keys[i]]>
		</cfloop>

		<cfreturn obj>
	</cffunction>

	<!---
	 * Returns the number of rows in the result set.
	--->
	<cffunction name="getNumRows" access="public" returntype="numeric" output="no">
		<cfif is_null(this.numRows)>
			<cfif NOT isValidResultId()>
				<cfreturn 0>
			</cfif>

			<cfset this.numRows = this.resultID.recordCount>
		</cfif>

		<cfreturn this.numRows>
	</cffunction>

	<!---
	 * The names of the columns, in the case of the database if the query
	 * gives them.
	 *
	 * Not in the original.
	 *
	 * @return list<string>
	--->
	<cffunction name="columnNames" access="private" returntype="array" output="no">
		<cfset var names = ArrayNew(1)>
		<cfset var meta = "">
		<cfset var i = 0>

		<cfif IsArray(this.columnNames_)>
			<cfreturn this.columnNames_>
		</cfif>

		<!---
		 The metadata of the query has the names as the database wrote them.
		 getColumnNames() and columnList give upper case (verified on the
		 server).
		--->
		<cftry>
			<cfset meta = this.resultID.getMetaData()>

			<cfloop from="1" to="#meta.getColumnCount()#" index="i">
				<cfset ArrayAppend(names, meta.getColumnLabel(JavaCast("int", i)))>
			</cfloop>

			<cfcatch type="any">
				<cfset names = this.resultID.getColumnNames()>
			</cfcatch>
		</cftry>

		<cfset this.columnNames_ = names>

		<cfreturn names>
	</cffunction>

</cfcomponent>
