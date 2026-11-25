<!---
 * Class Model
 *
 * The Model class extends BaseModel and provides additional
 * convenient features that makes working with a SQL database
 * table less painful.
 *
 * It will:
 *      - automatically connect to database
 *      - allow intermingling calls to the builder
 *      - removes the need to use Result object directly in most cases
 *
 * A model of the application is a component that mixes this one in:
 *
 *     <cfcomponent output="no" parent="ColdIgniter\Model">
 *         <cfset this.table = "users">
 *         <cfset this.allowedFields = ListToArray("name,email")>
 *     </cfcomponent>
 *
 * Difference: a model has no magic methods here (the language has none). The
 * methods of the builder that a model does not define itself are written out
 * below as public methods that hand the call over to the builder: where(),
 * orderBy(), limit(), groupStart() and the others. They return the model
 * itself when the builder returns a builder, and the result otherwise, as the
 * original __call() does. The same is done for the usual methods of the
 * connection (query(), transStart(), tableExists(), getLastQuery(),
 * prefixTable() and the others). insertID() is not one of them, as the
 * property insertID has that name: use getInsertID(). The
 * arguments of these methods are passed by position, not by name. For any
 * other method of the builder or the connection, and for the properties, call
 * __call(name, listOfArguments), __get(name) and __isset(name) by name.
 *
 * Difference: the methods getCompiledInsert(), getCompiledSelect() and
 * getCompiledUpdate() of the builder are refused, as in the original, and
 * throw a ModelException.
 *
 * Difference: the property builder is named builder_, as this.builder() is a
 * method.
 *
 * Difference: the original clones the builder in chunk() so that each
 * batch is read with a copy. There is no clone here, so the batches are read
 * from the shared builder without a reset, and the builder is reset when the
 * loop is over.
 *
 * Difference: an update that has no id (it uses the where() of the builder)
 * is written update(row=row), with the argument named.
 *
 * @see \CodeIgniter\Model
--->
<cfcomponent output="no" extends="BaseModel" hint="Convenient features for working with a SQL database table">

	<!---
	 * Name of database table.
	 *
	 * @var string
	--->
	<cfset this.table = "">

	<!---
	 * The table's primary key.
	 *
	 * @var string
	--->
	<cfset this.primaryKey = "id">

	<!---
	 * Whether primary key uses auto increment.
	 *
	 * @var bool
	--->
	<cfset this.useAutoIncrement = "true">

	<!---
	 * Query Builder object.
	 *
	 * Named with an underscore, as this.builder() is a method.
	 *
	 * @var BaseBuilder|null
	--->
	<cfset this.builder_ = "">

	<!---
	 * Holds information passed in via 'set'
	 * so that we can capture it (not the builder)
	 * and ensure it gets validated first.
	 *
	 * A map that is empty, or has the keys "escape" (a map) and "data" (a map).
	--->
	<cfset this.tempData = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Escape array that maps usage of escape
	 * flag for every parameter.
	 *
	 * An empty string is null.
	 *
	 * @var array<array-key, bool|null>
	--->
	<cfset this.escape = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Builder method names that should not be used in the Model.
	 *
	 * @var list<string>
	--->
	<cfset this.builderMethodsNotAvailable = ListToArray("getCompiledInsert,getCompiledSelect,getCompiledUpdate")>

	<!---
	 * @param db         The connection, or omitted for the one of $this->DBGroup
	 * @param validation The validation object, or omitted for none
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="db" type="any" required="no" default="">
		<cfargument name="validation" type="any" required="no" default="">
		<cfset var db_ = arguments.db>

		<cfif NOT IsObject(db_)>
			<cfset db_ = db_connect(this.DBGroup)>
		</cfif>

		<cfset this.db = db_>

		<cfreturn construct_(arguments.validation)>
	</cffunction>

	<!---
	 * Specify the table associated with a model.
	 *
	 * @return $this
	--->
	<cffunction name="setTable" access="public" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">

		<cfset this.table = arguments.table>

		<cfreturn this>
	</cffunction>

	<cffunction name="doFind" access="private" returntype="any" output="no">
		<cfargument name="singleton" type="boolean" required="yes">
		<cfargument name="id" type="any" required="yes">
		<cfset var builder = this.builder()>
		<cfset var useCast = useCasts()>
		<cfset var returnType = "">
		<cfset var row = "">
		<cfset var rows = ArrayNew(1)>
		<cfset var i = 0>

		<cfif useCast>
			<cfset returnType = this.tempReturnType>
			<cfset asArray()>
		</cfif>

		<cfif truthy_(this.tempUseSoftDeletes)>
			<cfset builder.where("#this.table#.#this.deletedField#")>
		</cfif>

		<cfif isArr_(arguments.id)>
			<cfset builder.whereIn("#this.table#.#this.primaryKey#", arguments.id)>
			<cfset rows = builder.get().getResult(this.tempReturnType)>
		<cfelseif arguments.singleton>
			<cfset builder.where("#this.table#.#this.primaryKey#", arguments.id)>
			<cfset row = builder.get().getFirstRow(this.tempReturnType)>
		<cfelse>
			<cfset rows = builder.get().getResult(this.tempReturnType)>
		</cfif>

		<cfif useCast>
			<cfset this.tempReturnType = returnType>

			<cfif arguments.singleton>
				<cfif isEmpty_(row)>
					<cfreturn "">
				</cfif>

				<cfreturn convertToReturnType(row, returnType)>
			</cfif>

			<cfloop from="1" to="#ArrayLen(rows)#" index="i">
				<cfset rows[i] = convertToReturnType(rows[i], returnType)>
			</cfloop>

			<cfreturn rows>
		</cfif>

		<cfif arguments.singleton>
			<cfreturn row>
		</cfif>

		<cfreturn rows>
	</cffunction>

	<cffunction name="doFindColumn" access="private" returntype="any" output="no">
		<cfargument name="columnName" type="string" required="yes">

		<cfset select(arguments.columnName)>
		<cfset asArray()>

		<cfreturn find_()>
	</cffunction>

	<!---
	 * {@inheritDoc}
	 *
	 * Works with the current Query Builder instance.
	--->
	<cffunction name="doFindAll" access="private" returntype="any" output="no">
		<cfargument name="limit_" type="any" required="yes">
		<cfargument name="offset_" type="any" required="yes">
		<cfset var limit = arguments.limit_>
		<cfset var builder = "">
		<cfset var useCast = useCasts()>
		<cfset var returnType = "">
		<cfset var results = "">
		<cfset var i = 0>

		<!--- Config\Feature.limitZeroAsAll is not ported yet, it is always true --->
		<cfif is_null(limit)>
			<cfset limit = 0>
		</cfif>

		<cfset builder = this.builder()>

		<cfif useCast>
			<cfset returnType = this.tempReturnType>
			<cfset asArray()>
		</cfif>

		<cfif truthy_(this.tempUseSoftDeletes)>
			<cfset builder.where("#this.table#.#this.deletedField#")>
		</cfif>

		<cfset builder.limit(limit, arguments.offset_)>
		<cfset results = builder.get().getResult(this.tempReturnType)>

		<cfif useCast>
			<cfloop from="1" to="#ArrayLen(results)#" index="i">
				<cfset results[i] = convertToReturnType(results[i], returnType)>
			</cfloop>

			<cfset this.tempReturnType = returnType>
		</cfif>

		<cfreturn results>
	</cffunction>

	<!---
	 * {@inheritDoc}
	 *
	 * Will take any previous Query Builder calls into account
	 * when determining the result set.
	--->
	<cffunction name="doFirst" access="private" returntype="any" output="no">
		<cfset var builder = this.builder()>
		<cfset var useCast = useCasts()>
		<cfset var returnType = "">
		<cfset var row = "">

		<cfif useCast>
			<cfset returnType = this.tempReturnType>
			<cfset asArray()>
		</cfif>

		<cfif truthy_(this.tempUseSoftDeletes)>
			<cfset builder.where("#this.table#.#this.deletedField#")>
		<cfelseif truthy_(this.useSoftDeletes) AND ArrayLen(builder.QBGroupBy) EQ 0 AND Len(this.primaryKey) GT 0>
			<cfset builder.groupBy("#this.table#.#this.primaryKey#")>
		</cfif>

		<!---
		 * Some databases, like PostgreSQL, need order
		 * information to consistently return correct results.
		--->
		<cfif ArrayLen(builder.QBGroupBy) GT 0 AND ArrayLen(builder.QBOrderBy) EQ 0 AND Len(this.primaryKey) GT 0>
			<cfset builder.orderBy("#this.table#.#this.primaryKey#", "asc")>
		</cfif>

		<cfset builder.limit(1, 0)>
		<cfset row = builder.get().getFirstRow(this.tempReturnType)>

		<cfif useCast AND NOT isEmpty_(row)>
			<cfset row = convertToReturnType(row, returnType)>

			<cfset this.tempReturnType = returnType>
		</cfif>

		<cfreturn row>
	</cffunction>

	<cffunction name="doInsert" access="private" returntype="any" output="no">
		<cfargument name="row" type="any" required="yes">
		<cfset var escape_ = this.escape>
		<cfset var builder = "">
		<cfset var keys = array_keys(arguments.row)>
		<cfset var key = "">
		<cfset var escapeValue = "">
		<cfset var table = "">
		<cfset var sql = "">
		<cfset var allFields = ArrayNew(1)>
		<cfset var fieldData = "">
		<cfset var marks = ArrayNew(1)>
		<cfset var result = "">
		<cfset var i = 0>

		<cfset this.escape = array_()>

		<!---
		 * Require non-empty primaryKey when
		 * not using auto-increment feature
		--->
		<cfif NOT truthy_(this.useAutoIncrement)>
			<cfif NOT isSet_(arguments.row, this.primaryKey)>
				<cfset static_("ColdIgniter\Database\Exceptions\DataException").forEmptyPrimaryKey("insert")>
			</cfif>

			<!--- Validate the primary key value (arrays not allowed for insert) --->
			<cfset validateID(arguments.row[this.primaryKey], false)>
		</cfif>

		<cfset builder = this.builder()>

		<!--- Must use the set() method to ensure to set the correct escape flag --->
		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset key = keys[i]>
			<cfset escapeValue = "">

			<cfif array_key_exists(key, escape_)>
				<cfset escapeValue = escape_[key]>
			</cfif>

			<cfset builder.set(key, arguments.row[key], escapeValue)>
		</cfloop>

		<cfif truthy_(this.allowEmptyInserts_) AND isEmpty_(arguments.row)>
			<cfset table = this.db.protectIdentifiers(this.table, true, "", "false")>

			<cfif Compare(this.db.getPlatform(), "MySQLi") EQ 0>
				<cfset sql = "INSERT INTO #table# VALUES ()">
			<cfelseif Compare(this.db.getPlatform(), "OCI8") EQ 0>
				<cfset fieldData = this.db.getFieldData(this.table)>

				<cfloop from="1" to="#ArrayLen(fieldData)#" index="i">
					<cfset ArrayAppend(allFields, this.db.protectIdentifiers(fieldData[i]["name"], false, "true"))>
					<cfset ArrayAppend(marks, "DEFAULT")>
				</cfloop>

				<cfset sql = "INSERT INTO #table# (#ArrayToList(allFields)#) VALUES (#ArrayToList(marks)#)">
			<cfelse>
				<cfset sql = "INSERT INTO #table# DEFAULT VALUES">
			</cfif>

			<cfset result = this.db.query(sql)>
		<cfelse>
			<cfset result = builder.insert_()>
		</cfif>

		<!--- If insertion succeeded then save the insert ID --->
		<cfif truthy_(result)>
			<cfif truthy_(this.useAutoIncrement)>
				<cfset this.insertID = this.db.insertID()>
			<cfelse>
				<cfset this.insertID = arguments.row[this.primaryKey]>
			</cfif>
		</cfif>

		<cfreturn result>
	</cffunction>

	<cffunction name="doInsertBatch" access="private" returntype="any" output="no">
		<cfargument name="set_" type="any" required="yes">
		<cfargument name="escape" type="any" required="yes">
		<cfargument name="batchSize" type="numeric" required="yes">
		<cfargument name="testing" type="boolean" required="yes">
		<cfset var builder = "">
		<cfset var row = "">
		<cfset var i = 0>

		<cfif IsArray(arguments.set_) AND NOT truthy_(this.useAutoIncrement)>
			<cfloop from="1" to="#ArrayLen(arguments.set_)#" index="i">
				<cfset row = arguments.set_[i]>

				<!---
				 * Require non-empty $primaryKey when
				 * not using auto-increment feature
				--->
				<cfif NOT isSet_(row, this.primaryKey)>
					<cfset static_("ColdIgniter\Database\Exceptions\DataException").forEmptyPrimaryKey("insertBatch")>
				</cfif>

				<!--- Validate the primary key value --->
				<cfset validateID(row[this.primaryKey], false)>
			</cfloop>
		</cfif>

		<cfset builder = this.builder()>
		<cfset builder.testMode(arguments.testing)>

		<cfreturn builder.insertBatch(arguments.set_, arguments.escape, arguments.batchSize)>
	</cffunction>

	<cffunction name="doUpdate" access="private" returntype="boolean" output="no">
		<cfargument name="id" type="any" required="yes">
		<cfargument name="row" type="any" required="yes">
		<cfset var escape_ = this.escape>
		<cfset var builder = "">
		<cfset var keys = array_keys(arguments.row)>
		<cfset var key = "">
		<cfset var escapeValue = "">
		<cfset var i = 0>

		<cfset this.escape = array_()>

		<cfset builder = this.builder()>

		<cfif isArr_(arguments.id) AND NOT isEmpty_(arguments.id)>
			<cfset builder.whereIn("#this.table#.#this.primaryKey#", arguments.id)>
		</cfif>

		<!--- Must use the set() method to ensure to set the correct escape flag --->
		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset key = keys[i]>
			<cfset escapeValue = "">

			<cfif array_key_exists(key, escape_)>
				<cfset escapeValue = escape_[key]>
			</cfif>

			<cfset builder.set(key, arguments.row[key], escapeValue)>
		</cfloop>

		<cfif ArrayLen(builder.getCompiledQBWhere()) EQ 0>
			<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="Updates are not allowed unless they contain a ""where"" or ""like"" clause.">
		</cfif>

		<cfreturn truthy_(builder.update())>
	</cffunction>

	<cffunction name="doUpdateBatch" access="private" returntype="any" output="no">
		<cfargument name="set_" type="any" required="yes">
		<cfargument name="index" type="any" required="yes">
		<cfargument name="batchSize" type="numeric" required="yes">
		<cfargument name="returnSQL" type="boolean" required="yes">
		<cfset var builder = this.builder()>

		<cfset builder.testMode(arguments.returnSQL)>

		<cfreturn builder.updateBatch(arguments.set_, arguments.index, arguments.batchSize)>
	</cffunction>

	<cffunction name="doDelete" access="private" returntype="any" output="no">
		<cfargument name="id" type="any" required="yes">
		<cfargument name="purge" type="boolean" required="yes">
		<cfset var set_ = array_()>
		<cfset var builder = this.builder()>

		<cfif isArr_(arguments.id) AND NOT isEmpty_(arguments.id)>
			<cfset builder.whereIn(this.primaryKey, arguments.id)>
		</cfif>

		<cfif truthy_(this.useSoftDeletes) AND NOT arguments.purge>
			<cfif ArrayLen(builder.getCompiledQBWhere()) EQ 0>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="Deletes are not allowed unless they contain a ""where"" or ""like"" clause.">
			</cfif>

			<cfset builder.where(this.deletedField)>

			<cfset set_[this.deletedField] = setDate()>

			<cfif truthy_(this.useTimestamps) AND Len(this.updatedField) GT 0>
				<cfset set_[this.updatedField] = setDate()>
			</cfif>

			<cfreturn builder.update(set_)>
		</cfif>

		<cfreturn builder.delete()>
	</cffunction>

	<cffunction name="doPurgeDeleted" access="private" returntype="any" output="no">
		<cfset var builder = this.builder()>

		<cfset builder.where("#this.table#.#this.deletedField# IS NOT NULL")>

		<cfreturn builder.delete()>
	</cffunction>

	<cffunction name="doOnlyDeleted" access="private" returntype="void" output="no">
		<cfset var builder = this.builder()>

		<cfset builder.where("#this.table#.#this.deletedField# IS NOT NULL")>
	</cffunction>

	<cffunction name="doReplace" access="private" returntype="any" output="no">
		<cfargument name="row" type="any" required="yes">
		<cfargument name="returnSQL" type="boolean" required="yes">
		<cfset var builder = this.builder()>

		<cfset builder.testMode(arguments.returnSQL)>

		<cfreturn builder.replace_(arguments.row)>
	</cffunction>

	<!---
	 * {@inheritDoc}
	 *
	 * The return map should be in the following format:
	 *  `['source' => 'message']`.
	 * This method works only with dbCalls.
	--->
	<cffunction name="doErrors" access="private" returntype="any" output="no">
		<cfset var error = this.db.error()>
		<cfset var result = array_()>

		<!--- $error is always ['code' => string|int, 'message' => string] --->
		<cfif Val(error["code"]) EQ 0>
			<cfreturn result>
		</cfif>

		<cfset result[GetMetaData(this.db).name] = error["message"]>

		<cfreturn result>
	</cffunction>

	<!---
	 * Returns the primary key value of a row, or an empty string (null).
	 *
	 * Difference: an object that is not an Entity is read by its key (there
	 * is no isset() of a property), and the magic methods of an Entity are
	 * written out (__get()).
	--->
	<cffunction name="getIdValue" access="public" returntype="any" output="no">
		<cfargument name="row" type="any" required="yes">
		<cfset var cast = "">
		<cfset var primaryKey = "">

		<cfif IsObject(arguments.row) AND NOT isNullMarker_(arguments.row)>
			<!--- get the raw or mapped primary key value of the Entity --->
			<cfif instanceof_(arguments.row, "Entity")>
				<cfif NOT is_null(arguments.row.__get(this.primaryKey))>
					<cfset cast = arguments.row.cast()>

					<!--- disable Entity casting, because raw primary key value is needed for database --->
					<cfset arguments.row.cast(false)>

					<cfset primaryKey = arguments.row.__get(this.primaryKey)>

					<!--- restore Entity casting setting --->
					<cfset arguments.row.cast(cast)>

					<cfreturn primaryKey>
				</cfif>
			<cfelseif StructKeyExists(arguments.row, this.primaryKey) AND NOT IsCustomFunction(arguments.row[this.primaryKey])>
				<cfif NOT isNullMarker_(arguments.row[this.primaryKey])>
					<cfreturn arguments.row[this.primaryKey]>
				</cfif>
			</cfif>
		</cfif>

		<cfif isMap_(arguments.row) AND isSet_(arguments.row, this.primaryKey)>
			<cfreturn arguments.row[this.primaryKey]>
		</cfif>

		<cfreturn "">
	</cffunction>

	<cffunction name="countAllResults" access="public" returntype="any" output="no">
		<cfargument name="reset" type="boolean" required="no" default="true">
		<cfargument name="test" type="boolean" required="no" default="false">
		<cfset var builder = "">

		<cfif truthy_(this.tempUseSoftDeletes)>
			<cfset builder = this.builder()>
			<cfset builder.where("#this.table#.#this.deletedField#")>
		</cfif>

		<!---
		 * When $reset === false, the $tempUseSoftDeletes will be
		 * dependent on $useSoftDeletes value because we don't
		 * want to add the same "where" condition for the second time.
		--->
		<cfif arguments.reset>
			<cfset this.tempUseSoftDeletes = this.useSoftDeletes>
		<cfelseif truthy_(this.useSoftDeletes)>
			<cfset this.tempUseSoftDeletes = "false">
		<cfelse>
			<cfset this.tempUseSoftDeletes = this.useSoftDeletes>
		</cfif>

		<cfset builder = this.builder()>
		<cfset builder.testMode(arguments.test)>

		<cfreturn builder.countAllResults(arguments.reset)>
	</cffunction>

	<!---
	 * {@inheritDoc}
	 *
	 * Works with `$this->builder` to get the Compiled select to
	 * determine the rows to operate on.
	 * This method works only with dbCalls.
	 *
	 * @param userFunc A list of an object and the name of one of its public methods,
	 *                 that gets a row and returns false to stop the loop
	--->
	<cffunction name="chunk" access="public" returntype="void" output="no">
		<cfargument name="size" type="numeric" required="yes">
		<cfargument name="userFunc" type="any" required="yes">
		<cfset var builder = "">
		<cfset var total = 0>
		<cfset var offset = 0>
		<cfset var rows = "">
		<cfset var row = "">
		<cfset var cbObject = "">
		<cfset var cbName = "">
		<cfset var outcome = "">
		<cfset var stop = "false">
		<cfset var i = 0>

		<cfif arguments.size LTE 0>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="chunk() requires a positive integer for the $size argument.">
		</cfif>

		<cfif NOT IsArray(arguments.userFunc) OR ArrayLen(arguments.userFunc) NEQ 2 OR NOT IsObject(arguments.userFunc[1]) OR NOT IsSimpleValue(arguments.userFunc[2]) OR REFind("^[A-Za-z_][A-Za-z0-9_]*$", arguments.userFunc[2]) EQ 0 OR NOT method_exists(arguments.userFunc[1], arguments.userFunc[2])>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="chunk() requires a list of an object and the name of one of its public methods for the $userFunc argument.">
		</cfif>

		<cfset cbObject = arguments.userFunc[1]>
		<cfset cbName = arguments.userFunc[2]>

		<cfset builder = this.builder()>
		<cfset total = builder.countAllResults(false)>

		<!---
		 * The rows are read from the shared builder without a reset (see the
		 * header), so after an error of the callback the builder is reset
		 * here, and the next query of the model starts clean.
		--->
		<cftry>
		<cfloop condition="offset LT total AND NOT stop">
			<cfset rows = builder.get(arguments.size, offset, false)>

			<cfif NOT IsObject(rows)>
				<cfset builder.resetQuery()>
				<cfset static_("ColdIgniter\Database\Exceptions\DataException").forEmptyDataset("chunk")>
			</cfif>

			<cfset rows = rows.getResult(this.tempReturnType)>

			<cfset offset = offset + arguments.size>

			<cfif ArrayLen(rows) GT 0>
				<cfloop from="1" to="#ArrayLen(rows)#" index="i">
					<cfset row = rows[i]>
					<cfset outcome = Evaluate("cbObject.#cbName#(row)")>

					<!--- a boolean of an expression reads NO, so the text is not compared; a number is not a boolean --->
					<cfif IsDefined("outcome") AND IsSimpleValue(outcome) AND IsBoolean(outcome) AND NOT IsNumeric(outcome) AND NOT outcome>
						<cfset stop = "true">
						<cfbreak>
					</cfif>
				</cfloop>
			</cfif>
		</cfloop>

			<cfcatch type="any">
				<cfset builder.resetQuery()>
				<cfrethrow>
			</cfcatch>
		</cftry>

		<cfset builder.resetQuery()>
	</cffunction>

	<!---
	 * Provides a shared instance of the Query Builder.
	 *
	 * @param table The table, or omitted for the table of the model
	 *
	 * @return BaseBuilder
	 *
	 * @throws ModelException
	--->
	<cffunction name="builder" access="public" returntype="any" output="no">
		<cfargument name="table" type="string" required="no" default="">
		<cfset var table_ = arguments.table>
		<cfset var builder_ = "">

		<!--- Check for an existing Builder --->
		<cfif instanceof_(this.builder_, "BaseBuilder")>
			<!--- Make sure the requested table matches the builder --->
			<cfif Len(table_) GT 0 AND Compare(this.builder_.getTable(), table_) NEQ 0>
				<cfreturn this.db.table(table_)>
			</cfif>

			<cfreturn this.builder_>
		</cfif>

		<!---
		 * We're going to force a primary key to exist
		 * so we don't have overly convoluted code,
		 * and future features are likely to require them.
		--->
		<cfif Len(this.primaryKey) EQ 0>
			<cfset static_("ColdIgniter\Exceptions\ModelException").forNoPrimaryKey(className_())>
		</cfif>

		<cfif Len(table_) EQ 0>
			<cfset table_ = this.table>
		</cfif>

		<!--- Ensure we have a good db connection --->
		<cfif NOT instanceof_(this.db, "BaseConnection")>
			<cfset this.db = db_connect(this.DBGroup)>
		</cfif>

		<cfset builder_ = this.db.table(table_)>

		<!--- Only consider it "shared" if the table is correct --->
		<cfif Compare(table_, this.table) EQ 0>
			<cfset this.builder_ = builder_>
		</cfif>

		<cfreturn builder_>
	</cffunction>

	<!---
	 * Captures the builder's set() method so that we can validate the
	 * data here. This allows it to be used with any of the other
	 * builder methods and still get validated data, like replace.
	 *
	 * @param key    Field name, or a map of field/value pairs, or an object
	 * @param value  Field value, if $key is a single field
	 * @param escape Whether to escape values, an empty string is null
	 *
	 * @return $this
	--->
	<cffunction name="set" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfargument name="value" type="any" required="no" default="">
		<cfargument name="escape" type="any" required="no" default="">
		<cfset var key_ = arguments.key>
		<cfset var data = "">
		<cfset var keys = "">
		<cfset var i = 0>

		<cfif IsObject(key_)>
			<cfset key_ = objectToArray(key_)>
		</cfif>

		<cfif isMap_(key_)>
			<cfset data = key_>
		<cfelse>
			<cfset data = array_()>
			<cfset data[key_] = arguments.value>
		</cfif>

		<cfif NOT array_key_exists("escape", this.tempData)>
			<cfset this.tempData["escape"] = array_()>
		</cfif>

		<cfset keys = array_keys(data)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset this.tempData["escape"][keys[i]] = arguments.escape>
		</cfloop>

		<cfif array_key_exists("data", this.tempData)>
			<cfset this.tempData["data"] = mergeMap_(this.tempData["data"], data)>
		<cfelse>
			<cfset this.tempData["data"] = copyMap_(data)>
		</cfif>

		<cfreturn this>
	</cffunction>

	<cffunction name="shouldUpdate" access="private" returntype="boolean" output="no">
		<cfargument name="row" type="any" required="yes">

		<cfif NOT parentShouldUpdate_(arguments.row)>
			<cfreturn false>
		</cfif>

		<cfif truthy_(this.useAutoIncrement)>
			<cfreturn true>
		</cfif>

		<!---
		 * When useAutoIncrement feature is disabled, check
		 * in the database if given record already exists
		--->
		<cfset where(this.primaryKey, getIdValue(arguments.row))>

		<cfreturn Val(countAllResults()) EQ 1>
	</cffunction>

	<!---
	 * Inserts data into the database. The data given by set() is used as
	 * the row, or merged with it.
	 *
	 * Named insert_(), as insert() is a built-in function.
	--->
	<cffunction name="insert_" access="public" returntype="any" output="no">
		<cfargument name="row" type="any" required="no">
		<cfargument name="returnID" type="boolean" required="no" default="true">
		<cfset var row_ = nullValue_()>

		<cfif StructKeyExists(arguments, "row")>
			<cfset row_ = arguments.row>
		</cfif>

		<cfif array_key_exists("data", this.tempData)>
			<cfif isNil_(row_)>
				<cfset row_ = this.tempData["data"]>
			<cfelse>
				<cfset row_ = transformDataToArray(row_, "insert")>
				<cfset row_ = mergeMap_(this.tempData["data"], row_)>
			</cfif>
		</cfif>

		<cfif array_key_exists("escape", this.tempData)>
			<cfset this.escape = this.tempData["escape"]>
		<cfelse>
			<cfset this.escape = array_()>
		</cfif>

		<cfset this.tempData = array_()>

		<cfif isNil_(row_)>
			<cfset row_ = nullValue_()>
		</cfif>

		<cfreturn parentInsert_(row_, arguments.returnID)>
	</cffunction>

	<cffunction name="doProtectFieldsForInsert" access="private" returntype="any" output="no">
		<cfargument name="row" type="any" required="yes">
		<cfset var keys = "">
		<cfset var result = array_()>
		<cfset var i = 0>

		<cfif NOT truthy_(this.protectFields)>
			<cfreturn arguments.row>
		</cfif>

		<cfif ArrayLen(this.allowedFields) EQ 0>
			<cfset static_("ColdIgniter\Database\Exceptions\DataException").forInvalidAllowedFields(className_())>
		</cfif>

		<cfset keys = array_keys(arguments.row)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<!--- Do not remove the non-auto-incrementing primary key data. --->
			<cfif (NOT truthy_(this.useAutoIncrement) AND Compare(keys[i], this.primaryKey) EQ 0) OR in_array(keys[i], this.allowedFields)>
				<cfset result[keys[i]] = arguments.row[keys[i]]>
			</cfif>
		</cfloop>

		<cfreturn result>
	</cffunction>

	<cffunction name="doProtectFieldsForReplace" access="private" returntype="any" output="no">
		<cfargument name="row" type="any" required="yes">
		<cfset var primaryKey = array_()>
		<cfset var protectedRow = doProtectFields(arguments.row)>
		<cfset var onlyPrimaryKey = "true">
		<cfset var keys = array_keys(protectedRow)>
		<cfset var rowKeys = array_keys(arguments.row)>
		<cfset var result = array_()>
		<cfset var i = 0>

		<!--- array_intersect_key($row, [$this->primaryKey => true]) --->
		<cfif array_key_exists(this.primaryKey, arguments.row)>
			<cfset primaryKey[this.primaryKey] = arguments.row[this.primaryKey]>
		</cfif>

		<!--- Reject data reduced to an identifier, but preserve explicit identifier-only calls. --->
		<cfset onlyPrimaryKey = StructCount(arguments.row) EQ StructCount(primaryKey)>

		<cfif NOT onlyPrimaryKey>
			<!--- array_diff_key($protectedRow, $primaryKey) === [] --->
			<cfset onlyPrimaryKey = "true">

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfif NOT array_key_exists(keys[i], primaryKey)>
					<cfset onlyPrimaryKey = "false">
				</cfif>
			</cfloop>

			<cfif onlyPrimaryKey>
				<cfset static_("ColdIgniter\Database\Exceptions\DataException").forEmptyDataset("replace")>
			</cfif>
		</cfif>

		<!--- $protectedRow += $primaryKey --->
		<cfset protectedRow = unionMap_(protectedRow, primaryKey)>

		<!--- PostgreSQL's replace() uses the first field to match an existing row. --->
		<cfloop from="1" to="#ArrayLen(rowKeys)#" index="i">
			<cfif array_key_exists(rowKeys[i], protectedRow)>
				<cfset result[rowKeys[i]] = protectedRow[rowKeys[i]]>
			</cfif>
		</cfloop>

		<cfreturn result>
	</cffunction>

	<!---
	 * Updates a record. The data given by set() is used as the row, or
	 * merged with it.
	 *
	 * @param id  An id, a list of ids, a RawSql, or omitted for none
	 * @param row A row, or omitted for none
	--->
	<cffunction name="update" access="public" returntype="boolean" output="no">
		<cfargument name="id" type="any" required="no">
		<cfargument name="row" type="any" required="no">
		<cfset var id_ = nullValue_()>
		<cfset var row_ = nullValue_()>

		<cfif StructKeyExists(arguments, "id")>
			<cfset id_ = arguments.id>
		</cfif>

		<cfif StructKeyExists(arguments, "row")>
			<cfset row_ = arguments.row>
		</cfif>

		<cfif array_key_exists("data", this.tempData)>
			<cfif isNil_(row_)>
				<cfset row_ = this.tempData["data"]>
			<cfelse>
				<cfset row_ = transformDataToArray(row_, "update")>
				<cfset row_ = mergeMap_(this.tempData["data"], row_)>
			</cfif>
		</cfif>

		<cfif array_key_exists("escape", this.tempData)>
			<cfset this.escape = this.tempData["escape"]>
		<cfelse>
			<cfset this.escape = array_()>
		</cfif>

		<cfset this.tempData = array_()>

		<cfif isNil_(row_)>
			<cfset row_ = nullValue_()>
		</cfif>

		<cfreturn parentUpdate_(id_, row_)>
	</cffunction>

	<!---
	 * Provides/instantiates the builder/db connection and model's table/primary key names and return type.
	 *
	 * Difference: __get() is a public method that is called by name:
	 * model.__get("table"). An empty string is the null of a property that
	 * does not exist.
	 *
	 * @return mixed
	--->
	<cffunction name="__get" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfset var builder = "">

		<cfif parentIsset_(arguments.name)>
			<cfreturn parentGet_(arguments.name)>
		</cfif>

		<cfset builder = this.builder()>

		<cfif StructKeyExists(builder, arguments.name) AND NOT IsCustomFunction(builder[arguments.name])>
			<cfreturn builder[arguments.name]>
		</cfif>

		<cfreturn "">
	</cffunction>

	<!---
	 * Checks for the existence of properties across this model, builder, and db connection.
	 *
	 * Difference: __isset() is a public method that is called by name.
	--->
	<cffunction name="__isset" access="public" returntype="boolean" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfset var builder = "">

		<cfif parentIsset_(arguments.name)>
			<cfreturn true>
		</cfif>

		<cfset builder = this.builder()>

		<cfif StructKeyExists(builder, arguments.name) AND NOT IsCustomFunction(builder[arguments.name])>
			<cfreturn NOT isNil_(builder[arguments.name])>
		</cfif>

		<cfreturn false>
	</cffunction>

	<!---
	 * Provides direct access to method in the builder (if available)
	 * and the database connection.
	 *
	 * Difference: __call() is a public method that is called by name:
	 * model.__call("where", params), with the arguments as a list. It is also
	 * the way to reach the methods of the builder and the connection that
	 * have no method of their own in this class.
	 *
	 * @param name   The name of the method
	 * @param params The arguments, as a list
	 *
	 * @return mixed
	--->
	<cffunction name="__call" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="params" type="array" required="no" default="#ArrayNew(1)#">
		<cfset var builder = this.builder()>
		<cfset var result = "">

		<cfif REFind("^[A-Za-z_][A-Za-z0-9_]*$", arguments.name) EQ 0>
			<cfthrow type="ColdIgniter.Exceptions.BadMethodCallException" message="Call to undefined method #className_()#::#arguments.name#">
		</cfif>

		<cfif method_exists(this.db, arguments.name)>
			<cfset result = callWith_(this.db, arguments.name, arguments.params)>
		<cfelseif method_exists(builder, arguments.name)>
			<cfset checkBuilderMethod(arguments.name)>

			<cfset result = callWith_(builder, arguments.name, arguments.params)>
		<cfelse>
			<cfthrow type="ColdIgniter.Exceptions.BadMethodCallException" message="Call to undefined method #className_()#::#arguments.name#">
		</cfif>

		<cfif instanceof_(result, "BaseBuilder")>
			<cfreturn this>
		</cfif>

		<cfreturn result>
	</cffunction>

	<!---
	 * Checks the Builder method name that should not be used in the Model.
	--->
	<cffunction name="checkBuilderMethod" access="private" returntype="void" output="no">
		<cfargument name="name" type="string" required="yes">

		<cfif in_array(arguments.name, this.builderMethodsNotAvailable)>
			<cfset static_("ColdIgniter\Exceptions\ModelException").forMethodNotAvailable(className_(), "#arguments.name#()")>
		</cfif>
	</cffunction>

	<!---
	 * The helpers below have no original: they stand in for the magic
	 * methods and the features of the language that CFML 6.1 does not have.
	--->

	<!--- calls a method of an object with a list of arguments --->
	<cffunction name="callWith_" access="private" returntype="any" output="no">
		<cfargument name="target" type="any" required="yes">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="params" type="array" required="yes">
		<cfset var receiver = arguments.target>
		<cfset var callArgs = arguments.params>
		<cfset var list = "">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(callArgs)#" index="i">
			<cfset list = ListAppend(list, "callArgs[#i#]")>
		</cfloop>

		<cfreturn Evaluate("receiver.#arguments.name#(#list#)")>
	</cffunction>

	<!--- hands a call of a forwarding method over to the builder --->
	<cffunction name="callBuilder_" access="private" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="args" type="any" required="yes">
		<cfset var result = "">

		<cfset checkBuilderMethod(arguments.name)>

		<cfset result = callWith_(this.builder(), arguments.name, positional_(arguments.args))>

		<cfif instanceof_(result, "BaseBuilder")>
			<cfreturn this>
		</cfif>

		<cfreturn result>
	</cffunction>

	<!--- hands a call of a forwarding method over to the connection --->
	<cffunction name="callDb_" access="private" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="args" type="any" required="yes">
		<cfset var result = callWith_(this.db, arguments.name, positional_(arguments.args))>

		<cfif instanceof_(result, "BaseBuilder")>
			<cfreturn this>
		</cfif>

		<cfreturn result>
	</cffunction>

	<!--- the arguments of a forwarding method as a list, which must have been passed by position --->
	<cffunction name="positional_" access="private" returntype="array" output="no">
		<cfargument name="args" type="any" required="yes">
		<cfset var list = ArrayNew(1)>
		<cfset var i = 0>

		<cfloop from="1" to="#StructCount(arguments.args)#" index="i">
			<cfif NOT StructKeyExists(arguments.args, "#i#")>
				<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="The arguments of #className_()# methods that hand over to the builder or the connection must be passed by position.">
			</cfif>

			<cfset ArrayAppend(list, arguments.args["#i#"])>
		</cfloop>

		<cfreturn list>
	</cffunction>

	<!--- a null: an empty string, or the marker --->
	<cffunction name="isNil_" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfreturn isNullMarker_(arguments.value) OR (IsSimpleValue(arguments.value) AND Len(arguments.value) EQ 0)>
	</cffunction>

	<!--- array_merge($a, $b) for two maps: the keys of the second win --->
	<cffunction name="mergeMap_" access="private" returntype="any" output="no">
		<cfargument name="a" type="any" required="yes">
		<cfargument name="b" type="any" required="yes">
		<cfset var result = copyMap_(arguments.a)>
		<cfset var keys = array_keys(arguments.b)>
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset result[keys[i]] = arguments.b[keys[i]]>
		</cfloop>

		<cfreturn result>
	</cffunction>

	<!---
	 * Methods of the builder, handed over by the model (see the header).
	--->

	<cffunction name="testMode" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("testMode", arguments)>
	</cffunction>

	<cffunction name="getTable" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("getTable", arguments)>
	</cffunction>

	<cffunction name="getBinds" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("getBinds", arguments)>
	</cffunction>

	<cffunction name="ignore" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("ignore", arguments)>
	</cffunction>

	<cffunction name="select" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("select", arguments)>
	</cffunction>

	<cffunction name="selectMax" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("selectMax", arguments)>
	</cffunction>

	<cffunction name="selectMin" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("selectMin", arguments)>
	</cffunction>

	<cffunction name="selectAvg" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("selectAvg", arguments)>
	</cffunction>

	<cffunction name="selectSum" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("selectSum", arguments)>
	</cffunction>

	<cffunction name="selectCount" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("selectCount", arguments)>
	</cffunction>

	<cffunction name="selectSubquery" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("selectSubquery", arguments)>
	</cffunction>

	<cffunction name="distinct" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("distinct", arguments)>
	</cffunction>

	<cffunction name="from" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("from", arguments)>
	</cffunction>

	<cffunction name="fromSubquery" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("fromSubquery", arguments)>
	</cffunction>

	<cffunction name="join" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("join", arguments)>
	</cffunction>

	<cffunction name="where" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("where", arguments)>
	</cffunction>

	<cffunction name="orWhere" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("orWhere", arguments)>
	</cffunction>

	<cffunction name="whereIn" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("whereIn", arguments)>
	</cffunction>

	<cffunction name="orWhereIn" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("orWhereIn", arguments)>
	</cffunction>

	<cffunction name="whereNotIn" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("whereNotIn", arguments)>
	</cffunction>

	<cffunction name="orWhereNotIn" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("orWhereNotIn", arguments)>
	</cffunction>

	<cffunction name="havingIn" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("havingIn", arguments)>
	</cffunction>

	<cffunction name="orHavingIn" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("orHavingIn", arguments)>
	</cffunction>

	<cffunction name="havingNotIn" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("havingNotIn", arguments)>
	</cffunction>

	<cffunction name="orHavingNotIn" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("orHavingNotIn", arguments)>
	</cffunction>

	<cffunction name="like" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("like", arguments)>
	</cffunction>

	<cffunction name="notLike" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("notLike", arguments)>
	</cffunction>

	<cffunction name="orLike" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("orLike", arguments)>
	</cffunction>

	<cffunction name="orNotLike" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("orNotLike", arguments)>
	</cffunction>

	<cffunction name="havingLike" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("havingLike", arguments)>
	</cffunction>

	<cffunction name="notHavingLike" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("notHavingLike", arguments)>
	</cffunction>

	<cffunction name="orHavingLike" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("orHavingLike", arguments)>
	</cffunction>

	<cffunction name="orNotHavingLike" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("orNotHavingLike", arguments)>
	</cffunction>

	<cffunction name="union" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("union", arguments)>
	</cffunction>

	<cffunction name="unionAll" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("unionAll", arguments)>
	</cffunction>

	<cffunction name="groupStart" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("groupStart", arguments)>
	</cffunction>

	<cffunction name="orGroupStart" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("orGroupStart", arguments)>
	</cffunction>

	<cffunction name="notGroupStart" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("notGroupStart", arguments)>
	</cffunction>

	<cffunction name="orNotGroupStart" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("orNotGroupStart", arguments)>
	</cffunction>

	<cffunction name="groupEnd" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("groupEnd", arguments)>
	</cffunction>

	<cffunction name="havingGroupStart" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("havingGroupStart", arguments)>
	</cffunction>

	<cffunction name="orHavingGroupStart" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("orHavingGroupStart", arguments)>
	</cffunction>

	<cffunction name="notHavingGroupStart" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("notHavingGroupStart", arguments)>
	</cffunction>

	<cffunction name="orNotHavingGroupStart" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("orNotHavingGroupStart", arguments)>
	</cffunction>

	<cffunction name="havingGroupEnd" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("havingGroupEnd", arguments)>
	</cffunction>

	<cffunction name="groupBy" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("groupBy", arguments)>
	</cffunction>

	<cffunction name="having" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("having", arguments)>
	</cffunction>

	<cffunction name="orHaving" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("orHaving", arguments)>
	</cffunction>

	<cffunction name="orderBy" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("orderBy", arguments)>
	</cffunction>

	<cffunction name="limit" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("limit", arguments)>
	</cffunction>

	<cffunction name="offset" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("offset", arguments)>
	</cffunction>

	<cffunction name="getSetData" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("getSetData", arguments)>
	</cffunction>

	<cffunction name="getCompiledSelect" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("getCompiledSelect", arguments)>
	</cffunction>

	<cffunction name="get" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("get", arguments)>
	</cffunction>

	<cffunction name="countAll" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("countAll", arguments)>
	</cffunction>

	<cffunction name="getCompiledQBWhere" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("getCompiledQBWhere", arguments)>
	</cffunction>

	<cffunction name="getWhere" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("getWhere", arguments)>
	</cffunction>

	<cffunction name="setData" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("setData", arguments)>
	</cffunction>

	<cffunction name="getCompiledUpsert" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("getCompiledUpsert", arguments)>
	</cffunction>

	<cffunction name="upsert" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("upsert", arguments)>
	</cffunction>

	<cffunction name="upsertBatch" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("upsertBatch", arguments)>
	</cffunction>

	<cffunction name="updateFields" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("updateFields", arguments)>
	</cffunction>

	<cffunction name="onConstraint" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("onConstraint", arguments)>
	</cffunction>

	<cffunction name="setQueryAsData" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("setQueryAsData", arguments)>
	</cffunction>

	<cffunction name="setInsertBatch" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("setInsertBatch", arguments)>
	</cffunction>

	<cffunction name="getCompiledInsert" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("getCompiledInsert", arguments)>
	</cffunction>

	<cffunction name="getCompiledUpdate" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("getCompiledUpdate", arguments)>
	</cffunction>

	<cffunction name="setUpdateBatch" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("setUpdateBatch", arguments)>
	</cffunction>

	<cffunction name="emptyTable" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("emptyTable", arguments)>
	</cffunction>

	<cffunction name="truncate" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("truncate", arguments)>
	</cffunction>

	<cffunction name="getCompiledDelete" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("getCompiledDelete", arguments)>
	</cffunction>

	<cffunction name="deleteBatch" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("deleteBatch", arguments)>
	</cffunction>

	<cffunction name="increment" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("increment", arguments)>
	</cffunction>

	<cffunction name="decrement" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("decrement", arguments)>
	</cffunction>

	<cffunction name="resetQuery" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("resetQuery", arguments)>
	</cffunction>

	<cffunction name="when" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("when", arguments)>
	</cffunction>

	<cffunction name="whenNot" access="public" returntype="any" output="no">

		<cfreturn callBuilder_("whenNot", arguments)>
	</cffunction>

	<!---
	 * Methods of the connection, handed over by the model (see the header).
	--->

	<cffunction name="query" access="public" returntype="any" output="no">

		<cfreturn callDb_("query", arguments)>
	</cffunction>

	<cffunction name="simpleQuery" access="public" returntype="any" output="no">

		<cfreturn callDb_("simpleQuery", arguments)>
	</cffunction>

	<cffunction name="affectedRows" access="public" returntype="any" output="no">

		<cfreturn callDb_("affectedRows", arguments)>
	</cffunction>

	<cffunction name="transOff" access="public" returntype="any" output="no">

		<cfreturn callDb_("transOff", arguments)>
	</cffunction>

	<cffunction name="transStart" access="public" returntype="any" output="no">

		<cfreturn callDb_("transStart", arguments)>
	</cffunction>

	<cffunction name="transComplete" access="public" returntype="any" output="no">

		<cfreturn callDb_("transComplete", arguments)>
	</cffunction>

	<cffunction name="transStatus" access="public" returntype="any" output="no">

		<cfreturn callDb_("transStatus", arguments)>
	</cffunction>

	<cffunction name="transBegin" access="public" returntype="any" output="no">

		<cfreturn callDb_("transBegin", arguments)>
	</cffunction>

	<cffunction name="transCommit" access="public" returntype="any" output="no">

		<cfreturn callDb_("transCommit", arguments)>
	</cffunction>

	<cffunction name="transRollback" access="public" returntype="any" output="no">

		<cfreturn callDb_("transRollback", arguments)>
	</cffunction>

	<cffunction name="escapeString" access="public" returntype="any" output="no">

		<cfreturn callDb_("escapeString", arguments)>
	</cffunction>

	<cffunction name="listTables" access="public" returntype="any" output="no">

		<cfreturn callDb_("listTables", arguments)>
	</cffunction>

	<cffunction name="tableExists" access="public" returntype="any" output="no">

		<cfreturn callDb_("tableExists", arguments)>
	</cffunction>

	<cffunction name="getFieldNames" access="public" returntype="any" output="no">

		<cfreturn callDb_("getFieldNames", arguments)>
	</cffunction>

	<cffunction name="getFieldData" access="public" returntype="any" output="no">

		<cfreturn callDb_("getFieldData", arguments)>
	</cffunction>

	<cffunction name="fieldExists" access="public" returntype="any" output="no">

		<cfreturn callDb_("fieldExists", arguments)>
	</cffunction>

	<cffunction name="getLastQuery" access="public" returntype="any" output="no">

		<cfreturn callDb_("getLastQuery", arguments)>
	</cffunction>

	<cffunction name="showLastQuery" access="public" returntype="any" output="no">

		<cfreturn callDb_("showLastQuery", arguments)>
	</cffunction>

	<cffunction name="error" access="public" returntype="any" output="no">

		<cfreturn callDb_("error", arguments)>
	</cffunction>

	<cffunction name="prefixTable" access="public" returntype="any" output="no">

		<cfreturn callDb_("prefixTable", arguments)>
	</cffunction>

	<cffunction name="getPrefix" access="public" returntype="any" output="no">

		<cfreturn callDb_("getPrefix", arguments)>
	</cffunction>

</cfcomponent>
