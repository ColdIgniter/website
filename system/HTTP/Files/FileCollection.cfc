<!---
 * Class FileCollection
 *
 * A collection of uploaded files, built from the files array of the
 * Superglobals service (the $_FILES of the original): one entry for each
 * field, with the keys name, full_path, type, tmp_name, error and size, and a
 * nested entry for a field that holds a list, such as docs[]. The collection
 * is built the first time it is asked for a file, so a request that never
 * asks pays nothing, and the files array itself is only read from the
 * request then (see Superglobals.getFilesArray()).
 *
 * Difference: the names of a multipart/form-data body come from the form
 * scope in upper case, as the case of the name cannot be read there, so a
 * name is found by its exact spelling first and then without regard to case.
 * This holds for every part of a dotted name. Where the original tells
 * a.b from A.B, this does not, if both are sent.
 *
 * Difference: an array of the original is a map (see array_()), and a
 * component is not a map (isMap()). The method names that the original
 * shares with a built-in function are unchanged.
--->
<cfcomponent output="no" hint="A collection of uploaded files">

	<!---
	 * An array of UploadedFile instances for any files uploaded as part of this request.
	 * Populated the first time either files(), file(), or hasFile() is called.
	 *
	 * @var array<string, array<UploadedFile>|UploadedFile>|null
	--->
	<cfset this.files = "">

	<!---
	 * Returns an array of uploaded files that were sent with the request.
	 *
	 * @return array<string, array<int, UploadedFile>|UploadedFile>
	--->
	<cffunction name="all" access="public" returntype="any" output="no">
		<cfset populateFiles()>

		<cfreturn this.files>
	</cffunction>

	<!---
	 * Attempts to get a single file from the collection of uploaded files.
	 *
	 * @return UploadedFile|null
	--->
	<cffunction name="getFile" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfset var uploadedFile = "">
		<cfset var key = "">

		<cfset populateFiles()>

		<cfif hasFile(arguments.name)>
			<cfif Find(".", arguments.name) GT 0>
				<cfset uploadedFile = getValueDotNotationSyntax(explode(".", arguments.name), this.files)>

				<cfif instanceof_(uploadedFile, "UploadedFile")>
					<cfreturn uploadedFile>
				</cfif>

				<cfreturn "">
			</cfif>

			<cfset key = findKey(this.files, arguments.name)>

			<cfif key NEQ "">
				<cfset uploadedFile = this.files[key]>

				<cfif instanceof_(uploadedFile, "UploadedFile")>
					<cfreturn uploadedFile>
				</cfif>

				<cfreturn "">
			</cfif>
		</cfif>

		<cfreturn "">
	</cffunction>

	<!---
	 * Verify if a file exist in the collection of uploaded files and retrieve it.
	 *
	 * @return array<int, UploadedFile>|null
	--->
	<cffunction name="getFileMultiple" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfset var uploadedFile = "">
		<cfset var key = "">

		<cfset populateFiles()>

		<cfif hasFile(arguments.name)>
			<cfif Find(".", arguments.name) GT 0>
				<cfset uploadedFile = getValueDotNotationSyntax(explode(".", arguments.name), this.files)>

				<cfif isMap(uploadedFile) AND instanceof_(firstValue(uploadedFile), "UploadedFile")>
					<cfreturn uploadedFile>
				</cfif>

				<cfreturn "">
			</cfif>

			<cfset key = findKey(this.files, arguments.name)>

			<cfif key NEQ "">
				<cfset uploadedFile = this.files[key]>

				<cfif isMap(uploadedFile) AND instanceof_(firstValue(uploadedFile), "UploadedFile")>
					<cfreturn uploadedFile>
				</cfif>

				<cfreturn "">
			</cfif>
		</cfif>

		<cfreturn "">
	</cffunction>

	<!---
	 * Checks whether an uploaded file with the name given by the field name exists in the request.
	 *
	 * @param fileID The name of the uploaded file (the field name), or a dotted name for a nested field
	--->
	<cffunction name="hasFile" access="public" returntype="boolean" output="no">
		<cfargument name="fileID" type="string" required="yes">
		<cfset var segments = "">
		<cfset var el = "">
		<cfset var key = "">
		<cfset var i = 0>

		<cfset populateFiles()>

		<cfif Find(".", arguments.fileID) GT 0>
			<cfset segments = explode(".", arguments.fileID)>

			<cfset el = this.files>

			<cfloop from="1" to="#ArrayLen(segments)#" index="i">
				<cfif NOT isMap(el)>
					<cfreturn false>
				</cfif>

				<cfset key = findKey(el, segments[i])>

				<cfif key EQ "">
					<cfreturn false>
				</cfif>

				<cfset el = el[key]>
			</cfloop>

			<cfreturn true>
		</cfif>

		<cfreturn findKey(this.files, arguments.fileID) NEQ "">
	</cffunction>

	<!---
	 * Taps into the files array of the Superglobals service and creates
	 * UploadedFile instances for each one, then stores them in this
	 * collection (once, the first time it is needed).
	 *
	 * @return void
	--->
	<cffunction name="populateFiles" access="private" returntype="void" output="no">
		<cfset var files = "">
		<cfset var name = "">

		<cfif isMap(this.files)>
			<cfreturn>
		</cfif>

		<cfset this.files = array_()>

		<cfset files = service("superglobals").getFilesArray()>

		<cfif NOT isMap(files) OR StructCount(files) EQ 0>
			<cfreturn>
		</cfif>

		<cfset files = fixFilesArray(files)>

		<cfloop collection="#files#" item="name">
			<cfset this.files[name] = createFileObject(files[name])>
		</cfloop>
	</cffunction>

	<!---
	 * Creates an array of UploadedFile instances for any files uploaded
	 * as part of this request, or the one UploadedFile for an entry with the
	 * keys of a file.
	 *
	 * @param array The entry of the (fixed) files array
	 *
	 * @return array<UploadedFile>|UploadedFile
	--->
	<cffunction name="createFileObject" access="private" returntype="any" output="no">
		<cfargument name="array" type="any" required="yes">
		<cfset var output = "">
		<cfset var key = "">
		<cfset var values = "">

		<cfif NOT array_key_exists("name", arguments.array)>
			<cfset output = array_()>

			<cfloop collection="#arguments.array#" item="key">
				<cfset values = arguments.array[key]>

				<cfif isMap(values)>
					<cfset output[key] = createFileObject(values)>
				</cfif>
			</cfloop>

			<cfreturn output>
		</cfif>

		<cfreturn new_("ColdIgniter\HTTP\Files\UploadedFile",
			valueOr(arguments.array, "tmp_name"),
			arguments.array["name"],
			valueOr(arguments.array, "type"),
			valueOr(arguments.array, "size"),
			valueOr(arguments.array, "error"),
			valueOr(arguments.array, "full_path"))>
	</cffunction>

	<!---
	 * Reformats the odd files array (the $_FILES of the original) into
	 * something much more like we would expect, with each object having its
	 * own array.
	 *
	 * Thanks to Jack Sleight for the basis of this method.
	 *
	 * @return array<string, array<string, mixed>>
	--->
	<cffunction name="fixFilesArray" access="private" returntype="any" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfset var output = array_()>
		<cfset var name = "">
		<cfset var array = "">
		<cfset var field = "">
		<cfset var value = "">

		<cfloop collection="#arguments.data#" item="name">
			<cfset array = arguments.data[name]>

			<cfloop collection="#array#" item="field">
				<cfset value = array[field]>

				<cfif NOT StructKeyExists(output, name)>
					<cfset output[name] = array_()>
				</cfif>

				<cfif NOT isMap(value)>
					<cfset output[name][field] = value>
				<cfelse>
					<!--- the keys of a nested value become the keys of the file, each with the field --->
					<cfset fixWalk(output[name], value, field)>
				</cfif>
			</cfloop>
		</cfloop>

		<cfreturn output>
	</cffunction>

	<!---
	 * The walk that replaces the RecursiveIteratorIterator of the original:
	 * for each key of the value, the leaf holds the field, so docs[name][0]
	 * becomes docs[0][name].
	 *
	 * Not in the original.
	--->
	<cffunction name="fixWalk" access="private" returntype="void" output="no">
		<cfargument name="node" type="any" required="yes">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="field" type="string" required="yes">
		<cfset var key = "">
		<cfset var child = "">
		<cfset var item = "">

		<cfloop collection="#arguments.value#" item="key">
			<cfset item = arguments.value[key]>

			<cfif NOT StructKeyExists(arguments.node, key)>
				<cfset arguments.node[key] = array_()>
			</cfif>

			<cfset child = arguments.node[key]>

			<cfif isMap(item)>
				<cfset fixWalk(child, item, arguments.field)>
			<cfelse>
				<cfset child[arguments.field] = item>
			</cfif>
		</cfloop>
	</cffunction>

	<!---
	 * Navigate through a array looking for a particular index
	 *
	 * @param index The index sequence we are navigating down (a list of parts)
	 * @param value The portion of the array to process
	 *
	 * @return The value found, or an empty string (null)
	--->
	<cffunction name="getValueDotNotationSyntax" access="private" returntype="any" output="no">
		<cfargument name="index" type="array" required="yes">
		<cfargument name="value" type="any" required="yes">
		<cfset var currentIndex = "">
		<cfset var key = "">

		<cfif ArrayLen(arguments.index) EQ 0>
			<cfreturn "">
		</cfif>

		<cfset currentIndex = arguments.index[1]>
		<cfset ArrayDeleteAt(arguments.index, 1)>

		<cfset key = findKey(arguments.value, currentIndex)>

		<cfif ArrayLen(arguments.index) GT 0 AND key NEQ "" AND isMap(arguments.value[key])>
			<cfreturn getValueDotNotationSyntax(arguments.index, arguments.value[key])>
		</cfif>

		<cfif key EQ "">
			<cfreturn "">
		</cfif>

		<cfreturn arguments.value[key]>
	</cffunction>

	<!---
	 * Finds the key of a map for a name: the exact key, or else the first
	 * key that is the same without regard to case. An empty string when
	 * there is none.
	 *
	 * Not in the original.
	--->
	<cffunction name="findKey" access="private" returntype="string" output="no">
		<cfargument name="map" type="any" required="yes">
		<cfargument name="name" type="string" required="yes">
		<cfset var key = "">

		<cfif NOT isMap(arguments.map)>
			<cfreturn "">
		</cfif>

		<cfif StructKeyExists(arguments.map, arguments.name)>
			<cfreturn arguments.name>
		</cfif>

		<cfloop collection="#arguments.map#" item="key">
			<cfif CompareNoCase(key, arguments.name) EQ 0>
				<cfreturn key>
			</cfif>
		</cfloop>

		<cfreturn "">
	</cffunction>

	<!---
	 * Whether a value is an array of the original (a map), which a component
	 * is not.
	 *
	 * Not in the original.
	--->
	<cffunction name="isMap" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfreturn NOT IsObject(arguments.value) AND IsStruct(arguments.value)>
	</cffunction>

	<!---
	 * The first value of a map, or an empty string (array_key_first() of
	 * the original, and the read of that key).
	 *
	 * Not in the original.
	--->
	<cffunction name="firstValue" access="private" returntype="any" output="no">
		<cfargument name="map" type="any" required="yes">
		<cfset var key = "">

		<cfloop collection="#arguments.map#" item="key">
			<cfreturn arguments.map[key]>
		</cfloop>

		<cfreturn "">
	</cffunction>

	<!---
	 * A value of a map, or an empty string (the ?? null of the original).
	 *
	 * Not in the original.
	--->
	<cffunction name="valueOr" access="private" returntype="any" output="no">
		<cfargument name="map" type="any" required="yes">
		<cfargument name="key" type="string" required="yes">

		<cfif StructKeyExists(arguments.map, arguments.key)>
			<cfreturn arguments.map[arguments.key]>
		</cfif>

		<cfreturn "">
	</cffunction>

</cfcomponent>
