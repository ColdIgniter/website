<!---
 * Class BaseModel
 *
 * The first thing the Model and the Entity classes share.
 *
 * Difference: the casts are made by DataConverter (see createDataConverter()),
 * and a model with the return type of an Entity class (or asObject() with a
 * class name) returns the objects of that class.
 *
 * Difference: there is no abstract method, and no magic method (__get,
 * __isset and __call are written as public methods, see Model). The abstract
 * methods are methods that throw; Model writes them out.
 *
 * Difference: the methods that have the name of a built-in function have a
 * trailing underscore: find_(), insert_() and replace_(). The properties that
 * have the name of a method have one too: skipValidation_, allowCallbacks_
 * and allowEmptyInserts_ (the methods skipValidation(), allowCallbacks() and
 * allowEmptyInserts() keep their names). The protected method
 * cleanValidationRules() is cleanValidationRules_(), as the property of that
 * name is set by the models.
 *
 * Difference: a row is a map (see array_()), also for the return type
 * 'object' (the rows of the result are maps in both cases, as there is no
 * stdClass). A class name gives the objects of that class. An object (a component) that is
 * given as data is read with its toRawArray() method, or the call throws
 * "Not ported yet" (there is no reflection).
 *
 * Difference: a null is an empty string, and a value that is a null inside a
 * map (or the id or the row of an event) is new_("ColdIgniter\Database\NullValue").
 * An argument that is omitted is null: find() is find_() with no id, and
 * update(row=row) has no id. A boolean is the text "true" or "false".
 *
 * Difference: the parent's version of a method that Model overrides is
 * reached by name, as the methods are copied into the models of the
 * application and super does not follow them: shouldUpdate(), insert_(),
 * update(), __get() and __isset() hand over to parentShouldUpdate_(),
 * parentInsert_(), parentUpdate_(), parentGet_() and parentIsset_(), which
 * hold their code, and the constructor to construct_().
 *
 * Difference: there is no Closure, so chunk() takes a callable written as a
 * list of two items, an object and the name of one of its public methods,
 * [object, "method"] (as the Query Builder does). The method has to return a
 * value.
 *
 * Difference: setDate() uses the server clock directly (no Time object, so a
 * row costs no CreateObject) and gives the same strings for the date formats
 * 'datetime', 'date' and 'int'. Only while a test instance of Time is set
 * (Time::setTestNow) it asks Time for the current time. timeToDate() takes
 * a Time, or a CFML date. The server clock is read in the zone of the CFML
 * server, not in Config\App appTimezone (which a Time uses).
 *
 * Difference: Config\Feature is not ported yet, so limitZeroAsAll is always
 * true.
 *
 * @see \CodeIgniter\BaseModel
--->
<cfcomponent output="no" hint="The first thing the Model and the Entity classes share">

	<!---
	 * Pager instance.
	 *
	 * Populated after calling `$this->paginate()`.
	 *
	 * @var Pager
	--->
	<cfset this.pager = "">

	<!---
	 * Database Connection.
	 *
	 * @var BaseConnection
	--->
	<cfset this.db = "">

	<!---
	 * Last insert ID.
	 *
	 * @var int|string
	--->
	<cfset this.insertID = 0>

	<!---
	 * The Database connection group that
	 * should be instantiated.
	 *
	 * @var non-empty-string|null
	--->
	<cfset this.DBGroup = "">

	<!---
	 * The format that the results should be returned as.
	 *
	 * Will be overridden if the `$this->asArray()`, `$this->asObject()` methods are used.
	 *
	 * @var 'array'|'object'|class-string
	--->
	<cfset this.returnType = "array">

	<!---
	 * The temporary format of the result.
	 *
	 * Used by `$this->asArray()` and `$this->asObject()` to provide
	 * temporary overrides of model default.
	 *
	 * @var 'array'|'object'|class-string
	--->
	<cfset this.tempReturnType = "">

	<!---
	 * Array of column names and the type of value to cast.
	 *
	 * @var array<string, string> Array order `['column' => 'type']`.
	--->
	<cfset this.casts = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Custom convert handlers.
	 *
	 * @var array<string, class-string<CastInterface|EntityCastInterface>> Array order `['type' => 'classname']`.
	--->
	<cfset this.castHandlers = CreateObject("java", "java.util.LinkedHashMap").init()>

	<cfset this.converter = "">

	<!---
	 * Determines whether the model should protect field names during
	 * mass assignment operations such as $this->insert(), $this->update(), $this->replace().
	 *
	 * When set to `true`, only the fields explicitly defined in the `$allowedFields`
	 * property will be allowed for mass assignment. This helps prevent
	 * unintended modification of database fields and improves security
	 * by avoiding mass assignment vulnerabilities.
	 *
	 * @var bool
	--->
	<cfset this.protectFields = "true">

	<!---
	 * An array of field names that are allowed
	 * to be set by the user in inserts/updates/replaces.
	 *
	 * @var list<string>
	--->
	<cfset this.allowedFields = ArrayNew(1)>

	<!---
	 * If true, will set created_at, and updated_at
	 * values during insert and update routines.
	 *
	 * @var bool
	--->
	<cfset this.useTimestamps = "false">

	<!---
	 * The type of column that created_at and updated_at
	 * are expected to.
	 *
	 * @var 'date'|'datetime'|'int'
	--->
	<cfset this.dateFormat = "datetime">

	<!---
	 * The column used for insert timestamps.
	 *
	 * @var string
	--->
	<cfset this.createdField = "created_at">

	<!---
	 * The column used for update timestamps.
	 *
	 * @var string
	--->
	<cfset this.updatedField = "updated_at">

	<!---
	 * If this model should use "softDeletes" and
	 * simply set a date when rows are deleted, or
	 * do hard deletes.
	 *
	 * @var bool
	--->
	<cfset this.useSoftDeletes = "false">

	<!---
	 * Used by $this->withDeleted() to override the
	 * model's "softDelete" setting.
	 *
	 * @var bool
	--->
	<cfset this.tempUseSoftDeletes = "false">

	<!---
	 * The column used to save soft delete state.
	 *
	 * @var string
	--->
	<cfset this.deletedField = "deleted_at">

	<!---
	 * Whether to allow inserting empty data.
	 *
	 * Named with an underscore, as allowEmptyInserts() is a method.
	--->
	<cfset this.allowEmptyInserts_ = "false">

	<!---
	 * Whether to update Entity's only changed data.
	--->
	<cfset this.updateOnlyChanged = "true">

	<!---
	 * Rules used to validate data in insert(), update(), save(),
	 * insertBatch(), and updateBatch() methods.
	 *
	 * The array must match the format of data passed to the `Validation`
	 * library.
	 *
	 * @see https://codeigniter4.github.io/userguide/models/model.html#setting-validation-rules
	 *
	 * @var array<string, array<string, array<string, string>|string>|string>|string
	--->
	<cfset this.validationRules = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Contains any custom error messages to be
	 * used during data validation.
	 *
	 * @var array<string, array<string, string>> The column is used as the keys.
	--->
	<cfset this.validationMessages = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Skip the model's validation.
	 *
	 * Used in conjunction with `$this->skipValidation()`
	 * to skip data validation for any future calls.
	 *
	 * Named with an underscore, as skipValidation() is a method.
	 *
	 * @var bool
	--->
	<cfset this.skipValidation_ = "false">

	<!---
	 * Whether rules should be removed that do not exist
	 * in the passed data. Used in updates.
	 *
	 * @var bool
	--->
	<cfset this.cleanValidationRules = "true">

	<!---
	 * Our validator instance.
	 *
	 * @var ValidationInterface|null
	--->
	<cfset this.validation = "">

	<!---
	 * Callbacks.
	 *
	 * Each array should contain the method names (within the model)
	 * that should be called when those events are triggered.
	 *
	 * "Update" and "delete" methods are passed the same items that
	 * are given to their respective method.
	 *
	 * "Find" methods receive the ID searched for (if present), and
	 * 'afterFind' additionally receives the results that were found.
	--->

	<!---
	 * Whether to trigger the defined callbacks.
	 *
	 * Named with an underscore, as allowCallbacks() is a method.
	 *
	 * @var bool
	--->
	<cfset this.allowCallbacks_ = "true">

	<!---
	 * Used by $this->allowCallbacks() to override the
	 * model's $allowCallbacks setting.
	 *
	 * @var bool
	--->
	<cfset this.tempAllowCallbacks = "true">

	<!---
	 * Callbacks for "beforeInsert" event.
	 *
	 * @var list<string>
	--->
	<cfset this.beforeInsert = ArrayNew(1)>

	<!---
	 * Callbacks for "afterInsert" event.
	 *
	 * @var list<string>
	--->
	<cfset this.afterInsert = ArrayNew(1)>

	<!---
	 * Callbacks for "beforeUpdate" event.
	 *
	 * @var list<string>
	--->
	<cfset this.beforeUpdate = ArrayNew(1)>

	<!---
	 * Callbacks for "afterUpdate" event.
	 *
	 * @var list<string>
	--->
	<cfset this.afterUpdate = ArrayNew(1)>

	<!---
	 * Callbacks for "beforeInsertBatch" event.
	 *
	 * @var list<string>
	--->
	<cfset this.beforeInsertBatch = ArrayNew(1)>

	<!---
	 * Callbacks for "afterInsertBatch" event.
	 *
	 * @var list<string>
	--->
	<cfset this.afterInsertBatch = ArrayNew(1)>

	<!---
	 * Callbacks for "beforeUpdateBatch" event.
	 *
	 * @var list<string>
	--->
	<cfset this.beforeUpdateBatch = ArrayNew(1)>

	<!---
	 * Callbacks for "afterUpdateBatch" event.
	 *
	 * @var list<string>
	--->
	<cfset this.afterUpdateBatch = ArrayNew(1)>

	<!---
	 * Callbacks for "beforeFind" event.
	 *
	 * @var list<string>
	--->
	<cfset this.beforeFind = ArrayNew(1)>

	<!---
	 * Callbacks for "afterFind" event.
	 *
	 * @var list<string>
	--->
	<cfset this.afterFind = ArrayNew(1)>

	<!---
	 * Callbacks for "beforeDelete" event.
	 *
	 * @var list<string>
	--->
	<cfset this.beforeDelete = ArrayNew(1)>

	<!---
	 * Callbacks for "afterDelete" event.
	 *
	 * @var list<string>
	--->
	<cfset this.afterDelete = ArrayNew(1)>

	<!---
	 * @param validation The validation object, or omitted for none
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="validation" type="any" required="no">

		<cfif StructKeyExists(arguments, "validation")>
			<cfreturn construct_(arguments.validation)>
		</cfif>

		<cfreturn construct_("")>
	</cffunction>

	<!---
	 * Not in the original. The code of __construct(), which Model reaches by
	 * name (see the header).
	--->
	<cffunction name="construct_" access="private" returntype="any" output="no">
		<cfargument name="validation" type="any" required="yes">

		<cfset this.tempReturnType = this.returnType>
		<cfset this.tempUseSoftDeletes = this.useSoftDeletes>
		<cfset this.tempAllowCallbacks = this.allowCallbacks_>

		<cfset this.validation = arguments.validation>

		<cfset initialize_()>
		<cfset createDataConverter()>

		<cfreturn this>
	</cffunction>

	<!---
	 * Creates DataConverter instance.
	 *
	 * Difference: the converter is a property that is empty when the model has
	 * no casts, so the rows of such a model need no object.
	--->
	<cffunction name="createDataConverter" access="private" returntype="void" output="no">

		<cfif useCasts()>
			<cfset this.converter = new_("ColdIgniter\DataConverter\DataConverter", this.casts, this.castHandlers, this.db)>
		</cfif>
	</cffunction>

	<!---
	 * Are casts used?
	--->
	<cffunction name="useCasts" access="private" returntype="boolean" output="no">

		<cfreturn NOT isEmpty_(this.casts)>
	</cffunction>

	<!---
	 * Initializes the instance with any additional steps.
	 * Optionally implemented by child classes.
	 *
	 * Difference: named initialize_ because initialize is a built-in function.
	--->
	<cffunction name="initialize_" access="private" returntype="void" output="no">
	</cffunction>

	<!---
	 * Fetches the row(s) of database with a primary key
	 * matching $id.
	 * This method works only with DB calls.
	 *
	 * @param singleton Single or multiple results.
	 * @param id        One primary key or a list of primary keys, or new_("ColdIgniter\Database\NullValue")
	 *
	 * @return The resulting row of data or an empty string (null), or a list of rows
	--->
	<cffunction name="doFind" access="private" returntype="any" output="no">
		<cfargument name="singleton" type="boolean" required="yes">
		<cfargument name="id" type="any" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define doFind().">
	</cffunction>

	<!---
	 * Fetches the column of database.
	 * This method works only with DB calls.
	 *
	 * @return list<row_array>|null The resulting row of data or `null` if no data found.
	 *
	 * @throws DataException
	--->
	<cffunction name="doFindColumn" access="private" returntype="any" output="no">
		<cfargument name="columnName" type="string" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define doFindColumn().">
	</cffunction>

	<!---
	 * Fetches all results, while optionally limiting them.
	 * This method works only with DB calls.
	 *
	 * @param limit An empty string is null
	 *
	 * @return list<object|row_array>
	--->
	<cffunction name="doFindAll" access="private" returntype="any" output="no">
		<cfargument name="limit_" type="any" required="yes">
		<cfargument name="offset_" type="any" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define doFindAll().">
	</cffunction>

	<!---
	 * Returns the first row of the result set.
	 * This method works only with DB calls.
	 *
	 * @return object|row_array|null
	--->
	<cffunction name="doFirst" access="private" returntype="any" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define doFirst().">
	</cffunction>

	<!---
	 * Inserts data into the current database.
	 * This method works only with DB calls.
	 *
	 * @param row_array $row
	 *
	 * @return bool
	--->
	<cffunction name="doInsert" access="private" returntype="any" output="no">
		<cfargument name="row" type="any" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define doInsert().">
	</cffunction>

	<!---
	 * Compiles batch insert and runs the queries, validating each row prior.
	 * This method works only with DB calls.
	 *
	 * @param set_      A list of rows, or an empty string (null)
	 * @param escape    Whether to escape values, an empty string is null
	 * @param batchSize The size of the batch to run.
	 * @param testing   `true` means only number of records is returned, `false` will execute the query.
	 *
	 * @return false|int|list<string> Number of rows affected or `false` on failure, SQL array when test mode
	--->
	<cffunction name="doInsertBatch" access="private" returntype="any" output="no">
		<cfargument name="set_" type="any" required="yes">
		<cfargument name="escape" type="any" required="yes">
		<cfargument name="batchSize" type="numeric" required="yes">
		<cfargument name="testing" type="boolean" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define doInsertBatch().">
	</cffunction>

	<!---
	 * Updates a single record in the database.
	 * This method works only with DB calls.
	 *
	 * @param id  A list of ids, or an empty string (null)
	 * @param row A row
	--->
	<cffunction name="doUpdate" access="private" returntype="boolean" output="no">
		<cfargument name="id" type="any" required="yes">
		<cfargument name="row" type="any" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define doUpdate().">
	</cffunction>

	<!---
	 * Compiles an update and runs the query.
	 * This method works only with DB calls.
	 *
	 * @param set_      A list of rows, or an empty string (null)
	 * @param index     The where key, an empty string is null
	 * @param batchSize The size of the batch to run.
	 * @param returnSQL `true` means SQL is returned, `false` will execute the query.
	 *
	 * @return false|int|list<string> Number of rows affected or `false` on failure, SQL array when test mode
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="doUpdateBatch" access="private" returntype="any" output="no">
		<cfargument name="set_" type="any" required="yes">
		<cfargument name="index" type="any" required="yes">
		<cfargument name="batchSize" type="numeric" required="yes">
		<cfargument name="returnSQL" type="boolean" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define doUpdateBatch().">
	</cffunction>

	<!---
	 * Deletes a single record from the database where $id matches
	 * the table's primary key.
	 * This method works only with DB calls.
	 *
	 * @param id    A list of ids, or an empty string (null)
	 * @param purge Allows overriding the soft deletes setting.
	 *
	 * @return bool|string Returns a SQL string if in test mode.
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="doDelete" access="private" returntype="any" output="no">
		<cfargument name="id" type="any" required="yes">
		<cfargument name="purge" type="boolean" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define doDelete().">
	</cffunction>

	<!---
	 * Permanently deletes all rows that have been marked as deleted
	 * through soft deletes (value of column $deletedField is not null).
	 * This method works only with DB calls.
	 *
	 * @return bool|string Returns a SQL string if in test mode.
	--->
	<cffunction name="doPurgeDeleted" access="private" returntype="any" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define doPurgeDeleted().">
	</cffunction>

	<!---
	 * Works with the $this->find* methods to return only the rows that
	 * have been deleted (value of column $deletedField is not null).
	 * This method works only with DB calls.
	--->
	<cffunction name="doOnlyDeleted" access="private" returntype="void" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define doOnlyDeleted().">
	</cffunction>

	<!---
	 * Compiles a replace and runs the query.
	 * This method works only with DB calls.
	 *
	 * @param row       A row, or an empty string (null)
	 * @param returnSQL `true` means SQL is returned, `false` will execute the query.
	 *
	 * @return BaseResult|false|Query|string
	--->
	<cffunction name="doReplace" access="private" returntype="any" output="no">
		<cfargument name="row" type="any" required="yes">
		<cfargument name="returnSQL" type="boolean" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define doReplace().">
	</cffunction>

	<!---
	 * Grabs the last error(s) that occurred from the Database connection.
	 * This method works only with DB calls.
	 *
	 * @return array<string, string>
	--->
	<cffunction name="doErrors" access="private" returntype="any" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define doErrors().">
	</cffunction>

	<!---
	 * Public getter to return the ID value for the data array or object.
	 * For example with SQL this will return `$data->{$this->primaryKey}`.
	 *
	 * @return int|string|null
	--->
	<cffunction name="getIdValue" access="public" returntype="any" output="no">
		<cfargument name="row" type="any" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getIdValue().">
	</cffunction>

	<!---
	 * Override countAllResults to account for soft deleted accounts.
	 * This method works only with DB calls.
	 *
	 * @param reset When `false`, the `$tempUseSoftDeletes` will be
	 *              dependent on `$useSoftDeletes` value because we don't
	 *              want to add the same "where" condition for the second time.
	 * @param test  `true` returns the number of all records, `false` will execute the query.
	 *
	 * @return int|string Returns a SQL string if in test mode.
	--->
	<cffunction name="countAllResults" access="public" returntype="any" output="no">
		<cfargument name="reset" type="boolean" required="no" default="true">
		<cfargument name="test" type="boolean" required="no" default="false">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define countAllResults().">
	</cffunction>

	<!---
	 * Loops over records in batches, allowing you to operate on them.
	 * This method works only with DB calls.
	 *
	 * @param size     The size of a batch
	 * @param userFunc A list of an object and the name of one of its public methods
	 *
	 * @throws DataException
	 * @throws InvalidArgumentException if $size is not a positive integer
	--->
	<cffunction name="chunk" access="public" returntype="void" output="no">
		<cfargument name="size" type="numeric" required="yes">
		<cfargument name="userFunc" type="any" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define chunk().">
	</cffunction>

	<!---
	 * Fetches the row of database.
	 *
	 * Named find_(), as find() is a built-in function.
	 *
	 * @param id One primary key or a list of primary keys, or omitted for none.
	 *
	 * @return The row, or an empty string (null), or a list of rows
	--->
	<cffunction name="find_" access="public" returntype="any" output="no">
		<cfargument name="id" type="any" required="no">
		<cfset var idValue = nullValue_()>
		<cfset var singleton = "false">
		<cfset var eventData = "">

		<cfif StructKeyExists(arguments, "id") AND NOT isNullMarker_(arguments.id)>
			<cfset idValue = arguments.id>
		</cfif>

		<cfset singleton = IsSimpleValue(idValue)>

		<cfif truthy_(this.tempAllowCallbacks)>
			<!--- Call the before event and check for a return --->
			<cfset eventData = trigger("beforeFind", array_("id", idValue, "method", "find", "singleton", singleton))>

			<cfif returnsData_(eventData)>
				<cfreturn eventData["data"]>
			</cfif>
		</cfif>

		<cfset eventData = array_("id", idValue, "data", doFind(singleton, idValue), "method", "find", "singleton", singleton)>

		<cfif truthy_(this.tempAllowCallbacks)>
			<cfset eventData = trigger("afterFind", eventData)>
		</cfif>

		<cfset this.tempReturnType = this.returnType>
		<cfset this.tempUseSoftDeletes = this.useSoftDeletes>
		<cfset this.tempAllowCallbacks = this.allowCallbacks_>

		<cfreturn eventData["data"]>
	</cffunction>

	<!---
	 * Fetches the column of database.
	 *
	 * @return list<bool|float|int|list<mixed>|object|string|null>|null The resulting row of data, or `null` if no data found.
	 *
	 * @throws DataException
	--->
	<cffunction name="findColumn" access="public" returntype="any" output="no">
		<cfargument name="columnName" type="string" required="yes">
		<cfset var resultSet = "">
		<cfset var column = ArrayNew(1)>
		<cfset var i = 0>

		<cfif Find(",", arguments.columnName) GT 0>
			<cfset static_("ColdIgniter\Database\Exceptions\DataException").forFindColumnHaveMultipleColumns()>
		</cfif>

		<cfset resultSet = doFindColumn(arguments.columnName)>

		<cfif NOT IsArray(resultSet)>
			<cfreturn "">
		</cfif>

		<!--- array_column() --->
		<cfloop from="1" to="#ArrayLen(resultSet)#" index="i">
			<cfif isMap_(resultSet[i]) AND StructKeyExists(resultSet[i], arguments.columnName)>
				<cfset ArrayAppend(column, resultSet[i][arguments.columnName])>
			</cfif>
		</cfloop>

		<cfreturn column>
	</cffunction>

	<!---
	 * Fetches all results, while optionally limiting them.
	 *
	 * Difference: the arguments are limit_ and offset_ (and set_ in the
	 * batch methods), as limit(), offset() and set() are methods of a
	 * model. An argument passed by name must use these names: another
	 * name is ignored without an error.
	 *
	 * @param limit_  An empty string, or omitted, is null
	 * @param offset_ The offset
	 *
	 * @return list<object|row_array>
	--->
	<cffunction name="findAll" access="public" returntype="any" output="no">
		<cfargument name="limit_" type="any" required="no" default="">
		<cfargument name="offset_" type="any" required="no" default="0">
		<cfset var limit = arguments.limit_>
		<cfset var eventData = "">

		<!--- Config\Feature.limitZeroAsAll is not ported yet, it is always true --->
		<cfif is_null(limit)>
			<cfset limit = 0>
		</cfif>

		<cfif truthy_(this.tempAllowCallbacks)>
			<!--- Call the before event and check for a return --->
			<cfset eventData = trigger("beforeFind", array_("method", "findAll", "limit", limit, "offset", arguments.offset_, "singleton", "false"))>

			<cfif returnsData_(eventData)>
				<cfreturn eventData["data"]>
			</cfif>
		</cfif>

		<cfset eventData = array_("data", doFindAll(limit, arguments.offset_), "limit", limit, "offset", arguments.offset_, "method", "findAll", "singleton", "false")>

		<cfif truthy_(this.tempAllowCallbacks)>
			<cfset eventData = trigger("afterFind", eventData)>
		</cfif>

		<cfset this.tempReturnType = this.returnType>
		<cfset this.tempUseSoftDeletes = this.useSoftDeletes>
		<cfset this.tempAllowCallbacks = this.allowCallbacks_>

		<cfreturn eventData["data"]>
	</cffunction>

	<!---
	 * Returns the first row of the result set.
	 *
	 * @return object|row_array|null
	--->
	<cffunction name="first" access="public" returntype="any" output="no">
		<cfset var eventData = "">

		<cfif truthy_(this.tempAllowCallbacks)>
			<!--- Call the before event and check for a return --->
			<cfset eventData = trigger("beforeFind", array_("method", "first", "singleton", "true"))>

			<cfif returnsData_(eventData)>
				<cfreturn eventData["data"]>
			</cfif>
		</cfif>

		<cfset eventData = array_("data", doFirst(), "method", "first", "singleton", "true")>

		<cfif truthy_(this.tempAllowCallbacks)>
			<cfset eventData = trigger("afterFind", eventData)>
		</cfif>

		<cfset this.tempReturnType = this.returnType>
		<cfset this.tempUseSoftDeletes = this.useSoftDeletes>
		<cfset this.tempAllowCallbacks = this.allowCallbacks_>

		<cfreturn eventData["data"]>
	</cffunction>

	<!---
	 * A convenience method that will attempt to determine whether the
	 * data should be inserted or updated.
	 *
	 * Will work with a map, or with an object that has a toRawArray() method.
	 *
	 * @throws ReflectionException
	--->
	<cffunction name="save" access="public" returntype="boolean" output="no">
		<cfargument name="row" type="any" required="yes">
		<cfset var response = "">

		<cfif StructCount(toArrayCast_(arguments.row)) EQ 0>
			<cfreturn true>
		</cfif>

		<cfif shouldUpdate(arguments.row)>
			<cfset response = update(getIdValue(arguments.row), arguments.row)>
		<cfelse>
			<cfset response = insert_(arguments.row, false)>

			<cfif truthy_(response)>
				<cfset response = true>
			</cfif>
		</cfif>

		<cfif NOT truthy_(response)>
			<cfreturn false>
		</cfif>

		<cfreturn true>
	</cffunction>

	<!---
	 * This method is called on save to determine if entry have to be updated.
	 * If this method returns `false` insert operation will be executed.
	--->
	<cffunction name="shouldUpdate" access="private" returntype="boolean" output="no">
		<cfargument name="row" type="any" required="yes">

		<cfreturn parentShouldUpdate_(arguments.row)>
	</cffunction>

	<!---
	 * Not in the original. The code of shouldUpdate(), which Model reaches by
	 * name (see the header).
	--->
	<cffunction name="parentShouldUpdate_" access="private" returntype="boolean" output="no">
		<cfargument name="row" type="any" required="yes">
		<cfset var id = getIdValue(arguments.row)>

		<cfif isNullMarker_(id)>
			<cfreturn false>
		</cfif>

		<cfif IsSimpleValue(id)>
			<cfreturn Len(id) GT 0>
		</cfif>

		<cfif isArr_(id)>
			<cfreturn NOT isEmpty_(id)>
		</cfif>

		<cfreturn true>
	</cffunction>

	<!---
	 * Returns last insert ID or 0.
	 *
	 * @return int|string
	--->
	<cffunction name="getInsertID" access="public" returntype="any" output="no">

		<cfif IsSimpleValue(this.insertID) AND IsNumeric(this.insertID)>
			<cfreturn Int(this.insertID)>
		</cfif>

		<cfreturn this.insertID>
	</cffunction>

	<!---
	 * Validates that the primary key values are valid for update/delete/insert operations.
	 * Throws exception if invalid.
	 *
	 * Difference: a number and its text are the same value here, so 0 and '0'
	 * are both written 0 in the message, and the text "true" and "false" are
	 * the booleans.
	 *
	 * @param id         The value, or a list of values
	 * @param allowArray Whether to allow array of IDs (true for update/delete, false for insert)
	 *
	 * @throws InvalidArgumentException
	--->
	<cffunction name="validateID" access="private" returntype="void" output="no">
		<cfargument name="id" type="any" required="yes">
		<cfargument name="allowArray" type="boolean" required="no" default="true">
		<cfset var values = "">
		<cfset var keys = "">
		<cfset var type = "">
		<cfset var i = 0>

		<cfif isArr_(arguments.id)>
			<!--- Check if arrays are allowed --->
			<cfif NOT arguments.allowArray>
				<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Invalid primary key: only a single value is allowed, not an array.">
			</cfif>

			<!--- Check for empty array --->
			<cfif isEmpty_(arguments.id)>
				<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Invalid primary key: cannot be an empty array.">
			</cfif>

			<!--- Validate each ID in the array recursively --->
			<cfif IsArray(arguments.id)>
				<cfset keys = ArrayNew(1)>

				<cfloop from="0" to="#ArrayLen(arguments.id) - 1#" index="i">
					<cfset ArrayAppend(keys, i)>
				</cfloop>

				<cfset values = arguments.id>
			<cfelse>
				<cfset keys = array_keys(arguments.id)>
				<cfset values = ArrayNew(1)>

				<cfloop from="1" to="#ArrayLen(keys)#" index="i">
					<cfset ArrayAppend(values, arguments.id[keys[i]])>
				</cfloop>
			</cfif>

			<cfloop from="1" to="#ArrayLen(values)#" index="i">
				<cfif isArr_(values[i])>
					<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Invalid primary key at index #keys[i]#: nested arrays are not allowed.">
				</cfif>

				<!--- Recursive call for each value (single values only in recursion) --->
				<cfset validateID(values[i], false)>
			</cfloop>

			<cfreturn>
		</cfif>

		<!--- Allow RawSql objects for complex scenarios --->
		<cfif instanceof_(arguments.id, "RawSql")>
			<cfreturn>
		</cfif>

		<!--- Check for invalid single values --->
		<cfif isNullMarker_(arguments.id)>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Invalid primary key: NULL is not allowed.">
		</cfif>

		<cfif IsSimpleValue(arguments.id)>
			<cfif Compare(arguments.id, "") EQ 0>
				<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Invalid primary key: '' is not allowed.">
			</cfif>

			<cfif Compare(arguments.id, "0") EQ 0>
				<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Invalid primary key: 0 is not allowed.">
			</cfif>

			<cfif Compare(arguments.id, "true") EQ 0>
				<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Invalid primary key: boolean true is not allowed.">
			</cfif>

			<cfif Compare(arguments.id, "false") EQ 0>
				<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Invalid primary key: boolean false is not allowed.">
			</cfif>

			<cfreturn>
		</cfif>

		<!--- Only allow int and string at this point --->
		<cfif IsObject(arguments.id)>
			<cfset type = ListLast(GetMetaData(arguments.id).name, ".")>
		<cfelse>
			<cfset type = "value">
		</cfif>

		<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Invalid primary key: must be int or string, #type# given.">
	</cffunction>

	<!---
	 * Inserts data into the database. If a map is provided it is used as
	 * the row.
	 *
	 * Named insert_(), as insert() is a built-in function.
	 *
	 * @param row      A row, or omitted for none
	 * @param returnID Whether insert ID should be returned or not.
	 *
	 * @return ($returnID is true ? false|int|string : bool)
	 *
	 * @throws ReflectionException
	--->
	<cffunction name="insert_" access="public" returntype="any" output="no">
		<cfargument name="row" type="any" required="no">
		<cfargument name="returnID" type="boolean" required="no" default="true">

		<cfif StructKeyExists(arguments, "row")>
			<cfreturn parentInsert_(arguments.row, arguments.returnID)>
		</cfif>

		<cfreturn parentInsert_(nullValue_(), arguments.returnID)>
	</cffunction>

	<!---
	 * Not in the original. The code of insert(), which Model reaches by name
	 * (see the header).
	 *
	 * @param row A row, or new_("ColdIgniter\Database\NullValue") for none
	--->
	<cffunction name="parentInsert_" access="private" returntype="any" output="no">
		<cfargument name="row" type="any" required="yes">
		<cfargument name="returnID" type="boolean" required="yes">
		<cfset var row_ = "">
		<cfset var cleanValidationRules = this.cleanValidationRules>
		<cfset var date = "">
		<cfset var eventData = "">
		<cfset var result = "">

		<cfset this.insertID = 0>

		<!--- Set $cleanValidationRules to false temporary. --->
		<cfset this.cleanValidationRules = "false">

		<cfset row_ = transformDataToArray(arguments.row, "insert")>

		<!--- Validate data before saving. --->
		<cfif NOT truthy_(this.skipValidation_)>
			<cfif NOT validate(row_)>
				<!--- Restore $cleanValidationRules --->
				<cfset this.cleanValidationRules = cleanValidationRules>

				<cfreturn "false">
			</cfif>
		</cfif>

		<!--- Restore $cleanValidationRules --->
		<cfset this.cleanValidationRules = cleanValidationRules>

		<!---
		 * Must be called first, so we don't
		 * strip out created_at values.
		--->
		<cfset row_ = doProtectFieldsForInsert(row_)>

		<!---
		 * doProtectFields() can further remove elements from
		 * $row, so we need to check for empty dataset again
		--->
		<cfif NOT truthy_(this.allowEmptyInserts_) AND isEmpty_(row_)>
			<cfset static_("ColdIgniter\Database\Exceptions\DataException").forEmptyDataset("insert")>
		</cfif>

		<!--- Set created_at and updated_at with same time --->
		<cfset date = setDate()>
		<cfset row_ = setCreatedField(row_, date)>
		<cfset row_ = setUpdatedField(row_, date)>

		<cfset eventData = array_("data", row_)>

		<cfif truthy_(this.tempAllowCallbacks)>
			<cfset eventData = trigger("beforeInsert", eventData)>
		</cfif>

		<cfset result = doInsert(eventData["data"])>

		<cfset eventData = array_("id", this.insertID, "data", eventData["data"], "result", result)>

		<cfif truthy_(this.tempAllowCallbacks)>
			<!--- Trigger afterInsert events with the inserted data and new ID --->
			<cfset trigger("afterInsert", eventData)>
		</cfif>

		<cfset this.tempAllowCallbacks = this.allowCallbacks_>

		<!--- If insertion failed, get out of here --->
		<cfif NOT truthy_(result)>
			<cfreturn result>
		</cfif>

		<!--- otherwise return the insertID, if requested. --->
		<cfif arguments.returnID>
			<cfreturn this.insertID>
		</cfif>

		<cfreturn result>
	</cffunction>

	<!---
	 * Set datetime to created field.
	 *
	 * @param row  A row
	 * @param date Timestamp or datetime string.
	 *
	 * @return row_array
	--->
	<cffunction name="setCreatedField" access="private" returntype="any" output="no">
		<cfargument name="row" type="any" required="yes">
		<cfargument name="date" type="any" required="yes">

		<cfif truthy_(this.useTimestamps) AND Len(this.createdField) GT 0>
			<cfif NOT array_key_exists(this.createdField, arguments.row)>
				<cfset arguments.row[this.createdField] = arguments.date>
			</cfif>
		</cfif>

		<cfreturn arguments.row>
	</cffunction>

	<!---
	 * Set datetime to updated field.
	 *
	 * @param row  A row
	 * @param date Timestamp or datetime string
	 *
	 * @return row_array
	--->
	<cffunction name="setUpdatedField" access="private" returntype="any" output="no">
		<cfargument name="row" type="any" required="yes">
		<cfargument name="date" type="any" required="yes">

		<cfif truthy_(this.useTimestamps) AND Len(this.updatedField) GT 0>
			<cfif NOT array_key_exists(this.updatedField, arguments.row)>
				<cfset arguments.row[this.updatedField] = arguments.date>
			</cfif>
		</cfif>

		<cfreturn arguments.row>
	</cffunction>

	<!---
	 * Compiles batch insert runs the queries, validating each row prior.
	 *
	 * @param set_      A list of rows, or omitted for none
	 * @param escape    Whether to escape values, an empty string is null
	 * @param batchSize The size of the batch to run.
	 * @param testing   `true` means only number of records is returned, `false` will execute the query.
	 *
	 * @return false|int|list<string> Number of rows inserted or `false` on failure.
	 *
	 * @throws ReflectionException
	--->
	<cffunction name="insertBatch" access="public" returntype="any" output="no">
		<cfargument name="set_" type="any" required="no" default="">
		<cfargument name="escape" type="any" required="no" default="">
		<cfargument name="batchSize" type="numeric" required="no" default="100">
		<cfargument name="testing" type="boolean" required="no" default="false">
		<cfset var cleanValidationRules = this.cleanValidationRules>
		<cfset var set = arguments.set_>
		<cfset var row = "">
		<cfset var rows = ArrayNew(1)>
		<cfset var date = "">
		<cfset var eventData = "">
		<cfset var result = "">
		<cfset var i = 0>

		<!--- Set $cleanValidationRules to false temporary. --->
		<cfset this.cleanValidationRules = "false">

		<cfif IsArray(set)>
			<cfloop from="1" to="#ArrayLen(set)#" index="i">
				<cfset row = transformDataToArray(set[i], "insert")>

				<!--- Validate every row. --->
				<cfif NOT truthy_(this.skipValidation_)>
					<cfif NOT validate(row)>
						<!--- Restore $cleanValidationRules --->
						<cfset this.cleanValidationRules = cleanValidationRules>

						<cfreturn "false">
					</cfif>
				</cfif>

				<!---
				 * Must be called first so we don't
				 * strip out created_at values.
				--->
				<cfset row = doProtectFieldsForInsert(row)>

				<!--- Set created_at and updated_at with same time --->
				<cfset date = setDate()>
				<cfset row = setCreatedField(row, date)>
				<cfset row = setUpdatedField(row, date)>

				<cfset ArrayAppend(rows, row)>
			</cfloop>

			<cfset set = rows>
		</cfif>

		<!--- Restore $cleanValidationRules --->
		<cfset this.cleanValidationRules = cleanValidationRules>

		<cfset eventData = array_("data", markNull_(set))>

		<cfif truthy_(this.tempAllowCallbacks)>
			<cfset eventData = trigger("beforeInsertBatch", eventData)>
		</cfif>

		<cfset result = doInsertBatch(unmarkNull_(eventData["data"]), arguments.escape, arguments.batchSize, arguments.testing)>

		<cfset eventData = array_("data", eventData["data"], "result", result)>

		<cfif truthy_(this.tempAllowCallbacks)>
			<!--- Trigger afterInsert events with the inserted data and new ID --->
			<cfset trigger("afterInsertBatch", eventData)>
		</cfif>

		<cfset this.tempAllowCallbacks = this.allowCallbacks_>

		<cfreturn result>
	</cffunction>

	<!---
	 * Updates a single record in the database. If a map is provided
	 * it is used as the row.
	 *
	 * @param id  An id, a list of ids, a RawSql, or omitted for none
	 * @param row A row, or omitted for none
	 *
	 * @throws ReflectionException
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

		<cfreturn parentUpdate_(id_, row_)>
	</cffunction>

	<!---
	 * Not in the original. The code of update(), which Model reaches by name
	 * (see the header).
	 *
	 * @param id  An id, a list of ids, a RawSql, or new_("ColdIgniter\Database\NullValue") for none
	 * @param row A row, or new_("ColdIgniter\Database\NullValue") for none
	--->
	<cffunction name="parentUpdate_" access="private" returntype="boolean" output="no">
		<cfargument name="id" type="any" required="yes">
		<cfargument name="row" type="any" required="yes">
		<cfset var id_ = arguments.id>
		<cfset var row_ = "">
		<cfset var eventData = "">

		<cfif NOT isNullMarker_(id_)>
			<cfif NOT isArr_(id_)>
				<cfset id_ = ArrayNew(1)>
				<cfset ArrayAppend(id_, arguments.id)>
			</cfif>

			<cfset validateID(id_)>
		</cfif>

		<cfset row_ = transformDataToArray(arguments.row, "update")>

		<!--- Validate data before saving. --->
		<cfif NOT truthy_(this.skipValidation_)>
			<cfif NOT validate(row_)>
				<cfreturn false>
			</cfif>
		</cfif>

		<!---
		 * Must be called first, so we don't
		 * strip out updated_at values.
		--->
		<cfset row_ = doProtectFields(row_)>

		<!---
		 * doProtectFields() can further remove elements from
		 * $row, so we need to check for empty dataset again
		--->
		<cfif isEmpty_(row_)>
			<cfset static_("ColdIgniter\Database\Exceptions\DataException").forEmptyDataset("update")>
		</cfif>

		<cfset row_ = setUpdatedField(row_, setDate())>

		<cfset eventData = array_("id", id_, "data", row_)>

		<cfif truthy_(this.tempAllowCallbacks)>
			<cfset eventData = trigger("beforeUpdate", eventData)>
		</cfif>

		<cfset eventData = array_("id", id_, "data", eventData["data"], "result", doUpdate(id_, eventData["data"]))>

		<cfif truthy_(this.tempAllowCallbacks)>
			<cfset trigger("afterUpdate", eventData)>
		</cfif>

		<cfset this.tempAllowCallbacks = this.allowCallbacks_>

		<cfreturn truthy_(eventData["result"])>
	</cffunction>

	<!---
	 * Compiles an update and runs the query.
	 *
	 * @param set_      A list of rows, or omitted for none
	 * @param index     The where key, an empty string is null
	 * @param batchSize The size of the batch to run.
	 * @param returnSQL `true` means SQL is returned, `false` will execute the query.
	 *
	 * @return false|int|list<string> Number of rows affected or `false` on failure, SQL array when test mode.
	 *
	 * @throws DatabaseException
	 * @throws ReflectionException
	--->
	<cffunction name="updateBatch" access="public" returntype="any" output="no">
		<cfargument name="set_" type="any" required="no" default="">
		<cfargument name="index" type="any" required="no" default="">
		<cfargument name="batchSize" type="numeric" required="no" default="100">
		<cfargument name="returnSQL" type="boolean" required="no" default="false">
		<cfset var set = arguments.set_>
		<cfset var row = "">
		<cfset var rows = ArrayNew(1)>
		<cfset var updateIndex = "">
		<cfset var hasUpdateIndex = "false">
		<cfset var raw = "">
		<cfset var eventData = "">
		<cfset var result = "">
		<cfset var i = 0>

		<cfif IsArray(set)>
			<cfloop from="1" to="#ArrayLen(set)#" index="i">
				<!---
				 * Save the index value from the original row because
				 * transformDataToArray() may strip it when updateOnlyChanged
				 * is true.
				--->
				<cfset hasUpdateIndex = "false">

				<cfif truthy_(this.updateOnlyChanged)>
					<cfset raw = toArrayCast_(set[i])>

					<cfif isSet_(raw, arguments.index)>
						<cfset updateIndex = raw[arguments.index]>
						<cfset hasUpdateIndex = "true">
					</cfif>
				</cfif>

				<cfset row = transformDataToArray(set[i], "update")>

				<!--- Validate data before saving. --->
				<cfif NOT truthy_(this.skipValidation_)>
					<cfif NOT validate(row)>
						<cfreturn "false">
					</cfif>
				</cfif>

				<!---
				 * When updateOnlyChanged is true, restore the pre-extracted
				 * index into $row. Otherwise read it from the transformed row.
				--->
				<cfif hasUpdateIndex>
					<cfset row[arguments.index] = updateIndex>
				<cfelseif isSet_(row, arguments.index)>
					<cfset updateIndex = row[arguments.index]>
					<cfset hasUpdateIndex = "true">
				</cfif>

				<cfif NOT hasUpdateIndex>
					<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="The index (""#arguments.index#"") for updateBatch() is missing in the data: #json_encode(row)#">
				</cfif>

				<!---
				 * Must be called first so we don't
				 * strip out updated_at values.
				--->
				<cfset row = doProtectFields(row)>

				<!--- Restore updateIndex value in case it was wiped out --->
				<cfset row[arguments.index] = updateIndex>

				<cfset row = setUpdatedField(row, setDate())>

				<cfset ArrayAppend(rows, row)>
			</cfloop>

			<cfset set = rows>
		</cfif>

		<cfset eventData = array_("data", markNull_(set))>

		<cfif truthy_(this.tempAllowCallbacks)>
			<cfset eventData = trigger("beforeUpdateBatch", eventData)>
		</cfif>

		<cfset result = doUpdateBatch(unmarkNull_(eventData["data"]), arguments.index, arguments.batchSize, arguments.returnSQL)>

		<cfset eventData = array_("data", eventData["data"], "result", result)>

		<cfif truthy_(this.tempAllowCallbacks)>
			<!--- Trigger afterInsert events with the inserted data and new ID --->
			<cfset trigger("afterUpdateBatch", eventData)>
		</cfif>

		<cfset this.tempAllowCallbacks = this.allowCallbacks_>

		<cfreturn result>
	</cffunction>

	<!---
	 * Deletes a single record from the database where $id matches.
	 *
	 * @param id    An id, a list of ids, a RawSql, or omitted for none
	 * @param purge Allows overriding the soft deletes setting.
	 *
	 * @return bool|string Returns a SQL string if in test mode.
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="delete" access="public" returntype="any" output="no">
		<cfargument name="id" type="any" required="no">
		<cfargument name="purge" type="boolean" required="no" default="false">
		<cfset var id_ = nullValue_()>
		<cfset var eventData = "">

		<cfif StructKeyExists(arguments, "id") AND NOT isNullMarker_(arguments.id)>
			<cfset id_ = arguments.id>

			<cfif NOT isArr_(id_)>
				<cfset id_ = ArrayNew(1)>
				<cfset ArrayAppend(id_, arguments.id)>
			</cfif>

			<cfset validateID(id_)>
		</cfif>

		<cfset eventData = array_("id", id_, "purge", arguments.purge)>

		<cfif truthy_(this.tempAllowCallbacks)>
			<cfset trigger("beforeDelete", eventData)>
		</cfif>

		<cfset eventData = array_("id", id_, "data", nullValue_(), "purge", arguments.purge, "result", doDelete(id_, arguments.purge))>

		<cfif truthy_(this.tempAllowCallbacks)>
			<cfset trigger("afterDelete", eventData)>
		</cfif>

		<cfset this.tempAllowCallbacks = this.allowCallbacks_>

		<cfreturn eventData["result"]>
	</cffunction>

	<!---
	 * Permanently deletes all rows that have been marked as deleted
	 * through soft deletes (value of column $deletedField is not null).
	 *
	 * @return bool|string Returns a SQL string if in test mode.
	--->
	<cffunction name="purgeDeleted" access="public" returntype="any" output="no">

		<cfif NOT truthy_(this.useSoftDeletes)>
			<cfreturn true>
		</cfif>

		<cfreturn doPurgeDeleted()>
	</cffunction>

	<!---
	 * Sets $useSoftDeletes value so that we can temporarily override
	 * the soft deletes settings. Can be used for all find* methods.
	 *
	 * @return $this
	--->
	<cffunction name="withDeleted" access="public" returntype="any" output="no">
		<cfargument name="val" type="boolean" required="no" default="true">

		<cfset this.tempUseSoftDeletes = NOT arguments.val>

		<cfreturn this>
	</cffunction>

	<!---
	 * Works with the $this->find* methods to return only the rows that
	 * have been deleted.
	 *
	 * @return $this
	--->
	<cffunction name="onlyDeleted" access="public" returntype="any" output="no">

		<cfset this.tempUseSoftDeletes = "false">
		<cfset doOnlyDeleted()>

		<cfreturn this>
	</cffunction>

	<!---
	 * Compiles a replace and runs the query.
	 *
	 * Named replace_(), as replace() is a built-in function.
	 *
	 * @param row       A row, or omitted for none
	 * @param returnSQL `true` means SQL is returned, `false` will execute the query.
	 *
	 * @return BaseResult|false|Query|string
	 *
	 * @throws DataException
	--->
	<cffunction name="replace_" access="public" returntype="any" output="no">
		<cfargument name="row" type="any" required="no">
		<cfargument name="returnSQL" type="boolean" required="no" default="false">
		<cfset var row_ = "">
		<cfset var hasData = "false">

		<!--- Validate data before saving. --->
		<cfif StructKeyExists(arguments, "row") AND NOT isNullMarker_(arguments.row)>
			<cfif NOT truthy_(this.skipValidation_)>
				<cfif NOT validate(arguments.row)>
					<cfreturn "false">
				</cfif>
			</cfif>
		</cfif>

		<cfif StructKeyExists(arguments, "row")>
			<cfset row_ = copyMap_(toArrayCast_(arguments.row))>
		<cfelse>
			<cfset row_ = array_()>
		</cfif>

		<cfset hasData = NOT isEmpty_(row_)>
		<cfset row_ = doProtectFieldsForReplace(row_)>

		<cfif hasData AND isEmpty_(row_)>
			<cfset static_("ColdIgniter\Database\Exceptions\DataException").forEmptyDataset("replace")>
		</cfif>

		<cfset row_ = setCreatedField(row_, setDate())>
		<cfset row_ = setUpdatedField(row_, setDate())>

		<cfreturn doReplace(row_, arguments.returnSQL)>
	</cffunction>

	<!---
	 * Grabs the last error(s) that occurred.
	 *
	 * If data was validated, it will first check for errors there,
	 *  otherwise will try to grab the last error from the Database connection.
	 *
	 * The return map should be in the following format:
	 *  `['source' => 'message']`.
	 *
	 * @param forceDB Always grab the DB error, not validation.
	 *
	 * @return array<string, string>
	--->
	<cffunction name="errors" access="public" returntype="any" output="no">
		<cfargument name="forceDB" type="boolean" required="no" default="false">
		<cfset var errors_ = "">

		<cfif NOT IsObject(this.validation)>
			<cfreturn doErrors()>
		</cfif>

		<!--- Do we have validation errors? --->
		<cfif NOT arguments.forceDB AND NOT truthy_(this.skipValidation_)>
			<cfset errors_ = this.validation.getErrors()>

			<cfif NOT isEmpty_(errors_)>
				<cfreturn errors_>
			</cfif>
		</cfif>

		<cfreturn doErrors()>
	</cffunction>

	<!---
	 * Works with Pager to get the size and offset parameters.
	 * Expects a GET variable (?page=2) that specifies the page of results
	 * to display.
	 *
	 * @param perPage Items per page, an empty string is null
	 * @param group   Will be used by the pagination library to identify a unique pagination set.
	 * @param page    Optional page number (useful when the page number is provided in different way).
	 * @param segment Optional URI segment number (if page number is provided by URI segment).
	 *
	 * @return list<object|row_array>
	--->
	<cffunction name="paginate" access="public" returntype="any" output="no">
		<cfargument name="perPage" type="any" required="no" default="">
		<cfargument name="group" type="string" required="no" default="default">
		<cfargument name="page" type="any" required="no" default="">
		<cfargument name="segment" type="numeric" required="no" default="0">

		<cfset var pager = "">
		<cfset var pageNo = arguments.page>
		<cfset var size = "">
		<cfset var offset = 0>

		<!--- Since multiple models may use the Pager, the Pager must be shared. --->
		<cfset pager = service("pager")>

		<cfif arguments.segment NEQ 0>
			<cfset pager.setSegment(arguments.segment, arguments.group)>
		</cfif>

		<cfif is_null(pageNo) OR pageNo LT 1>
			<cfset pageNo = pager.getCurrentPage(arguments.group)>
		</cfif>

		<!--- Store it in the Pager library, so it can be paginated in the views. --->
		<cfset this.pager = pager.store(arguments.group, pageNo, arguments.perPage, this.countAllResults(false), arguments.segment)>
		<cfset size = this.pager.getPerPage(arguments.group)>
		<cfset offset = (pager.getCurrentPage(arguments.group) - 1) * size>

		<cfreturn findAll(size, offset)>
	</cffunction>

	<!---
	 * It could be used when you have to change default or override current allowed fields.
	 *
	 * @param allowedFields List with names of fields.
	 *
	 * @return $this
	--->
	<cffunction name="setAllowedFields" access="public" returntype="any" output="no">
		<cfargument name="allowedFields" type="array" required="yes">

		<cfset this.allowedFields = arguments.allowedFields>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets whether or not we should whitelist data set during
	 * updates or inserts against $this->availableFields.
	 *
	 * @return $this
	--->
	<cffunction name="protect" access="public" returntype="any" output="no">
		<cfargument name="protect" type="boolean" required="no" default="true">

		<cfset this.protectFields = arguments.protect>

		<cfreturn this>
	</cffunction>

	<!---
	 * Ensures that only the fields that are allowed to be updated are
	 * in the data array.
	 *
	 * @used-by update() to protect against mass assignment vulnerabilities.
	 * @used-by updateBatch() to protect against mass assignment vulnerabilities.
	 *
	 * @param row_array $row
	 *
	 * @return row_array
	 *
	 * @throws DataException
	--->
	<cffunction name="doProtectFields" access="private" returntype="any" output="no">
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
			<cfif in_array(keys[i], this.allowedFields)>
				<cfset result[keys[i]] = arguments.row[keys[i]]>
			</cfif>
		</cfloop>

		<cfreturn result>
	</cffunction>

	<!---
	 * Ensures that only the fields that are allowed to be inserted are in
	 * the data array.
	 *
	 * @used-by insert() to protect against mass assignment vulnerabilities.
	 * @used-by insertBatch() to protect against mass assignment vulnerabilities.
	 *
	 * @param row_array $row
	 *
	 * @return row_array
	 *
	 * @throws DataException
	--->
	<cffunction name="doProtectFieldsForInsert" access="private" returntype="any" output="no">
		<cfargument name="row" type="any" required="yes">

		<cfreturn doProtectFields(arguments.row)>
	</cffunction>

	<!---
	 * Protects replacement data before generated timestamps are added.
	 *
	 * @param row_array $row
	 *
	 * @return row_array
	 *
	 * @throws DataException
	--->
	<cffunction name="doProtectFieldsForReplace" access="private" returntype="any" output="no">
		<cfargument name="row" type="any" required="yes">

		<cfreturn doProtectFields(arguments.row)>
	</cffunction>

	<!---
	 * Sets the timestamp or current timestamp if null value is passed.
	 *
	 * @param userDate An optional Unix timestamp to be converted, or omitted
	 *                 (an empty string counts as omitted)
	 *
	 * @return int|string
	 *
	 * @throws ModelException
	--->
	<cffunction name="setDate" access="private" returntype="any" output="no">
		<cfargument name="userDate" type="any" required="no">

		<cfset var given = StructKeyExists(arguments, "userDate")>

		<!--- an empty string is a null, as everywhere --->
		<cfif given AND IsSimpleValue(arguments.userDate) AND Len(arguments.userDate) EQ 0>
			<cfset given = false>
		</cfif>

		<!--- a test instance of Time (Time::setTestNow) stands for the current time --->
		<cfif NOT given AND StructKeyExists(request.ColdIgniter, "testNowTime")>
			<cfreturn timeToDate(static_("ColdIgniter\I18n\Time").now_())>
		</cfif>

		<cfif NOT given AND Compare(this.dateFormat, "datetime") EQ 0>
			<cfreturn timeToDate(Now())>
		</cfif>

		<cfif given>
			<cfreturn intToDate(arguments.userDate)>
		</cfif>

		<cfreturn intToDate(time())>
	</cffunction>

	<!---
	 * A utility function to allow child models to use the type of
	 * date/time format that they prefer. This is primarily used for
	 * setting created_at, updated_at and deleted_at values, but can be
	 * used by inheriting classes.
	 *
	 * The available time formats are:
	 *  - 'int'      - Stores the date as an integer timestamp.
	 *  - 'datetime' - Stores the data in the SQL datetime format.
	 *  - 'date'     - Stores the date (only) in the SQL date format.
	 *
	 * @param value A Unix timestamp
	 *
	 * @return int|string
	 *
	 * @throws ModelException
	--->
	<cffunction name="intToDate" access="private" returntype="any" output="no">
		<cfargument name="value" type="numeric" required="yes">
		<cfset var moment = "">

		<cfif Compare(this.dateFormat, "int") EQ 0>
			<cfreturn arguments.value>
		</cfif>

		<cfif Compare(this.dateFormat, "datetime") NEQ 0 AND Compare(this.dateFormat, "date") NEQ 0>
			<cfset static_("ColdIgniter\Exceptions\ModelException").forNoDateFormat(className_())>
		</cfif>

		<!--- the milliseconds do not fit in an integer, so they are built from text --->
		<cfset moment = CreateObject("java", "java.util.Date").init(CreateObject("java", "java.lang.Long").parseLong(JavaCast("string", Int(arguments.value) & "000")))>

		<cfreturn date(this.db.dateFormat[this.dateFormat], moment)>
	</cffunction>

	<!---
	 * Converts Time value to string using $this->dateFormat.
	 *
	 * The available time formats are:
	 *  - 'int'      - Stores the date as an integer timestamp.
	 *  - 'datetime' - Stores the data in the SQL datetime format.
	 *  - 'date'     - Stores the date (only) in the SQL date format.
	 *
	 * Difference: the value is a Time, or a CFML date (a CFML date is cheaper
	 * than a Time, see setDate).
	 *
	 * @return int|string
	--->
	<cffunction name="timeToDate" access="private" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfif NOT IsSimpleValue(arguments.value)>
			<cfif Compare(this.dateFormat, "int") EQ 0>
				<cfreturn arguments.value.getTimestamp()>
			</cfif>

			<cfif Compare(this.dateFormat, "datetime") NEQ 0 AND Compare(this.dateFormat, "date") NEQ 0>
				<cfreturn arguments.value.__toString()>
			</cfif>

			<cfreturn arguments.value.format(this.db.dateFormat[this.dateFormat])>
		</cfif>

		<cfif Compare(this.dateFormat, "datetime") EQ 0 OR Compare(this.dateFormat, "date") EQ 0>
			<cfreturn date(this.db.dateFormat[this.dateFormat], arguments.value)>
		</cfif>

		<cfif Compare(this.dateFormat, "int") EQ 0>
			<cfreturn Int(arguments.value.getTime() / 1000)>
		</cfif>

		<cfreturn "" & arguments.value>
	</cffunction>

	<!---
	 * Set the value of the $skipValidation flag.
	 *
	 * @return $this
	--->
	<cffunction name="skipValidation" access="public" returntype="any" output="no">
		<cfargument name="skip" type="boolean" required="no" default="true">

		<cfset this.skipValidation_ = arguments.skip>

		<cfreturn this>
	</cffunction>

	<!---
	 * Allows to set (and reset) validation messages.
	 * It could be used when you have to change default or override current validate messages.
	 *
	 * @param validationMessages array<string, array<string, string>>
	 *
	 * @return $this
	--->
	<cffunction name="setValidationMessages" access="public" returntype="any" output="no">
		<cfargument name="validationMessages" type="any" required="yes">

		<cfset this.validationMessages = arguments.validationMessages>

		<cfreturn this>
	</cffunction>

	<!---
	 * Allows to set field wise validation message.
	 * It could be used when you have to change default or override current validate messages.
	 *
	 * @param fieldMessages array<string, string>
	 *
	 * @return $this
	--->
	<cffunction name="setValidationMessage" access="public" returntype="any" output="no">
		<cfargument name="field" type="string" required="yes">
		<cfargument name="fieldMessages" type="any" required="yes">

		<cfset this.validationMessages = copyMap_(this.validationMessages)>
		<cfset this.validationMessages[arguments.field] = arguments.fieldMessages>

		<cfreturn this>
	</cffunction>

	<!---
	 * Allows to set (and reset) validation rules.
	 * It could be used when you have to change default or override current validate rules.
	 *
	 * @param validationRules array<string, array<string, array<string, string>|string>|string>
	 *
	 * @return $this
	--->
	<cffunction name="setValidationRules" access="public" returntype="any" output="no">
		<cfargument name="validationRules" type="any" required="yes">

		<cfset this.validationRules = arguments.validationRules>

		<cfreturn this>
	</cffunction>

	<!---
	 * Allows to set field wise validation rules.
	 * It could be used when you have to change default or override current validate rules.
	 *
	 * @param fieldRules array<string, array<string, string>|string>|string
	 *
	 * @return $this
	--->
	<cffunction name="setValidationRule" access="public" returntype="any" output="no">
		<cfargument name="field" type="string" required="yes">
		<cfargument name="fieldRules" type="any" required="yes">
		<cfset var rules = this.validationRules>
		<cfset var loaded = "">

		<!---
		 * ValidationRules can be either a string, which is the group name,
		 * or an array of rules.
		--->
		<cfif IsSimpleValue(rules) AND Len(rules) GT 0>
			<cfset ensureValidation()>

			<cfset loaded = this.validation.loadRuleGroup(rules)>
			<cfset rules = loaded[1]>

			<cfset this.validationRules = rules>
			<cfset this.validationMessages = unionMap_(this.validationMessages, loaded[2])>
		</cfif>

		<cfset this.validationRules = copyMap_(this.validationRules)>
		<cfset this.validationRules[arguments.field] = arguments.fieldRules>

		<cfreturn this>
	</cffunction>

	<!---
	 * Should validation rules be removed before saving?
	 * Most handy when doing updates.
	 *
	 * @return $this
	--->
	<cffunction name="cleanRules" access="public" returntype="any" output="no">
		<cfargument name="choice" type="boolean" required="no" default="false">

		<cfset this.cleanValidationRules = arguments.choice>

		<cfreturn this>
	</cffunction>

	<!---
	 * Validate the row data against the validation rules (or the validation group)
	 * specified in the class property, $validationRules.
	 *
	 * @param row A row
	--->
	<cffunction name="validate" access="public" returntype="boolean" output="no">
		<cfargument name="row" type="any" required="yes">
		<cfset var rules = "">
		<cfset var row_ = "">

		<cfif truthy_(this.skipValidation_)>
			<cfreturn true>
		</cfif>

		<cfset rules = getValidationRules()>

		<cfif isEmpty_(rules)>
			<cfreturn true>
		</cfif>

		<!--- Validation requires array, so cast away. --->
		<cfset row_ = toArrayCast_(arguments.row)>

		<cfif isEmpty_(row_)>
			<cfreturn true>
		</cfif>

		<cfif truthy_(this.cleanValidationRules)>
			<cfset rules = cleanValidationRules_(rules, row_)>
		</cfif>

		<!---
		 * If no data existed that needs validation
		 * our job is done here.
		--->
		<cfif isEmpty_(rules)>
			<cfreturn true>
		</cfif>

		<cfset ensureValidation()>

		<cfset this.validation.reset()>
		<cfset this.validation.setRules(rules, this.validationMessages)>

		<cfreturn this.validation.run(row_, "", this.DBGroup)>
	</cffunction>

	<!---
	 * Returns the model's defined validation rules so that they
	 * can be used elsewhere, if needed.
	 *
	 * @param options A map with "only" or "except", a list of field names, to filter the list of rules
	 *
	 * @return array<string, array<string, array<string, string>|string>|string>
	--->
	<cffunction name="getValidationRules" access="public" returntype="any" output="no">
		<cfargument name="options" type="any" required="no" default="">
		<cfset var rules = this.validationRules>
		<cfset var loaded = "">
		<cfset var filtered = "">
		<cfset var keys = "">
		<cfset var i = 0>

		<!---
		 * ValidationRules can be either a string, which is the group name,
		 * or an array of rules.
		--->
		<cfif IsSimpleValue(rules) AND Len(rules) GT 0>
			<cfset ensureValidation()>

			<cfset loaded = this.validation.loadRuleGroup(rules)>
			<cfset rules = loaded[1]>

			<cfset this.validationMessages = unionMap_(this.validationMessages, loaded[2])>
		</cfif>

		<cfif IsSimpleValue(rules)>
			<cfset rules = array_()>
		</cfif>

		<cfif isMap_(arguments.options)>
			<cfif array_key_exists("except", arguments.options)>
				<!--- array_diff_key() --->
				<cfset filtered = array_()>
				<cfset keys = array_keys(rules)>

				<cfloop from="1" to="#ArrayLen(keys)#" index="i">
					<cfif NOT in_array(keys[i], arguments.options["except"])>
						<cfset filtered[keys[i]] = rules[keys[i]]>
					</cfif>
				</cfloop>

				<cfset rules = filtered>
			<cfelseif array_key_exists("only", arguments.options)>
				<!--- array_intersect_key() --->
				<cfset filtered = array_()>
				<cfset keys = array_keys(rules)>

				<cfloop from="1" to="#ArrayLen(keys)#" index="i">
					<cfif in_array(keys[i], arguments.options["only"])>
						<cfset filtered[keys[i]] = rules[keys[i]]>
					</cfif>
				</cfloop>

				<cfset rules = filtered>
			</cfif>
		</cfif>

		<cfreturn rules>
	</cffunction>

	<cffunction name="ensureValidation" access="private" returntype="void" output="no">

		<cfif NOT IsObject(this.validation)>
			<cfset this.validation = service("validation", "", false)>
		</cfif>
	</cffunction>

	<!---
	 * Returns the model's validation messages, so they
	 * can be used elsewhere, if needed.
	 *
	 * @return array<string, array<string, string>>
	--->
	<cffunction name="getValidationMessages" access="public" returntype="any" output="no">

		<cfreturn this.validationMessages>
	</cffunction>

	<!---
	 * Removes any rules that apply to fields that have not been set
	 * currently so that rules don't block updating when only updating
	 * a partial row.
	 *
	 * Named cleanValidationRules_(), as cleanValidationRules is a property.
	 *
	 * @param rules array<string, array<string, array<string, string>|string>|string>
	 * @param row   row_array
	 *
	 * @return array<string, array<string, array<string, string>|string>|string>
	--->
	<cffunction name="cleanValidationRules_" access="private" returntype="any" output="no">
		<cfargument name="rules" type="any" required="yes">
		<cfargument name="row" type="any" required="yes">
		<cfset var result = array_()>
		<cfset var keys = "">
		<cfset var i = 0>

		<cfif isEmpty_(arguments.row)>
			<cfreturn array_()>
		</cfif>

		<cfset keys = array_keys(arguments.rules)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfif array_key_exists(keys[i], arguments.row)>
				<cfset result[keys[i]] = arguments.rules[keys[i]]>
			</cfif>
		</cfloop>

		<cfreturn result>
	</cffunction>

	<!---
	 * Sets $tempAllowCallbacks value so that we can temporarily override
	 * the setting. Resets after the next method that uses triggers.
	 *
	 * @return $this
	--->
	<cffunction name="allowCallbacks" access="public" returntype="any" output="no">
		<cfargument name="val" type="boolean" required="no" default="true">

		<cfset this.tempAllowCallbacks = arguments.val>

		<cfreturn this>
	</cffunction>

	<!---
	 * A simple event trigger for Model Events that allows additional
	 * data manipulation within the model. Specifically intended for
	 * usage by child models this can be used to format data,
	 * save/load related classes, etc.
	 *
	 * It is the responsibility of the callback methods to return
	 * the data itself.
	 *
	 * Each $eventData map MUST have a 'data' key with the relevant
	 * data for callback methods (like a map of key/value pairs to insert
	 * or update, a list of results, etc.)
	 *
	 * If callbacks are not allowed then returns $eventData immediately.
	 *
	 * Difference: a callback is the name of a method of the model, public or
	 * not, and has to be a plain name.
	 *
	 * @param event     Valid property of the model event: $this->before*, $this->after*, etc.
	 * @param eventData A map
	 *
	 * @return The map
	 *
	 * @throws DataException
	--->
	<cffunction name="trigger" access="private" returntype="any" output="no">
		<cfargument name="event" type="string" required="yes">
		<cfargument name="eventData" type="any" required="yes">
		<cfset var data = arguments.eventData>
		<cfset var callback = "">
		<cfset var i = 0>

		<!--- Ensure it's a valid event --->
		<cfif NOT StructKeyExists(this, arguments.event) OR isEmpty_(this[arguments.event])>
			<cfreturn arguments.eventData>
		</cfif>

		<cfloop from="1" to="#ArrayLen(this[arguments.event])#" index="i">
			<cfset callback = this[arguments.event][i]>

			<cfif REFind("^[A-Za-z_][A-Za-z0-9_]*$", callback) EQ 0>
				<cfset static_("ColdIgniter\Database\Exceptions\DataException").forInvalidMethodTriggered(callback)>
			</cfif>

			<cfif NOT StructKeyExists(variables, callback) OR NOT IsCustomFunction(variables[callback])>
				<cfset static_("ColdIgniter\Database\Exceptions\DataException").forInvalidMethodTriggered(callback)>
			</cfif>

			<cfset data = Evaluate("#callback#(data)")>
		</cfloop>

		<cfreturn data>
	</cffunction>

	<!---
	 * Sets the return type of the results to be as an associative array.
	 *
	 * @return $this
	--->
	<cffunction name="asArray" access="public" returntype="any" output="no">

		<cfset this.tempReturnType = "array">

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets the return type to be of the specified type of object.
	 * Defaults to a simple object, but can be any class that has
	 * class vars with the same name as the collection columns,
	 * or at least allows them to be created.
	 *
	 * Difference: 'object' gives maps (there is no stdClass), and a class
	 * name gives the objects of that class.
	 *
	 * @param class 'object'|class-string
	 *
	 * @return $this
	--->
	<cffunction name="asObject" access="public" returntype="any" output="no">
		<cfargument name="class" type="string" required="no" default="object">

		<cfset this.tempReturnType = arguments.class>

		<cfreturn this>
	</cffunction>

	<!---
	 * Takes a class and returns an array of its public and protected
	 * properties as an array suitable for use in creates and updates.
	 * This method uses `$this->objectToRawArray()` internally and does conversion
	 * to string on all Time instances.
	 *
	 * @param object     $object
	 * @param onlyChanged Returns only the changed properties.
	 * @param recursive   If `true`, inner entities will be cast as array as well.
	 *
	 * @return array<string, mixed>
	 *
	 * @throws ReflectionException
	--->
	<cffunction name="objectToArray" access="private" returntype="any" output="no">
		<cfargument name="object" type="any" required="yes">
		<cfargument name="onlyChanged" type="boolean" required="no" default="true">
		<cfargument name="recursive" type="boolean" required="no" default="false">
		<cfset var properties = objectToRawArray(arguments.object, arguments.onlyChanged, arguments.recursive)>

		<!--- Convert any Time instances to appropriate $dateFormat --->
		<cfreturn timeToString(properties)>
	</cffunction>

	<!---
	 * Convert any Time instances to appropriate $dateFormat.
	 *
	 * @param properties array<string, mixed>
	 *
	 * @return array<string, mixed>
	--->
	<cffunction name="timeToString" access="private" returntype="any" output="no">
		<cfargument name="properties" type="any" required="yes">
		<cfset var copy = copyMap_(arguments.properties)>
		<cfset var keys = array_keys(copy)>
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfif IsObject(copy[keys[i]]) AND instanceof_(copy[keys[i]], "ColdIgniter\I18n\Time")>
				<cfset copy[keys[i]] = timeToDate(copy[keys[i]])>
			</cfif>
		</cfloop>

		<cfreturn copy>
	</cffunction>

	<!---
	 * Takes a class and returns an array of its public and protected
	 * properties as an array with raw values.
	 *
	 * Difference: there is no reflection, so only an object that has a
	 * toRawArray() method is read, and any other object throws.
	 *
	 * @param object      The object
	 * @param onlyChanged Returns only the changed properties.
	 * @param recursive   If `true`, inner entities will be cast as array as well.
	 *
	 * @return array<string, mixed> Array with raw values
	 *
	 * @throws ReflectionException
	--->
	<cffunction name="objectToRawArray" access="private" returntype="any" output="no">
		<cfargument name="object" type="any" required="yes">
		<cfargument name="onlyChanged" type="boolean" required="no" default="true">
		<cfargument name="recursive" type="boolean" required="no" default="false">
		<cfset var properties = "">

		<!--- Entity::toRawArray() returns array --->
		<cfif method_exists(arguments.object, "toRawArray")>
			<cfset properties = arguments.object.toRawArray(arguments.onlyChanged, arguments.recursive)>
		<cfelse>
			<cfthrow type="ColdIgniter.LogicException" message="Not ported yet: reading the properties of an object without a toRawArray() method (#className_()#).">
		</cfif>

		<cfreturn properties>
	</cffunction>

	<!---
	 * Transform data to array.
	 *
	 * @param row  A row, an object, or new_("ColdIgniter\Database\NullValue") for none
	 * @param type "insert" or "update"
	 *
	 * @return array<array-key, mixed>
	 *
	 * @throws DataException
	 * @throws InvalidArgumentException
	 * @throws ReflectionException
	 *
	 * @used-by insert()
	 * @used-by insertBatch()
	 * @used-by update()
	 * @used-by updateBatch()
	--->
	<cffunction name="transformDataToArray" access="private" returntype="any" output="no">
		<cfargument name="row" type="any" required="yes">
		<cfargument name="type" type="string" required="yes">
		<cfset var row_ = arguments.row>
		<cfset var onlyChanged = "false">

		<cfif Compare(arguments.type, "insert") NEQ 0 AND Compare(arguments.type, "update") NEQ 0>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Invalid type ""#arguments.type#"" used upon transforming data to array.">
		</cfif>

		<cfif NOT truthy_(this.allowEmptyInserts_) AND isEmpty_(toArrayCast_(row_))>
			<cfset static_("ColdIgniter\Database\Exceptions\DataException").forEmptyDataset(arguments.type)>
		</cfif>

		<!--- If it validates with entire rules, all fields are needed. --->
		<cfif NOT truthy_(this.skipValidation_) AND NOT truthy_(this.cleanValidationRules)>
			<cfset onlyChanged = "false">
		<cfelse>
			<cfset onlyChanged = Compare(arguments.type, "update") EQ 0 AND truthy_(this.updateOnlyChanged)>
		</cfif>

		<cfif useCasts()>
			<cfif isMap_(row_)>
				<cfset row_ = this.converter.toDataSource(row_)>
			<cfelseif IsObject(row_) AND NOT isNullMarker_(row_)>
				<cfset row_ = this.converter.extract(row_, onlyChanged)>
			</cfif>
		<!---
		 * If $row is using a custom class with public or protected
		 * properties representing the collection elements, we need to grab
		 * them as an array.
		--->
		<cfelseif IsObject(row_) AND NOT isNullMarker_(row_)>
			<cfset row_ = objectToArray(row_, onlyChanged, true)>
		</cfif>

		<cfset row_ = toArrayCast_(row_)>

		<!--- If it's still empty here, means $row is no change or is empty object --->
		<cfif NOT truthy_(this.allowEmptyInserts_) AND isEmpty_(row_)>
			<cfset static_("ColdIgniter\Database\Exceptions\DataException").forEmptyDataset(arguments.type)>
		</cfif>

		<!--- Convert any Time instances to appropriate $dateFormat --->
		<cfreturn timeToString(row_)>
	</cffunction>

	<!---
	 * Provides the DB connection and model's properties.
	 *
	 * Difference: __get() is a public method that is called by name:
	 * model.__get("table").
	 *
	 * @return mixed
	--->
	<cffunction name="__get" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">

		<cfreturn parentGet_(arguments.name)>
	</cffunction>

	<!---
	 * Not in the original. The code of __get(), which Model reaches by name
	 * (see the header).
	--->
	<cffunction name="parentGet_" access="private" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">

		<cfif StructKeyExists(this, arguments.name) AND NOT IsCustomFunction(this[arguments.name])>
			<cfreturn this[arguments.name]>
		</cfif>

		<cfif IsObject(this.db) AND StructKeyExists(this.db, arguments.name) AND NOT IsCustomFunction(this.db[arguments.name])>
			<cfreturn this.db[arguments.name]>
		</cfif>

		<cfreturn "">
	</cffunction>

	<!---
	 * Checks for the existence of properties across this model, and DB connection.
	--->
	<cffunction name="__isset" access="public" returntype="boolean" output="no">
		<cfargument name="name" type="string" required="yes">

		<cfreturn parentIsset_(arguments.name)>
	</cffunction>

	<!---
	 * Not in the original. The code of __isset(), which Model reaches by name
	 * (see the header).
	--->
	<cffunction name="parentIsset_" access="private" returntype="boolean" output="no">
		<cfargument name="name" type="string" required="yes">

		<cfif StructKeyExists(this, arguments.name) AND NOT IsCustomFunction(this[arguments.name])>
			<cfreturn true>
		</cfif>

		<cfif IsObject(this.db) AND StructKeyExists(this.db, arguments.name) AND NOT IsCustomFunction(this.db[arguments.name])>
			<cfreturn NOT isNullMarker_(this.db[arguments.name]) AND NOT (IsSimpleValue(this.db[arguments.name]) AND Len(this.db[arguments.name]) EQ 0)>
		</cfif>

		<cfreturn false>
	</cffunction>

	<!---
	 * Provides direct access to method in the database connection.
	 *
	 * Difference: __call() is a public method that is called by name:
	 * model.__call("query", params), with the arguments as a list.
	 *
	 * @param name   The name of the method
	 * @param params The arguments, as a list
	 *
	 * @return mixed
	--->
	<cffunction name="__call" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="params" type="array" required="no" default="#ArrayNew(1)#">
		<cfset var db = this.db>
		<cfset var call = "">
		<cfset var i = 0>

		<cfif REFind("^[A-Za-z_][A-Za-z0-9_]*$", arguments.name) EQ 0 OR NOT method_exists(db, arguments.name)>
			<cfreturn "">
		</cfif>

		<cfloop from="1" to="#ArrayLen(arguments.params)#" index="i">
			<cfset call = ListAppend(call, "arguments.params[#i#]")>
		</cfloop>

		<cfreturn Evaluate("db.#arguments.name#(#call#)")>
	</cffunction>

	<!---
	 * Sets $allowEmptyInserts.
	 *
	 * @return $this
	--->
	<cffunction name="allowEmptyInserts" access="public" returntype="any" output="no">
		<cfargument name="value" type="boolean" required="no" default="true">

		<cfset this.allowEmptyInserts_ = arguments.value>

		<cfreturn this>
	</cffunction>

	<!---
	 * Converts database data array to return type value.
	 *
	 * @param row        Raw data from database.
	 * @param returnType 'array'|'object'|class-string
	 *
	 * @return array<string, mixed>|object
	--->
	<cffunction name="convertToReturnType" access="private" returntype="any" output="no">
		<cfargument name="row" type="any" required="yes">
		<cfargument name="returnType" type="string" required="yes">

		<cfif Compare(arguments.returnType, "array") EQ 0 OR Compare(arguments.returnType, "object") EQ 0>
			<cfreturn this.converter.fromDataSource(arguments.row)>
		</cfif>

		<cfreturn this.converter.reconstruct(arguments.returnType, arguments.row)>
	</cffunction>

	<!---
	 * The helpers below have no original: they stand in for the features
	 * of the language that CFML 6.1 does not have.
	--->

	<!--- the name of the class of the model, for the messages (static::class) --->
	<cffunction name="className_" access="private" returntype="string" output="no">

		<cfreturn GetMetaData(this).name>
	</cffunction>

	<!--- null in a map, or the id or the row that was left out --->
	<cffunction name="nullValue_" access="private" returntype="any" output="no">

		<cfreturn new_("ColdIgniter\Database\NullValue")>
	</cffunction>

	<cffunction name="isNullMarker_" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfreturn instanceof_(arguments.value, "NullValue")>
	</cffunction>

	<!--- a null becomes the marker, to be kept in a map --->
	<cffunction name="markNull_" access="private" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfif IsSimpleValue(arguments.value) AND Len(arguments.value) EQ 0>
			<cfreturn nullValue_()>
		</cfif>

		<cfreturn arguments.value>
	</cffunction>

	<!--- the marker becomes an empty string, the null of an argument --->
	<cffunction name="unmarkNull_" access="private" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfif isNullMarker_(arguments.value)>
			<cfreturn "">
		</cfif>

		<cfreturn arguments.value>
	</cffunction>

	<!--- a map, not a component --->
	<cffunction name="isMap_" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfreturn IsStruct(arguments.value) AND NOT IsObject(arguments.value)>
	</cffunction>

	<!--- a list or a map, never a component --->
	<cffunction name="isArr_" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfif IsObject(arguments.value)>
			<cfreturn false>
		</cfif>

		<cfreturn IsArray(arguments.value) OR IsStruct(arguments.value)>
	</cffunction>

	<!--- $value === [] (also an empty string, as the null of a row or a list) --->
	<cffunction name="isEmpty_" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfif IsSimpleValue(arguments.value)>
			<cfreturn Len(arguments.value) EQ 0>
		</cfif>

		<cfif IsObject(arguments.value)>
			<cfreturn isNullMarker_(arguments.value)>
		</cfif>

		<cfif IsArray(arguments.value)>
			<cfreturn ArrayLen(arguments.value) EQ 0>
		</cfif>

		<cfif IsStruct(arguments.value)>
			<cfreturn StructCount(arguments.value) EQ 0>
		</cfif>

		<cfreturn false>
	</cffunction>

	<!--- isset($map[$key]): the key is there and its value is not null --->
	<cffunction name="isSet_" access="private" returntype="boolean" output="no">
		<cfargument name="map" type="any" required="yes">
		<cfargument name="key" type="any" required="yes">

		<cfif NOT isMap_(arguments.map) OR NOT array_key_exists(arguments.key, arguments.map)>
			<cfreturn false>
		</cfif>

		<cfreturn NOT isNullMarker_(arguments.map[arguments.key])>
	</cffunction>

	<!--- the truth of a value: an empty string, false and 0 are false, an object is true --->
	<cffunction name="truthy_" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfif IsSimpleValue(arguments.value)>
			<cfif Len(arguments.value) EQ 0>
				<cfreturn false>
			</cfif>

			<cfif IsBoolean(arguments.value)>
				<cfreturn arguments.value>
			</cfif>

			<cfreturn true>
		</cfif>

		<cfif IsObject(arguments.value)>
			<cfreturn true>
		</cfif>

		<cfreturn NOT isEmpty_(arguments.value)>
	</cffunction>

	<!--- the event data of a before event asks for the data to be returned --->
	<cffunction name="returnsData_" access="private" returntype="boolean" output="no">
		<cfargument name="eventData" type="any" required="yes">

		<cfif NOT isSet_(arguments.eventData, "returnData")>
			<cfreturn false>
		</cfif>

		<!--- a boolean of an expression reads YES, so the text is not compared; a number is not a boolean --->
		<cfreturn IsSimpleValue(arguments.eventData["returnData"]) AND IsBoolean(arguments.eventData["returnData"]) AND NOT IsNumeric(arguments.eventData["returnData"]) AND arguments.eventData["returnData"]>
	</cffunction>

	<!--- (array) $value: a map is a map, an object is read, a null is an empty map --->
	<cffunction name="toArrayCast_" access="private" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfif isNullMarker_(arguments.value) OR (IsSimpleValue(arguments.value) AND Len(arguments.value) EQ 0)>
			<cfreturn array_()>
		</cfif>

		<cfif IsObject(arguments.value)>
			<cfreturn objectToRawArray(arguments.value, false, false)>
		</cfif>

		<cfif NOT IsStruct(arguments.value)>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="A row has to be a map of field names and values.">
		</cfif>

		<cfreturn arguments.value>
	</cffunction>

	<!--- a copy of a map, as an array is copied in the original --->
	<cffunction name="copyMap_" access="private" returntype="any" output="no">
		<cfargument name="map" type="any" required="yes">
		<cfset var copy = array_()>
		<cfset var keys = "">
		<cfset var i = 0>

		<cfif NOT IsStruct(arguments.map) OR IsObject(arguments.map)>
			<cfreturn copy>
		</cfif>

		<cfset keys = array_keys(arguments.map)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset copy[keys[i]] = arguments.map[keys[i]]>
		</cfloop>

		<cfreturn copy>
	</cffunction>

	<!--- $a + $b: the keys of the first map, then the keys of the second that it lacks --->
	<cffunction name="unionMap_" access="private" returntype="any" output="no">
		<cfargument name="a" type="any" required="yes">
		<cfargument name="b" type="any" required="yes">
		<cfset var result = copyMap_(arguments.a)>
		<cfset var keys = "">
		<cfset var i = 0>

		<cfif NOT isMap_(arguments.b)>
			<cfreturn result>
		</cfif>

		<cfset keys = array_keys(arguments.b)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfif NOT array_key_exists(keys[i], result)>
				<cfset result[keys[i]] = arguments.b[keys[i]]>
			</cfif>
		</cfloop>

		<cfreturn result>
	</cffunction>

</cfcomponent>
