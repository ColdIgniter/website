<!---
 * Entity encapsulation, for use with ColdIgniter\Model
 *
 * Difference: there is no magic method, so the properties of an entity are
 * read and written with the methods that the original calls for them:
 * entity.__get("name"), entity.__set("name", value), entity.__isset("name")
 * and entity.__unset("name"), as the Model does (see there). There is no
 * $entity->name, and so no property of the entity that could hide an
 * attribute.
 *
 * Difference: the getters and setters of the original ("getFoo()", "_getFoo()",
 * "setFoo()" and "_setFoo()", found with method_exists(), also when they are
 * protected or private) have to be public methods here, as method_exists()
 * sees only the public methods of an object. A setter is called as a
 * function, so it must not have the return type "void". __set() and
 * __unset() return the entity (the original returns nothing).
 *
 * Difference: an array of the original is a map (see array_()), or a list
 * (an ArrayNew(1)); a null is an empty string, so an attribute that holds an
 * empty string is a null as well. The properties datamap, dates, casts and
 * castHandlers are set by a child as it sets the properties of a model: a
 * map (created with CreateObject("java", "java.util.LinkedHashMap").init(),
 * or a struct) and a list. The property dataCaster is dataCaster_, as there
 * is a method of that name.
 *
 * Difference: the casts are the ones of the original, but the DataCaster
 * that does the work is created when it is needed, so a child can set its
 * casts after the constructor ran (as it can in the original, where the
 * property is set by the class body). The enum cast is not ported yet (there
 * are no enums).
 *
 * Difference: the type of an object is not checked (there is no type), and
 * the types of the scalars are lost (see BaseModel): the change of an
 * attribute from the number 1 to the text "1" is not a change.
--->
<cfcomponent output="no" hint="Entity encapsulation, for use with ColdIgniter\Model">

	<!---
	 * Maps names used in sets and gets against unique
	 * names within the class, allowing independence from
	 * database column names.
	 *
	 * Example:
	 *  datamap["class_property_name"] = "db_column_name"
	 *
	 * @var array<string, string>
	--->
	<cfset this.datamap = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * The date fields.
	 *
	 * @var list<string>
	--->
	<cfset this.dates = ListToArray("created_at,updated_at,deleted_at")>

	<!---
	 * Array of field names and the type of value to cast them as when
	 * they are accessed.
	 *
	 * @var array<string, string>
	--->
	<cfset this.casts = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Custom convert handlers.
	 *
	 * @var array<string, string>
	--->
	<cfset this.castHandlers = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Holds the current values of all class vars.
	 *
	 * @var array<string, mixed>
	--->
	<cfset this.attributes = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Holds original copies of all class vars so we can determine
	 * what's actually been changed and not accidentally write
	 * nulls where we shouldn't.
	 *
	 * @var array<string, mixed>
	--->
	<cfset this.original = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * The data caster (the property dataCaster of the original).
	--->
	<cfset this.dataCaster_ = "">

	<!---
	 * Holds info whenever properties have to be casted.
	--->
	<cfset this._cast = true>

	<!---
	 * Indicates whether all attributes are scalars (for optimization).
	--->
	<cfset this._onlyScalars = true>

	<!---
	 * Allows filling in Entity parameters during construction.
	 *
	 * @param data array<string, mixed>
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="data" type="any" required="no" default="">

		<cfset this.dataCaster_ = dataCaster()>

		<cfset syncOriginal()>

		<cfset fill(arguments.data)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Takes an array of key/value pairs and sets them as class
	 * properties, using any `setCamelCasedProperty()` methods
	 * that may or may not exist.
	 *
	 * @param data array<string, mixed>
	 *
	 * @return $this
	--->
	<cffunction name="fill" access="public" returntype="any" output="no">
		<cfargument name="data" type="any" required="no" default="">
		<cfset var keys = "">
		<cfset var i = 0>

		<cfif NOT IsStruct(arguments.data) OR IsObject(arguments.data)>
			<cfreturn this>
		</cfif>

		<cfset keys = array_keys(arguments.data)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset __set(keys[i], arguments.data[keys[i]])>
		</cfloop>

		<cfreturn this>
	</cffunction>

	<!---
	 * General method that will return all public and protected values
	 * of this entity as an array. All values are accessed through the
	 * __get() method so will have any casts, etc applied to them.
	 *
	 * @param onlyChanged If true, only return values that have changed since object creation.
	 * @param cast        If true, properties will be cast.
	 * @param recursive   If true, inner entities will be cast as array as well.
	 *
	 * @return array<string, mixed>
	--->
	<cffunction name="toArray" access="public" returntype="any" output="no">
		<cfargument name="onlyChanged" type="boolean" required="no" default="false">
		<cfargument name="cast" type="boolean" required="no" default="true">
		<cfargument name="recursive" type="boolean" required="no" default="false">
		<cfset var originalCast = this._cast>
		<cfset var attributeKeys = array_keys(this.attributes)>
		<cfset var mappedKeys = array_keys(this.datamap)>
		<cfset var columns = ArrayNew(1)>
		<cfset var keys = ArrayNew(1)>
		<cfset var return_ = array_()>
		<cfset var key = "">
		<cfset var i = 0>
		<cfset var j = 0>
		<cfset var mapped = false>

		<cfset this._cast = arguments.cast>

		<!--- the datamap: the columns that have a property name are replaced by it --->
		<cfloop from="1" to="#ArrayLen(mappedKeys)#" index="j">
			<cfset ArrayAppend(columns, this.datamap[mappedKeys[j]])>
		</cfloop>

		<cfloop from="1" to="#ArrayLen(attributeKeys)#" index="i">
			<cfif Compare(Left(attributeKeys[i], 1), "_") NEQ 0 AND NOT in_array(attributeKeys[i], columns)>
				<cfset ArrayAppend(keys, attributeKeys[i])>
			</cfif>
		</cfloop>

		<cfloop from="1" to="#ArrayLen(mappedKeys)#" index="j">
			<cfset ArrayAppend(keys, mappedKeys[j])>
		</cfloop>

		<cfset keys = array_unique(keys)>

		<!--- loop over the properties, to let the getters do their thing --->
		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset key = keys[i]>

			<cfif NOT (arguments.onlyChanged AND NOT hasChanged(key))>
				<cfset return_[key] = __get(key)>

				<cfif arguments.recursive AND IsObject(return_[key])>
					<cfif instanceof_(return_[key], "Entity")>
						<cfset return_[key] = return_[key].toArray(arguments.onlyChanged, arguments.cast, arguments.recursive)>
					<cfelseif method_exists(return_[key], "toArray")>
						<cfset return_[key] = return_[key].toArray()>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>

		<cfset this._cast = originalCast>

		<cfreturn return_>
	</cffunction>

	<!---
	 * Returns the raw values of the current attributes.
	 *
	 * Difference: the result is always a copy of the attributes, as an array
	 * is a value in the original. In the recursive mode, a list of entities
	 * with a change gives a map with the position of the changed entities as
	 * keys, as a list has no gaps here.
	 *
	 * @param onlyChanged If true, only return values that have changed since object creation.
	 * @param recursive   If true, inner entities will be cast as array as well.
	 *
	 * @return array<string, mixed>
	--->
	<cffunction name="toRawArray" access="public" returntype="any" output="no">
		<cfargument name="onlyChanged" type="boolean" required="no" default="false">
		<cfargument name="recursive" type="boolean" required="no" default="false">
		<cfset var keys = array_keys(this.attributes)>
		<cfset var return_ = array_()>
		<cfset var key = "">
		<cfset var value = "">
		<cfset var i = 0>
		<cfset var idx = 0>
		<cfset var item = "">
		<cfset var originalValue = "">
		<cfset var originalArray = "">
		<cfset var converted = "">
		<cfset var currentNormalized = "">
		<cfset var originalNormalized = "">
		<cfset var include = false>

		<!--- when returning everything --->
		<cfif NOT arguments.onlyChanged>
			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset return_[keys[i]] = convert_(this.attributes[keys[i]], arguments.recursive)>
			</cfloop>

			<cfreturn return_>
		</cfif>

		<!--- when filtering by changed values only --->
		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset key = keys[i]>
			<cfset value = this.attributes[key]>

			<!--- special handling for arrays of entities in recursive mode: skip hasChanged() and do the comparison of each entity --->
			<cfif arguments.recursive AND IsArray(value) AND containsOnlyEntities(value)>
				<cfset converted = array_()>

				<cfif array_key_exists(key, this.original) AND IsSimpleValue(this.original[key]) AND NOT is_null(this.original[key])>
					<!--- decode the original array structure for the comparison of each entity --->
					<cfset originalArray = json_decode(this.original[key])>

					<cfloop from="1" to="#ArrayLen(value)#" index="idx">
						<cfset item = value[idx]>
						<cfset currentNormalized = json_encode(textify_(normalizeValue(item)))>
						<cfset include = true>

						<cfif IsArray(originalArray) AND idx LTE ArrayLen(originalArray)>
							<cfset originalNormalized = json_encode(textify_(originalArray[idx]))>
							<cfset include = Compare(currentNormalized, originalNormalized) NEQ 0>
						</cfif>

						<!--- only include if changed, new, or can't determine --->
						<cfif include>
							<cfset converted[idx - 1 & ""] = item.toRawArray(false, true)>
						</cfif>
					</cfloop>

					<!--- only include this property if at least one entity changed --->
					<cfif NOT StructIsEmpty(converted)>
						<cfset return_[key] = converted>
					</cfif>
				<cfelse>
					<!--- no original or invalid format, export all entities --->
					<cfset converted = ArrayNew(1)>

					<cfloop from="1" to="#ArrayLen(value)#" index="idx">
						<cfset ArrayAppend(converted, value[idx].toRawArray(false, true))>
					</cfloop>

					<cfset return_[key] = converted>
				</cfif>
			<!--- for all other cases, use hasChanged() --->
			<cfelseif hasChanged(key)>
				<cfset return_[key] = convert_(value, arguments.recursive)>
			</cfif>
		</cfloop>

		<cfreturn return_>
	</cffunction>

	<!---
	 * Ensures our "original" values match the current values.
	 *
	 * Objects and arrays are normalized and JSON-encoded for reliable change detection,
	 * while scalars are stored as-is for performance.
	 *
	 * Difference: json_encode() has no flags here, see there.
	 *
	 * @return $this
	--->
	<cffunction name="syncOriginal" access="public" returntype="any" output="no">
		<cfset var keys = array_keys(this.attributes)>
		<cfset var value = "">
		<cfset var i = 0>

		<cfset this.original = array_()>
		<cfset this._onlyScalars = true>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset value = this.attributes[keys[i]]>

			<cfif NOT IsSimpleValue(value)>
				<cfset this.original[keys[i]] = json_encode(normalizeValue(value))>
				<cfset this._onlyScalars = false>
			<cfelse>
				<cfset this.original[keys[i]] = value>
			</cfif>
		</cfloop>

		<cfreturn this>
	</cffunction>

	<!---
	 * Checks a property to see if it has changed since the entity
	 * was created. Or, without a parameter, checks if any
	 * properties have changed.
	 *
	 * Difference: the key is an empty string for "no parameter".
	--->
	<cffunction name="hasChanged" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="string" required="no" default="">
		<cfset var keys = "">
		<cfset var i = 0>
		<cfset var dbColumn = "">
		<cfset var originalValue = "">
		<cfset var currentValue = "">
		<cfset var inOriginal = false>
		<cfset var inAttributes = false>

		<!--- if no parameter was given then check all attributes --->
		<cfif Len(arguments.key) EQ 0>
			<cfif this._onlyScalars>
				<cfreturn NOT identical_(this.original, this.attributes)>
			</cfif>

			<cfset keys = array_keys(this.attributes)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfif hasChanged(keys[i])>
					<cfreturn true>
				</cfif>
			</cfloop>

			<cfreturn false>
		</cfif>

		<cfset dbColumn = mapProperty(arguments.key)>
		<cfset inOriginal = array_key_exists(dbColumn, this.original)>
		<cfset inAttributes = array_key_exists(dbColumn, this.attributes)>

		<!--- key doesn't exist in either --->
		<cfif NOT inOriginal AND NOT inAttributes>
			<cfreturn false>
		</cfif>

		<!--- it's a new element, or it was removed --->
		<cfif inOriginal NEQ inAttributes>
			<cfreturn true>
		</cfif>

		<cfset originalValue = this.original[dbColumn]>
		<cfset currentValue = this.attributes[dbColumn]>

		<!--- if original is a string, it was JSON-encoded (object or array) --->
		<cfif IsSimpleValue(originalValue) AND NOT IsSimpleValue(currentValue)>
			<cfreturn Compare(originalValue, json_encode(normalizeValue(currentValue))) NEQ 0>
		</cfif>

		<!--- for scalars, use direct comparison --->
		<cfreturn NOT identical_(originalValue, currentValue)>
	</cffunction>

	<!---
	 * Checks if an array contains only Entity instances.
	 * This allows optimization for per-entity change tracking.
	 *
	 * @param data array<array-key, mixed>
	--->
	<cffunction name="containsOnlyEntities" access="private" returntype="boolean" output="no">
		<cfargument name="data" type="array" required="yes">
		<cfset var i = 0>

		<cfif ArrayLen(arguments.data) EQ 0>
			<cfreturn false>
		</cfif>

		<cfloop from="1" to="#ArrayLen(arguments.data)#" index="i">
			<cfif NOT instanceof_(arguments.data[i], "Entity")>
				<cfreturn false>
			</cfif>
		</cfloop>

		<cfreturn true>
	</cffunction>

	<!---
	 * Recursively normalize a value for comparison.
	 * Converts objects and arrays to a JSON-encodable format.
	 *
	 * Difference: there is no enum and no Traversable. A Time (the nearest
	 * to a DateTimeInterface) gives its class and its time in the format
	 * DATE_RFC3339_EXTENDED. There is no get_object_vars(), so the data of
	 * an object that has no jsonSerialize(), toArray() or __toString() is an
	 * empty map.
	--->
	<cffunction name="normalizeValue" access="private" returntype="any" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfset var normalized = "">
		<cfset var keys = "">
		<cfset var objectData = "">
		<cfset var class_ = "">
		<cfset var result = "">
		<cfset var i = 0>

		<cfif IsArray(arguments.data)>
			<cfset normalized = ArrayNew(1)>

			<cfloop from="1" to="#ArrayLen(arguments.data)#" index="i">
				<cfset ArrayAppend(normalized, normalizeValue(arguments.data[i]))>
			</cfloop>

			<cfreturn normalized>
		</cfif>

		<cfif IsObject(arguments.data)>
			<cfset class_ = GetMetaData(arguments.data).name>
			<cfset result = array_()>

			<!--- check for Entity instance (use raw values, recursive) --->
			<cfif instanceof_(arguments.data, "Entity")>
				<cfset objectData = arguments.data.toRawArray(false, true)>
			<cfelseif method_exists(arguments.data, "jsonSerialize")>
				<cfset objectData = arguments.data.jsonSerialize()>
			<cfelseif method_exists(arguments.data, "toArray")>
				<cfset objectData = arguments.data.toArray()>
			<cfelseif instanceof_(arguments.data, "Time")>
				<cfset result["__class"] = class_>
				<cfset result["__datetime"] = arguments.data.format("Y-m-d\TH:i:s.vP")>

				<cfreturn result>
			<cfelse>
				<cfset objectData = array_()>

				<!--- fallback for value objects with __toString() when properties are not accessible --->
				<cfif method_exists(arguments.data, "__toString")>
					<cfset result["__class"] = class_>
					<cfset result["__string"] = arguments.data.__toString()>

					<cfreturn result>
				</cfif>
			</cfif>

			<cfset result["__class"] = class_>
			<cfset result["__data"] = normalizeValue(objectData)>

			<cfreturn result>
		</cfif>

		<cfif IsStruct(arguments.data)>
			<cfset normalized = array_()>
			<cfset keys = array_keys(arguments.data)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset normalized[keys[i]] = normalizeValue(arguments.data[keys[i]])>
			</cfloop>

			<cfreturn normalized>
		</cfif>

		<!--- return scalars and null as-is --->
		<cfreturn arguments.data>
	</cffunction>

	<!---
	 * Set raw data array without any mutations.
	 *
	 * Difference: the map is kept, not copied, as the rows that come from the
	 * database are not used again.
	 *
	 * @param data array<string, mixed>
	 *
	 * @return $this
	--->
	<cffunction name="injectRawData" access="public" returntype="any" output="no">
		<cfargument name="data" type="any" required="yes">

		<cfset this.attributes = arguments.data>

		<cfset syncOriginal()>

		<cfreturn this>
	</cffunction>

	<!---
	 * Checks the datamap to see if this property name is being mapped,
	 * and returns the DB column name, if any, or the original property name.
	 *
	 * @return string Database column name.
	--->
	<cffunction name="mapProperty" access="private" returntype="string" output="no">
		<cfargument name="key" type="string" required="yes">

		<cfif StructIsEmpty(this.datamap)>
			<cfreturn arguments.key>
		</cfif>

		<cfif array_key_exists(arguments.key, this.datamap) AND Compare(this.datamap[arguments.key], "") NEQ 0>
			<cfreturn this.datamap[arguments.key]>
		</cfif>

		<cfreturn arguments.key>
	</cffunction>

	<!---
	 * Converts the given string|timestamp|DateTimeInterface instance
	 * into the "ColdIgniter\I18n\Time" object.
	 *
	 * Difference: this calls the cast of the same name (DatetimeCast).
	 *
	 * @param value DateTimeInterface|float|int|string
	 *
	 * @return Time
	--->
	<cffunction name="mutateDate" access="private" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfreturn static_("ColdIgniter\Entity\Cast\DatetimeCast").get(arguments.value)>
	</cffunction>

	<!---
	 * Provides the ability to cast an item as a specific data type.
	 * Add ? at the beginning of the type (i.e. ?string) to get `null`
	 * instead of casting $value when $value is null.
	 *
	 * @param value     Attribute value
	 * @param attribute Attribute name
	 * @param method    Allowed to "get" and "set"
	 *
	 * @return mixed
	 *
	 * @throws CastException
	--->
	<cffunction name="castAs" access="private" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="attribute" type="string" required="yes">
		<cfargument name="method" type="string" required="no" default="get">
		<cfset var caster = dataCaster()>

		<cfif IsObject(caster)>
			<cfreturn caster.setTypes(this.casts).castAs(arguments.value, arguments.attribute, arguments.method)>
		</cfif>

		<cfreturn arguments.value>
	</cffunction>

	<!---
	 * Returns a DataCaster instance when casts are defined.
	 * If no casts are configured, no DataCaster is created and an empty
	 * string (null) is returned.
	--->
	<cffunction name="dataCaster" access="private" returntype="any" output="no">
		<cfset var handlers = "">
		<cfset var keys = "">
		<cfset var i = 0>

		<cfif StructIsEmpty(this.casts)>
			<cfset this.dataCaster_ = "">

			<cfreturn "">
		</cfif>

		<cfif NOT IsObject(this.dataCaster_)>
			<!--- the default handlers, with the ones of the entity replaced by the custom ones --->
			<cfset handlers = array_(
				"array", "ColdIgniter\Entity\Cast\ArrayCast",
				"bool", "ColdIgniter\Entity\Cast\BooleanCast",
				"boolean", "ColdIgniter\Entity\Cast\BooleanCast",
				"csv", "ColdIgniter\Entity\Cast\CSVCast",
				"datetime", "ColdIgniter\Entity\Cast\DatetimeCast",
				"double", "ColdIgniter\Entity\Cast\FloatCast",
				"float", "ColdIgniter\Entity\Cast\FloatCast",
				"int", "ColdIgniter\Entity\Cast\IntegerCast",
				"integer", "ColdIgniter\Entity\Cast\IntegerCast",
				"int-bool", "ColdIgniter\Entity\Cast\IntBoolCast",
				"json", "ColdIgniter\Entity\Cast\JsonCast",
				"object", "ColdIgniter\Entity\Cast\ObjectCast",
				"string", "ColdIgniter\Entity\Cast\StringCast",
				"timestamp", "ColdIgniter\Entity\Cast\TimestampCast",
				"uri", "ColdIgniter\Entity\Cast\URICast"
			)>
			<cfset keys = array_keys(this.castHandlers)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset handlers[keys[i]] = this.castHandlers[keys[i]]>
			</cfloop>

			<cfset this.dataCaster_ = new_("ColdIgniter\DataCaster\DataCaster", handlers, "", "", false)>
		</cfif>

		<cfreturn this.dataCaster_>
	</cffunction>

	<!---
	 * Support for json_encode().
	 *
	 * @return array<string, mixed>
	--->
	<cffunction name="jsonSerialize" access="public" returntype="any" output="no">

		<cfreturn toArray()>
	</cffunction>

	<!---
	 * Change the value of the private $_cast property.
	 *
	 * Difference: the argument is an empty string (null) to read.
	 *
	 * @return bool|Entity
	--->
	<cffunction name="cast" access="public" returntype="any" output="no">
		<cfargument name="cast" type="any" required="no" default="">

		<cfif is_null(arguments.cast)>
			<cfreturn JavaCast("boolean", this._cast)>
		</cfif>

		<cfset this._cast = arguments.cast>

		<cfreturn this>
	</cffunction>

	<!---
	 * Method to allow the properties to be easily set, either through a
	 * direct access or a `setCamelCasedProperty()` method.
	 *
	 * Examples:
	 *  entity.__set("my_property", p)
	 *  entity.setMyProperty(p)
	 *
	 * @param value mixed
	 *
	 * @return void
	--->
	<cffunction name="__set" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="value" type="any" required="no" default="">
		<cfset var dbColumn = mapProperty(arguments.key)>
		<cfset var method = "">

		<!--- check if the field should be mutated into a date --->
		<cfif in_array(dbColumn, this.dates)>
			<cfset arguments.value = mutateDate(arguments.value)>
		</cfif>

		<cfset arguments.value = castAs(arguments.value, dbColumn, "set")>

		<!--- if a setter method exists for this key, use that method to insert this value. should be outside the null check, so maybe wants to do something with a null value automatically --->
		<cfset method = "set" & studly_(dbColumn)>

		<!--- if a "_set" + key method exists, it is a setter --->
		<cfif method_exists(this, "_" & method)>
			<cfset Evaluate("this._#method#(arguments.value)")>

			<cfreturn this>
		</cfif>

		<!--- if a "set" + key method exists, it is also a setter --->
		<cfif method_exists(this, method)>
			<cfset Evaluate("this.#method#(arguments.value)")>

			<cfreturn this>
		</cfif>

		<!--- otherwise, just the value. This allows for creation of new attributes that are undefined, though they cannot be saved. Useful for grabbing values through joins, assigning relationships, etc. --->
		<cfset this.attributes[dbColumn] = arguments.value>

		<cfreturn this>
	</cffunction>

	<!---
	 * Method to allow retrieval of the attributes either by their name, or
	 * through a `getCamelCasedProperty()` method.
	 *
	 * Examples:
	 *  p = entity.__get("my_property")
	 *  p = entity.getMyProperty()
	 *
	 * @return mixed
	--->
	<cffunction name="__get" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfset var dbColumn = mapProperty(arguments.key)>
		<cfset var result = "">
		<cfset var method = "get" & studly_(dbColumn)>

		<!--- if a getter method exists for this key, use that method to insert this value --->
		<cfif method_exists(this, "_" & method)>
			<!--- if a "_get" + key method exists, it is a getter --->
			<cfset result = Evaluate("this._#method#()")>
		<cfelseif method_exists(this, method)>
			<!--- if a "get" + key method exists, it is also a getter --->
			<cfset result = Evaluate("this.#method#()")>
		<!--- otherwise return the attribute if it exists --->
		<cfelseif array_key_exists(dbColumn, this.attributes)>
			<cfset result = this.attributes[dbColumn]>
		</cfif>

		<!--- do we need to mutate this into a date? --->
		<cfif in_array(dbColumn, this.dates)>
			<cfset result = mutateDate(result)>
		<!--- or cast it as something? --->
		<cfelseif this._cast>
			<cfset result = castAs(result, dbColumn)>
		</cfif>

		<cfreturn result>
	</cffunction>

	<!---
	 * Returns true if an attribute exists named $key, or a getter method
	 * exists named like for __get().
	 *
	 * Difference: an attribute that is an empty string (a null) is set, as
	 * an empty string is a value as well.
	--->
	<cffunction name="__isset" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfset var dbColumn = "">
		<cfset var method = "">

		<cfif isMappedDbColumn(arguments.key)>
			<cfreturn false>
		</cfif>

		<cfset dbColumn = mapProperty(arguments.key)>
		<cfset method = "get" & studly_(dbColumn)>

		<cfif method_exists(this, method)>
			<cfreturn true>
		</cfif>

		<cfreturn array_key_exists(dbColumn, this.attributes)>
	</cffunction>

	<!---
	 * Unsets an attribute property.
	--->
	<cffunction name="__unset" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfset var dbColumn = "">

		<cfif isMappedDbColumn(arguments.key)>
			<cfreturn this>
		</cfif>

		<cfset dbColumn = mapProperty(arguments.key)>

		<cfset StructDelete(this.attributes, dbColumn)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Whether this key is mapped db column name?
	--->
	<cffunction name="isMappedDbColumn" access="private" returntype="boolean" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfset var dbColumn = mapProperty(arguments.key)>

		<!--- the key is a property name which has mapped db column name --->
		<cfif Compare(arguments.key, dbColumn) NEQ 0>
			<cfreturn false>
		</cfif>

		<cfreturn hasMappedProperty(arguments.key)>
	</cffunction>

	<!---
	 * Whether this key has mapped property?
	--->
	<cffunction name="hasMappedProperty" access="private" returntype="boolean" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfset var keys = array_keys(this.datamap)>
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfif Compare(this.datamap[keys[i]], arguments.key) EQ 0>
				<cfreturn true>
			</cfif>
		</cfloop>

		<cfreturn false>
	</cffunction>

	<!---
	 * The helpers below have no original: they stand in for the features
	 * of the language that CFML 6.1 does not have.
	--->

	<!---
	 * Converts a column name to the CamelCase of a getter or a setter:
	 * str_replace(' ', '', ucwords(str_replace(['-', '_'], ' ', $dbColumn))).
	--->
	<cffunction name="studly_" access="private" returntype="string" output="no">
		<cfargument name="name" type="string" required="yes">

		<cfreturn Replace(ucwords(Replace(Replace(arguments.name, "-", " ", "all"), "_", " ", "all")), " ", "", "all")>
	</cffunction>

	<!---
	 * The function $convert of toRawArray(): the raw values of the entities
	 * inside a value, in the recursive mode.
	--->
	<cffunction name="convert_" access="private" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="recursive" type="boolean" required="yes">
		<cfset var result = "">
		<cfset var keys = "">
		<cfset var i = 0>

		<cfif NOT arguments.recursive>
			<cfreturn arguments.value>
		</cfif>

		<cfif IsObject(arguments.value)>
			<cfif instanceof_(arguments.value, "Entity")>
				<!--- always output full array for nested entities --->
				<cfreturn arguments.value.toRawArray(false, true)>
			</cfif>

			<cfif method_exists(arguments.value, "toRawArray")>
				<cfreturn arguments.value.toRawArray()>
			</cfif>

			<cfreturn arguments.value>
		</cfif>

		<cfif IsArray(arguments.value)>
			<cfset result = ArrayNew(1)>

			<cfloop from="1" to="#ArrayLen(arguments.value)#" index="i">
				<cfset ArrayAppend(result, convert_(arguments.value[i], true))>
			</cfloop>

			<cfreturn result>
		</cfif>

		<cfif IsStruct(arguments.value)>
			<cfset result = array_()>
			<cfset keys = array_keys(arguments.value)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset result[keys[i]] = convert_(arguments.value[keys[i]], true)>
			</cfloop>

			<cfreturn result>
		</cfif>

		<cfreturn arguments.value>
	</cffunction>

	<!---
	 * Makes every scalar of a list or a map a text, as json_decode() gives
	 * them, so a value and the same value read back from JSON are encoded
	 * the same way.
	--->
	<cffunction name="textify_" access="private" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfset var result = "">
		<cfset var keys = "">
		<cfset var i = 0>

		<cfif IsArray(arguments.value)>
			<cfset result = ArrayNew(1)>

			<cfloop from="1" to="#ArrayLen(arguments.value)#" index="i">
				<cfset ArrayAppend(result, textify_(arguments.value[i]))>
			</cfloop>

			<cfreturn result>
		</cfif>

		<cfif IsStruct(arguments.value) AND NOT IsObject(arguments.value)>
			<cfset result = array_()>
			<cfset keys = array_keys(arguments.value)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset result[keys[i]] = textify_(arguments.value[keys[i]])>
			</cfloop>

			<cfreturn result>
		</cfif>

		<cfif is_bool(arguments.value)>
			<cfif arguments.value>
				<cfreturn "true">
			</cfif>

			<cfreturn "false">
		</cfif>

		<cfif IsSimpleValue(arguments.value)>
			<cfreturn JavaCast("string", arguments.value)>
		</cfif>

		<cfreturn arguments.value>
	</cffunction>
</cfcomponent>
