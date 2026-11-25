<!---
 * Superglobals manipulation.
 *
 * Provides a clean API for accessing and manipulating the request
 * values, with automatic synchronization of state.
 *
 * The server values are read from the CGI scope, which cannot be
 * changed: a value set here is kept in this object only.
 *
 * Difference: a request header can supply a server variable, so the CGI
 * scope is read through server_value() (see Common.cfm): only the real
 * server variables and the HTTP_* names, and not a server variable that a
 * header has supplied.
 *
 * The get, post and cookie values stand in for the three arrays of the
 * original. They are read from the query string, from a urlencoded
 * body and from the cookie header, so that the names keep the case they
 * were sent in (the url, form and cookie scopes upper-case them).
 *
 * The files array is read from the request only when it is first asked
 * for (getFilesArray()), as every file of the request is saved by cffile
 * then (see readFiles()), so a request that has no use for its uploads
 * costs nothing. On a multipart request the first read or change of the
 * post values reads the files too, so the first getPost() saves every
 * upload of the request (a field that only looked like an upload goes back
 * into the post values then).
 *
 * Not ported yet: the names of a multipart/form-data body, which come
 * from the form scope in upper case.
--->
<cfcomponent output="no" hint="Superglobals manipulation">

	<!--- The server array. Named with an underscore, because server() is a method. --->
	<cfset this.server_ = StructNew()>

	<!--- The get array. Named with an underscore, because get() is a method. --->
	<cfset this.get_ = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!--- The post array. Named with an underscore, because post() is a method. --->
	<cfset this.post_ = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!--- The cookie array. Named with an underscore, because cookie() is a method. --->
	<cfset this.cookie_ = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!--- The files array. --->
	<cfset this.files = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!--- Whether the files array still has to be read from the request (see getFilesArray()). --->
	<cfset this.filesPending = false>

	<!--- The folders that hold the temp files of an upload (a list, read once, see uploadTempDirs()). --->
	<cfset this.tempDirs = "">

	<!--- The request array. Named with an underscore, because request() is a method. --->
	<cfset this.request_ = CreateObject("java", "java.util.LinkedHashMap").init()>

	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="server" type="any" required="no" default="">
		<cfargument name="get" type="any" required="no" default="">
		<cfargument name="post" type="any" required="no" default="">
		<cfargument name="cookie" type="any" required="no" default="">
		<cfargument name="files" type="any" required="no" default="">
		<cfargument name="request_" type="any" required="no" default="">
		<cfset var filesPending = false>

		<cfif NOT is_null(arguments.server)>
			<cfset setServerArray(arguments.server)>
		</cfif>

		<!--- The scopes stand in for the superglobals, where the original reads $_GET, $_POST and $_COOKIE. --->
		<cfif is_null(arguments.get)>
			<cfset arguments.get = parse_str(server_value("QUERY_STRING"))>
		</cfif>
		<cfif is_null(arguments.post)>
			<cfset arguments.post = readPost()>
		</cfif>
		<cfif is_null(arguments.cookie)>
			<cfset arguments.cookie = readCookie()>
		</cfif>
		<cfset filesPending = is_null(arguments.files)>
		<cfif filesPending>
			<cfset arguments.files = CreateObject("java", "java.util.LinkedHashMap").init()>
		</cfif>

		<cfset setGetArray(arguments.get)>
		<cfset setPostArray(arguments.post)>
		<cfset setCookieArray(arguments.cookie)>
		<cfset setFilesArray(arguments.files)>

		<cfif is_null(arguments.request_)>
			<cfset arguments.request_ = getRequestData()>
		</cfif>

		<cfset setRequestArray(arguments.request_)>

		<!--- Difference: the files of the request are read when they are first asked for (after the request array, as its accessors read them). --->
		<cfset this.filesPending = filesPending>

		<cfreturn this>
	</cffunction>

	<!---
	 * Get a server value
	 *
	 * @return The value, or the default (an empty string) if there is none
	--->
	<cffunction name="server" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="default" type="any" required="no" default="">
		<cfset var value = "">

		<cfif StructKeyExists(this.server_, arguments.key)>
			<cfreturn this.server_[arguments.key]>
		</cfif>

		<cfset value = server_value(arguments.key)>

		<!--- The web server gives the path without the query string. --->
		<cfif arguments.key EQ "REQUEST_URI">
			<cfif value EQ "">
				<cfset value = server_value("PATH_INFO")>
			</cfif>
			<cfif server_value("QUERY_STRING") NEQ "">
				<cfset value = value & "?" & server_value("QUERY_STRING")>
			</cfif>
		</cfif>

		<cfif value EQ "">
			<cfreturn arguments.default>
		</cfif>

		<cfreturn value>
	</cffunction>

	<!---
	 * Set a server value
	--->
	<cffunction name="setServer" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="value" type="any" required="yes">

		<cfset this.server_[arguments.key] = arguments.value>

		<cfreturn this>
	</cffunction>

	<!---
	 * Remove a server value
	--->
	<cffunction name="unsetServer" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">

		<cfset StructDelete(this.server_, arguments.key)>

		<cfreturn this>
	</cffunction>


	<!---
	 * Get all server values.
	 *
	 * The CGI scope has no values that are empty, and a value set with
	 * setServer() comes last.
	--->
	<cffunction name="getServerArray" access="public" returntype="any" output="no">
		<cfset var result = CreateObject("java", "java.util.LinkedHashMap").init()>
		<cfset var key = "">
		<cfset var value = "">

		<cfloop collection="#CGI#" item="key">
			<cfset value = server_value(key)>

			<cfif value NEQ "">
				<cfset result[key] = value>
			</cfif>
		</cfloop>

		<cfset result["REQUEST_URI"] = this.server("REQUEST_URI")>

		<cfloop collection="#this.server_#" item="key">
			<cfset result[key] = this.server_[key]>
		</cfloop>

		<cfreturn result>
	</cffunction>

	<!---
	 * Set the entire server array.
	 *
	 * Difference: a key that is not in it is still read from the CGI scope.
	--->
	<cffunction name="setServerArray" access="public" returntype="any" output="no">
		<cfargument name="array" type="any" required="yes">

		<cfset this.server_ = arguments.array>

		<cfreturn this>
	</cffunction>

	<!---
	 * Get a value from GET.
	 *
	 * @return The value, or the default (an empty string) if there is none
	--->
	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="default" type="any" required="no" default="">

		<cfif StructKeyExists(this.get_, arguments.key)>
			<cfreturn this.get_[arguments.key]>
		</cfif>

		<cfreturn arguments.default>
	</cffunction>

	<!---
	 * Set a value in GET.
	--->
	<cffunction name="setGet" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="value" type="any" required="yes">

		<cfset this.get_[arguments.key] = arguments.value>

		<cfreturn this>
	</cffunction>

	<!---
	 * Remove a key from GET.
	--->
	<cffunction name="unsetGet" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">

		<cfset this.get_.remove(arguments.key)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Get all GET values.
	--->
	<cffunction name="getGetArray" access="public" returntype="any" output="no">
		<cfreturn this.get_>
	</cffunction>

	<!---
	 * Set the entire GET array.
	--->
	<cffunction name="setGetArray" access="public" returntype="any" output="no">
		<cfargument name="array" type="any" required="yes">

		<cfset this.get_ = arguments.array>

		<cfreturn this>
	</cffunction>

	<!---
	 * Get a value from POST.
	 *
	 * @return The value, or the default (an empty string) if there is none
	--->
	<cffunction name="post" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="default" type="any" required="no" default="">

		<!--- Difference: the files are read first, as that puts back the fields that only looked like uploads --->
		<cfif this.filesPending>
			<cfset getFilesArray()>
		</cfif>

		<cfif StructKeyExists(this.post_, arguments.key)>
			<cfreturn this.post_[arguments.key]>
		</cfif>

		<cfreturn arguments.default>
	</cffunction>

	<!---
	 * Set a value in POST.
	--->
	<cffunction name="setPost" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="value" type="any" required="yes">

		<cfif this.filesPending>
			<cfset getFilesArray()>
		</cfif>

		<cfset this.post_[arguments.key] = arguments.value>

		<cfreturn this>
	</cffunction>

	<!---
	 * Remove a key from POST.
	--->
	<cffunction name="unsetPost" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">

		<cfif this.filesPending>
			<cfset getFilesArray()>
		</cfif>

		<cfset this.post_.remove(arguments.key)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Get all POST values.
	--->
	<cffunction name="getPostArray" access="public" returntype="any" output="no">
		<cfif this.filesPending>
			<cfset getFilesArray()>
		</cfif>

		<cfreturn this.post_>
	</cffunction>

	<!---
	 * Set the entire POST array.
	--->
	<cffunction name="setPostArray" access="public" returntype="any" output="no">
		<cfargument name="array" type="any" required="yes">

		<cfif this.filesPending>
			<cfset getFilesArray()>
		</cfif>

		<cfset this.post_ = arguments.array>

		<cfreturn this>
	</cffunction>

	<!---
	 * Get a value from COOKIE.
	 *
	 * @return The value, or the default (an empty string) if there is none
	--->
	<cffunction name="cookie" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="default" type="any" required="no" default="">

		<cfif StructKeyExists(this.cookie_, arguments.key)>
			<cfreturn this.cookie_[arguments.key]>
		</cfif>

		<cfreturn arguments.default>
	</cffunction>

	<!---
	 * Set a value in COOKIE.
	--->
	<cffunction name="setCookie" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="value" type="any" required="yes">

		<cfset this.cookie_[arguments.key] = arguments.value>

		<cfreturn this>
	</cffunction>

	<!---
	 * Remove a key from COOKIE.
	--->
	<cffunction name="unsetCookie" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">

		<cfset this.cookie_.remove(arguments.key)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Get all COOKIE values.
	--->
	<cffunction name="getCookieArray" access="public" returntype="any" output="no">
		<cfreturn this.cookie_>
	</cffunction>

	<!---
	 * Set the entire COOKIE array.
	--->
	<cffunction name="setCookieArray" access="public" returntype="any" output="no">
		<cfargument name="array" type="any" required="yes">

		<cfset this.cookie_ = arguments.array>

		<cfreturn this>
	</cffunction>

	<!---
	 * Get a value from REQUEST.
	 *
	 * @return The value, or the default (an empty string) if there is none
	--->
	<cffunction name="request" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="default" type="any" required="no" default="">

		<cfif this.filesPending>
			<cfset getFilesArray()>
		</cfif>

		<cfif StructKeyExists(this.request_, arguments.key)>
			<cfreturn this.request_[arguments.key]>
		</cfif>

		<cfreturn arguments.default>
	</cffunction>

	<!---
	 * Set a value in REQUEST.
	--->
	<cffunction name="setRequest" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="value" type="any" required="yes">

		<cfif this.filesPending>
			<cfset getFilesArray()>
		</cfif>

		<cfset this.request_[arguments.key] = arguments.value>

		<cfreturn this>
	</cffunction>

	<!---
	 * Remove a key from REQUEST.
	--->
	<cffunction name="unsetRequest" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">

		<cfif this.filesPending>
			<cfset getFilesArray()>
		</cfif>

		<cfset this.request_.remove(arguments.key)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Get all REQUEST values.
	--->
	<cffunction name="getRequestArray" access="public" returntype="any" output="no">
		<cfif this.filesPending>
			<cfset getFilesArray()>
		</cfif>

		<cfreturn this.request_>
	</cffunction>

	<!---
	 * Set the entire REQUEST array.
	--->
	<cffunction name="setRequestArray" access="public" returntype="any" output="no">
		<cfargument name="array" type="any" required="yes">

		<cfif this.filesPending>
			<cfset getFilesArray()>
		</cfif>

		<cfset this.request_ = arguments.array>

		<cfreturn this>
	</cffunction>

	<!---
	 * Returns the merged GET, POST, and COOKIE data according to the
	 * `request_order` (or `variables_order`) ini setting, without mutating
	 * the request array.
	 *
	 * The request array is filled only once at the start of the request.
	 * When the get array is modified later (e.g. by SiteURIFactory), it
	 * becomes stale. This method returns the current merged values so
	 * callers can read up-to-date request data without relying on the
	 * stale request array.
	 *
	 * @param requestOrder Overrides the `request_order` ini setting.
	 *                     Useful for testing, since the ini setting
	 *                     cannot be changed at runtime.
	--->
	<cffunction name="getRequestData" access="public" returntype="any" output="no">
		<cfargument name="requestOrder" type="string" required="no" default="">
		<cfset var merged = CreateObject("java", "java.util.LinkedHashMap").init()>
		<cfset var seen = "">
		<cfset var type = "">
		<cfset var i = 0>

		<cfif is_null(arguments.requestOrder)>
			<cfset arguments.requestOrder = ini_get("request_order")>
		</cfif>

		<cfif arguments.requestOrder EQ "">
			<cfset arguments.requestOrder = ini_get("variables_order")>
		</cfif>

		<cfif arguments.requestOrder EQ "">
			<cfset arguments.requestOrder = "GP">
		</cfif>

		<cfset arguments.requestOrder = UCase(arguments.requestOrder)>

		<cfloop from="1" to="#Len(arguments.requestOrder)#" index="i">
			<cfset type = Mid(arguments.requestOrder, i, 1)>

			<!--- Every letter counts once (array_unique) --->
			<cfif Find(type, seen) EQ 0>
				<cfset seen = seen & type>

				<!--- array_replace_recursive() matches the merge of the request array: array values are merged recursively. --->
				<cfif type EQ "G">
					<cfset merged = array_replace_recursive(merged, this.get_)>
				<cfelseif type EQ "P">
					<cfset merged = array_replace_recursive(merged, this.post_)>
				<cfelseif type EQ "C">
					<cfset merged = array_replace_recursive(merged, this.cookie_)>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn merged>
	</cffunction>

	<!---
	 * Get all files values.
	--->
	<cffunction name="getFilesArray" access="public" returntype="any" output="no">
		<cfif this.filesPending>
			<cfset this.filesPending = false>
			<cfset this.files = readFiles()>
		</cfif>

		<cfreturn this.files>
	</cffunction>

	<!---
	 * Set the entire files array.
	--->
	<cffunction name="setFilesArray" access="public" returntype="any" output="no">
		<cfargument name="array" type="any" required="yes">

		<cfset this.files = arguments.array>
		<cfset this.filesPending = false>

		<cfreturn this>
	</cffunction>

	<!---
	 * Get a superglobal array by name.
	 *
	 * @param name The superglobal name (server, get, post, cookie, files, request)
	 *
	 * @throws InvalidArgumentException If the superglobal name is invalid
	--->
	<cffunction name="getGlobalArray" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">

		<cfswitch expression="#arguments.name#">
			<cfcase value="server"><cfreturn getServerArray()></cfcase>
			<cfcase value="get"><cfreturn getGetArray()></cfcase>
			<cfcase value="post"><cfreturn getPostArray()></cfcase>
			<cfcase value="cookie"><cfreturn getCookieArray()></cfcase>
			<cfcase value="files"><cfreturn getFilesArray()></cfcase>
			<cfcase value="request"><cfreturn getRequestArray()></cfcase>
			<cfdefaultcase>
				<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Invalid superglobal name '#arguments.name#'. Must be one of: server, get, post, cookie, files, request.">
			</cfdefaultcase>
		</cfswitch>
	</cffunction>

	<!---
	 * Set a superglobal array by name.
	 *
	 * @param name  The superglobal name (server, get, post, cookie, files, request)
	 * @param array The array to set
	 *
	 * @throws InvalidArgumentException If the superglobal name is invalid
	--->
	<cffunction name="setGlobalArray" access="public" returntype="void" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="array" type="any" required="yes">

		<cfswitch expression="#arguments.name#">
			<cfcase value="server"><cfset setServerArray(arguments.array)></cfcase>
			<cfcase value="get"><cfset setGetArray(arguments.array)></cfcase>
			<cfcase value="post"><cfset setPostArray(arguments.array)></cfcase>
			<cfcase value="cookie"><cfset setCookieArray(arguments.array)></cfcase>
			<cfcase value="files"><cfset setFilesArray(arguments.array)></cfcase>
			<cfcase value="request"><cfset setRequestArray(arguments.array)></cfcase>
			<cfdefaultcase>
				<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Invalid superglobal name '#arguments.name#'. Must be one of: server, get, post, cookie, files, request.">
			</cfdefaultcase>
		</cfswitch>
	</cffunction>

	<!---
	 * The post values of this request. These stand in for the post array
	 * the web server fills in the original.
	 *
	 * A urlencoded body is parsed from the body itself, to keep the names
	 * as they were sent. For multipart/form-data the form scope is all
	 * there is, so the names are upper case and several values of a name
	 * come joined by commas.
	--->
	<cffunction name="readPost" access="private" returntype="any" output="no">
		<cfset var contentType = LCase(CGI.CONTENT_TYPE)>
		<cfset var content = "">
		<cfset var query = "">
		<cfset var parsed = "">
		<cfset var key = "">

		<cfif server_value("REQUEST_METHOD") NEQ "POST">
			<cfreturn CreateObject("java", "java.util.LinkedHashMap").init()>
		</cfif>

		<cfif Find("application/x-www-form-urlencoded", contentType) GT 0>
			<cfset content = http_request_data().content>

			<cfif IsBinary(content)>
				<cfset content = ToString(content)>
			</cfif>

			<cfreturn parse_str(content)>
		</cfif>

		<cfif Find("multipart/form-data", contentType) GT 0>
			<cfloop collection="#form#" item="key">
				<!--- Difference: the temp file of an upload is no post value (see readFiles()) --->
				<cfif key NEQ "FIELDNAMES" AND IsSimpleValue(form[key]) AND NOT isUploadValue(form[key])>
					<cfset query = query & "&" & URLEncodedFormat(key) & "=" & URLEncodedFormat(form[key])>
				</cfif>
			</cfloop>

			<!---
			 Difference: the names are upper case and their case is gone, so
			 the map is a CFML structure, whose names are found without regard
			 to case: getPost("title") finds TITLE. The order of the fields is
			 not kept. Only the top level ignores case: the maps of a name with
			 brackets, a[b], stay case-sensitive (a[B]).
			--->
			<cfset parsed = parse_str(query)>
			<cfset content = StructNew()>

			<cfloop collection="#parsed#" item="key">
				<cfset content[key] = parsed[key]>
			</cfloop>

			<cfreturn content>
		</cfif>

		<cfreturn CreateObject("java", "java.util.LinkedHashMap").init()>
	</cffunction>

	<!---
	 * The files of this request, as the files array (the $_FILES of the
	 * original) holds them: for each field the keys name, full_path, type,
	 * tmp_name, error and size, and for a field with brackets (docs[]) a
	 * nested value under each of the keys. FileCollection turns it into
	 * UploadedFile objects.
	 *
	 * There is no files array on the server. The engine reads a
	 * multipart/form-data body, saves every file to a temp file and puts the
	 * path of that file in the form scope as the value of the field. So a
	 * file field is a field whose value is the path of a file in a temp
	 * folder of the engine (see isTempUpload(): nothing else counts, so a
	 * text field cannot name a file of the server). The name, the type and the
	 * size of the client are not in the form scope; cffile action="upload"
	 * gives them, and saves the file to a folder of its own in the temp
	 * folder, one per request, which Boot removes at the end of the request
	 * (request.ColdIgniter.uploadDirs). Only the paths of such files are
	 * valid uploads (request.ColdIgniter.uploads, see UploadedFile.isValid()).
	 *
	 * Difference: the names are upper case, as the form scope has them, and
	 * FileCollection finds a field without regard to case.
	 *
	 * Difference: an entry exists only for a file that cffile saved, and its
	 * error is always 0. A field that cffile refuses has no entry (see
	 * below), and a field with no file chosen has none either, where the
	 * original has one with the error 4 (UPLOAD_ERR_NO_FILE), as an empty file
	 * field cannot be told from an empty text field. The other error codes
	 * are not known.
	 *
	 * Difference: a value that looks like a temp file but that cffile does
	 * not take as a file part stays a post value, with no files entry. The
	 * files are read the first time the post values or the files are asked
	 * for, so that post is complete either way.
	 *
	 * Difference: the full_path is the name of the client, as the engine does
	 * not give the relative path of a folder upload.
	 *
	 * Not ported yet: a field name that comes more than once (docs[] with
	 * two files). The engine keeps one value for it, the last, and the form
	 * scope cannot tell a file part from a text part, so it could be made to
	 * take a file of another request. Such a name has no files entry: its
	 * value goes back to the post values, as text. The names are counted in
	 * the field names list of the form scope.
	 *
	 * Only one level of brackets is read (docs[] or docs[key]).
	--->
	<cffunction name="readFiles" access="private" returntype="any" output="no">
		<cfset var raw = CreateObject("java", "java.util.LinkedHashMap").init()>
		<cfset var fields = "name,full_path,type,tmp_name,error,size">
		<cfset var key = "">
		<cfset var name = "">
		<cfset var sub = "">
		<cfset var isList = false>
		<cfset var paths = "">
		<cfset var info = "">
		<cfset var position = 0>
		<cfset var close = 0>
		<cfset var index = "">
		<cfset var field = "">
		<cfset var holder = "">
		<cfset var entry = "">
		<cfset var count = 0>
		<cfset var i = 0>

		<cfif server_value("REQUEST_METHOD") NEQ "POST" OR Find("multipart/form-data", LCase(CGI.CONTENT_TYPE)) EQ 0>
			<cfreturn raw>
		</cfif>

		<cfloop collection="#form#" item="key">
			<cfif key NEQ "FIELDNAMES" AND IsSimpleValue(form[key]) AND isUploadValue(form[key])>
				<cfset paths = ListToArray(form[key])>
				<cfset name = key>
				<cfset sub = "">
				<cfset isList = false>
				<cfset position = Find("[", key)>
				<cfset close = Find("]", key, position)>

				<cfif position GT 1 AND close GT position>
					<cfset name = Left(key, position - 1)>
					<cfset sub = Mid(key, position + 1, close - position - 1)>
					<cfset isList = true>
				</cfif>

				<!--- the form scope lists a name once for each part, but keeps one value --->
				<cfset count = Max(ArrayLen(paths), ListValueCount(form.FIELDNAMES, key))>

				<cfif count GT 1>
					<cfset isList = true>
				</cfif>

				<cfif count GT 1>
					<!--- a name that comes more than once: the form scope cannot tell a file part from a text part --->
					<cfset restorePost(key)>
					<cfset paths = ArrayNew(1)>
				</cfif>

				<cfloop from="1" to="#ArrayLen(paths)#" index="i">
					<cfset info = fileInfo(key, paths[i])>

					<cfif info.error NEQ 0>
						<!--- cffile refused it, so it is a text field after all: back to post, no files entry --->
						<cfset restorePost(key)>
					<cfelse>
						<cfif NOT StructKeyExists(raw, name)>
							<cfset raw[name] = CreateObject("java", "java.util.LinkedHashMap").init()>
						</cfif>

						<cfloop list="#fields#" index="field">
							<cfset entry = raw[name]>

							<cfif NOT isList>
								<cfset entry[field] = info[field]>
							<cfelse>
								<cfif NOT StructKeyExists(entry, field)>
									<cfset entry[field] = CreateObject("java", "java.util.LinkedHashMap").init()>
								</cfif>

								<cfset holder = entry[field]>
								<cfset index = sub>

								<cfif index EQ "" OR ArrayLen(paths) GT 1>
									<cfset index = StructCount(holder) & "">
								</cfif>

								<cfset holder[index] = info[field]>
							</cfif>
						</cfloop>
					</cfif>
				</cfloop>
			</cfif>
		</cfloop>

		<cfreturn raw>
	</cffunction>

	<!---
	 * Puts a form field back in the post values: a field whose value looked
	 * like a temp file but that cffile did not take as a file part (see
	 * readFiles()). Only the names that are not there yet are added.
	 *
	 * Not in the original.
	--->
	<cffunction name="restorePost" access="private" returntype="void" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfset var parsed = parse_str(URLEncodedFormat(arguments.key) & "=" & URLEncodedFormat(form[arguments.key]))>

		<!--- the request values hold the post values too (see getRequestData()) --->
		<cfset mergeInto(this.post_, parsed)>
		<cfset mergeInto(this.request_, parsed)>
	</cffunction>

	<!---
	 * Adds the names of a map to another, level by level: a name that is
	 * there already is kept (a refused a[x] joins the a[y] that was set), and
	 * a map is merged into a map.
	 *
	 * Not in the original.
	--->
	<cffunction name="mergeInto" access="private" returntype="void" output="no">
		<cfargument name="target" type="any" required="yes">
		<cfargument name="source" type="any" required="yes">
		<cfset var name = "">

		<cfloop collection="#arguments.source#" item="name">
			<cfif NOT StructKeyExists(arguments.target, name)>
				<cfset arguments.target[name] = arguments.source[name]>
			<cfelseif IsStruct(arguments.target[name]) AND IsStruct(arguments.source[name])>
				<cfset mergeInto(arguments.target[name], arguments.source[name])>
			</cfif>
		</cfloop>
	</cffunction>

	<!---
	 * What is known of one upload: a structure with the keys of an entry
	 * of the files array. A path is an upload (error 0) only when cffile
	 * saved it in the folder of this request; in every other case the error
	 * is 7 and there is no path, which readFiles() takes as a refused field
	 * (it is put back in the post values and gets no entry), so a text field
	 * that holds the path of a file of the temp folder is never an upload.
	 *
	 * Not in the original.
	 *
	 * @param field The name of the form field
	 * @param path  The path of the temp file that the form scope has
	--->
	<cffunction name="fileInfo" access="private" returntype="struct" output="no">
		<cfargument name="field" type="string" required="yes">
		<cfargument name="path" type="string" required="yes">
		<cfset var info = StructNew()>
		<cfset var dir = uploadDir()>
		<cfset var saved = "">
		<cfset var file = "">
		<cfset var folder = "">
		<cfset var ok = false>

		<!--- error 7 and no path, unless cffile saved the file in the folder of this request --->
		<cfset info.name = "">
		<cfset info.full_path = "">
		<cfset info.type = "application/octet-stream">
		<cfset info.tmp_name = "">
		<cfset info.error = 7>
		<cfset info.size = 0>

		<cftry>
			<cffile action="upload" filefield="#arguments.field#" destination="#dir#" nameconflict="makeunique">

			<cfset info.name = cffile.clientFile>
			<cfset info.full_path = cffile.clientFile>
			<cfset info.type = cffile.contentType & "/" & cffile.contentSubType>
			<cfset saved = cffile.serverDirectory & request.DIRECTORY_SEPARATOR & cffile.serverFile>
			<cfset ok = true>

			<cfcatch type="any">
				<cfset ok = false>
			</cfcatch>
		</cftry>

		<cfif ok>
			<cfset file = CreateObject("java", "java.io.File").init(JavaCast("string", saved))>
			<cfset folder = CreateObject("java", "java.io.File").init(JavaCast("string", dir))>

			<!--- the saved file must be in the folder made for it --->
			<cfif file.isFile() AND Compare(LCase(file.getCanonicalFile().getParentFile().getPath() & ""), LCase(folder.getCanonicalPath() & "")) EQ 0>
				<cfset info.tmp_name = file.getCanonicalPath() & "">
				<cfset info.error = 0>
				<cfset info.size = file.length()>

				<!--- only a path in this list is an upload (see UploadedFile.isValid()) --->
				<cfif NOT StructKeyExists(request.ColdIgniter, "uploads")>
					<cfset request.ColdIgniter.uploads = StructNew()>
				</cfif>

				<cfset request.ColdIgniter.uploads[LCase(info.tmp_name)] = info.tmp_name>
			</cfif>
		</cfif>

		<cfreturn info>
	</cffunction>

	<!---
	 * The folder that holds the saved uploads of this request: a new folder
	 * in the temp folder, named from a UUID, made on the first call. Boot
	 * removes it, with what is in it, at the end of the request.
	 *
	 * Not in the original.
	--->
	<cffunction name="uploadDir" access="private" returntype="string" output="no">
		<cfset var dir = "">
		<cfset var folder = "">

		<cfif NOT StructKeyExists(request.ColdIgniter, "uploadDirs")>
			<cfset request.ColdIgniter.uploadDirs = StructNew()>
		</cfif>

		<cfloop collection="#request.ColdIgniter.uploadDirs#" item="dir">
			<cfreturn request.ColdIgniter.uploadDirs[dir]>
		</cfloop>

		<cfset dir = GetTempDirectory() & "ciup_" & CreateUUID() & request.DIRECTORY_SEPARATOR>
		<cfset folder = CreateObject("java", "java.io.File").init(JavaCast("string", dir))>
		<cfset folder.mkdirs()>

		<cfset request.ColdIgniter.uploadDirs[LCase(dir)] = dir>

		<cfset sweepUploadDirs(dir)>

		<cfreturn dir>
	</cffunction>

	<!---
	 * Removes the upload folders (ciup_ and a UUID) of earlier requests that
	 * Boot could not clean, as a request that timed out or was aborted does
	 * not get to it: folders in the temp folder that are older than an hour.
	 * Only folders of that name, and only the files in them, are removed. It
	 * runs when the first upload folder of a request is made, never on a
	 * request without an upload.
	 *
	 * Not in the original.
	 *
	 * @param current The folder of this request, which is left alone
	--->
	<cffunction name="sweepUploadDirs" access="private" returntype="void" output="no">
		<cfargument name="current" type="string" required="yes">
		<cfset var folders = "">
		<cfset var files = "">
		<cfset var path = "">

		<cftry>
			<cfdirectory action="list" directory="#GetTempDirectory()#" name="folders" filter="ciup_*">

			<cfloop query="folders">
				<cfif folders.type EQ "Dir" AND Len(folders.name) EQ 40 AND Left(folders.name, 5) EQ "ciup_" AND DateDiff("n", folders.dateLastModified, Now()) GT 60>
					<cfset path = GetTempDirectory() & folders.name & request.DIRECTORY_SEPARATOR>

					<cfif CompareNoCase(path, arguments.current) NEQ 0>
						<cfdirectory action="list" directory="#path#" name="files">

						<cfloop query="files">
							<cfif files.type EQ "File">
								<cffile action="delete" file="#path##files.name#">
							</cfif>
						</cfloop>

						<cfdirectory action="delete" directory="#path#">
					</cfif>
				</cfif>
			</cfloop>

			<cfcatch type="any"></cfcatch>
		</cftry>
	</cffunction>

	<!---
	 * The temp folders of the engine, as lower case canonical paths: the
	 * folder GetTempDirectory() gives, and the temp folder of the servlet
	 * context (javax.servlet.context.tempdir). Read once.
	 *
	 * Not in the original.
	--->
	<cffunction name="uploadTempDirs" access="private" returntype="array" output="no">
		<cfset var dirs = ArrayNew(1)>
		<cfset var attribute = "">

		<cfif IsArray(this.tempDirs)>
			<cfreturn this.tempDirs>
		</cfif>

		<cftry>
			<cfset ArrayAppend(dirs, LCase(CreateObject("java", "java.io.File").init(JavaCast("string", GetTempDirectory())).getCanonicalPath()))>

			<cfcatch type="any"></cfcatch>
		</cftry>

		<cftry>
			<cfset attribute = GetPageContext().getServletContext().getAttribute(JavaCast("string", "javax.servlet.context.tempdir"))>

			<cfif IsDefined("attribute")>
				<cfset ArrayAppend(dirs, LCase(CreateObject("java", "java.io.File").init(JavaCast("string", attribute.toString())).getCanonicalPath()))>
			</cfif>

			<cfcatch type="any"></cfcatch>
		</cftry>

		<cfset this.tempDirs = dirs>

		<cfreturn dirs>
	</cffunction>

	<!---
	 * Whether a path is the temp file of an upload: a file with the
	 * extension tmp and a name that starts with neotmp (the engine's names) in a temp folder of the engine, after the path is made
	 * canonical (so a ".." in a text field names no other folder).
	 *
	 * Not in the original. An engine that names its temp files otherwise
	 * needs the test changed here.
	--->
	<cffunction name="isTempUpload" access="private" returntype="boolean" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfset var file = "">
		<cfset var name = "">
		<cfset var parent = "">
		<cfset var dirs = uploadTempDirs()>
		<cfset var i = 0>

		<cfif Len(arguments.path) LT 5 OR Len(arguments.path) GT 400>
			<cfreturn false>
		</cfif>

		<cftry>
			<cfset file = CreateObject("java", "java.io.File").init(JavaCast("string", arguments.path)).getCanonicalFile()>
			<cfset name = file.getName() & "">
			<cfset parent = LCase(file.getParentFile().getPath() & "")>

			<cfif NOT file.isFile()>
				<cfreturn false>
			</cfif>

			<cfif CompareNoCase(Right(name, 4), ".tmp") NEQ 0 OR CompareNoCase(Left(name, 6), "neotmp") NEQ 0>
				<cfreturn false>
			</cfif>

			<cfloop from="1" to="#ArrayLen(dirs)#" index="i">
				<cfif Compare(parent, dirs[i] & "") EQ 0>
					<cfreturn true>
				</cfif>
			</cfloop>

			<cfcatch type="any"></cfcatch>
		</cftry>

		<cfreturn false>
	</cffunction>

	<!---
	 * Whether the value of a form field is the temp file of an upload, or
	 * a list of them (several files of one name come joined by commas).
	 *
	 * Not in the original.
	--->
	<cffunction name="isUploadValue" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="string" required="yes">
		<cfset var paths = "">
		<cfset var i = 0>

		<cfif Len(arguments.value) LT 5 OR Find(".tmp", LCase(arguments.value)) EQ 0>
			<cfreturn false>
		</cfif>

		<cfset paths = ListToArray(arguments.value)>

		<cfloop from="1" to="#ArrayLen(paths)#" index="i">
			<cfif NOT isTempUpload(paths[i])>
				<cfreturn false>
			</cfif>
		</cfloop>

		<cfreturn ArrayLen(paths) GT 0>
	</cffunction>

	<!---
	 * The cookies of this request, read from the cookie header, because
	 * the cookie scope upper-cases the names. These stand in for the
	 * cookie array the web server fills in the original.
	--->
	<cffunction name="readCookie" access="private" returntype="any" output="no">
		<cfset var pairs = explode(";", CGI.HTTP_COOKIE)>
		<cfset var query = "">
		<cfset var seen = CreateObject("java", "java.util.HashMap").init()>
		<cfset var name = "">
		<cfset var position = 0>
		<cfset var isElement = false>
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(pairs)#" index="i">
			<cfif Trim(pairs[i]) NEQ "">
				<!--- a name that repeats keeps its first value (an array element appends) --->
				<cfset name = Trim(pairs[i])>
				<cfset position = Find("=", name)>
				<cfif position GT 0>
					<cfset name = Left(name, position - 1)>
				</cfif>

				<!--- the name as parse_str() keys it: cut at a NUL, decoded, left-trimmed, dots and spaces replaced --->
				<cfset position = FindNoCase("%00", name)>
				<cfif position GT 0>
					<cfset name = Left(name, position - 1)>
				</cfif>
				<cfset name = LTrim(parse_str_decode(name))>
				<cfset position = Find("[", name)>
				<cfset isElement = position GT 0 AND Find("]", name, position) GT 0>
				<cfset name = parse_str_key(name)>

				<cfif isElement OR NOT seen.containsKey(name)>
					<cfset seen.put(name, "")>

					<!--- a cookie value is not form-encoded: keep a plus and an ampersand --->
					<cfset query = query & "&" & Replace(Replace(Trim(pairs[i]), "+", "%2B", "all"), "&", "%26", "all")>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn parse_str(query)>
	</cffunction>

</cfcomponent>
