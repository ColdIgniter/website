<!---
 * File system cache handler.
 *
 * Difference: the stored file holds two objects of a Java object stream
 * (ObjectOutputStream) and not serialize(): a small map {time, ttl}, then
 * the value. It is the form the server writes and reads fastest, there is
 * no parsing, and the expiry is known from the first object, so the value
 * of an expired file is never read. A value comes back as it went
 * in: a string, a number, a map (a struct, which keeps its kind and so
 * the order of its keys), an array and a query. A component cannot be
 * cached, also not inside a map or an array: save() returns false. The
 * file is read with readObject(), so, as with unserialize(), the cache
 * directory must be writable by the application only.
 *
 * Difference: getShared() is not in the original. It gives the value from
 * a map in the application scope of the server (application.ColdIgniter),
 * which holds the items read from a file, and reads the file only when the
 * item is not there, was changed or has expired. The value is shared by all
 * requests, so the caller must not change it. The file stays the durable
 * copy: save(), delete(), deleteMatching() and clean() drop the items of
 * the map, and an item is used only while the modified time of its file
 * is the one that it was read with (a file that is deleted or written from
 * outside is noticed). The option file_.memoryEntries of Config\Cache is the
 * number of items kept (default 100); 0 switches the map off. Nothing but
 * values saved by the application is kept there, never the .env values.
 *
 * Difference: a file is read under a named readonly lock (cflock) of its
 * full path, and written and deleted under a named exclusive lock. A file
 * is not written to a temporary name and renamed, as a rename over an
 * existing file fails on Windows with the Java of the server, so a file
 * that is cut short by a crash is read as a
 * miss (the stream cannot be read). A file of an earlier version (JSON
 * text, or one object only) is a miss too.
 *
 * Difference: a key that the file system could not take as a file name
 * (a character of * ? " < > | / \ : or below a space, a name of "." or "..", a
 * trailing period or space, or a device name such as CON or NUL) is stored
 * under the md5 of the prefixed key, as a key that is too long is.
 *
 * Difference: a name of 32 hexadecimal digits (the key of a page) is used
 * as it is, without the checks above.
 *
 * Difference: the cache directory is created when it does not exist.
 *
 * Not ported yet: the option mode and chmod (there is no chmod).
--->
<cfcomponent output="no" extends="BaseHandler" hint="File system cache handler">

	<!---
	 * Maximum key length.
	 *
	 * @var int
	--->
	<cfset this.MAX_KEY_LENGTH = 255>

	<!---
	 * Where to store cached files on the disk.
	 *
	 * @var string
	--->
	<cfset this.path = "">

	<!---
	 * Difference: not in the original. The number of items that the map
	 * in the application scope holds, 0 for none.
	 *
	 * @var int
	--->
	<cfset this.memoryEntries = 100>

	<!---
	 * Difference: not in the original. The map in the application scope (a
	 * synchronized java.util.HashMap), or an empty string when it is off.
	 * Opened once for the request, see getMemory().
	--->
	<cfset this.pageMemory = "">
	<cfset this.pageMemoryReady = false>

	<!---
	 * The entry of the map that the last call of getShared() gave its value
	 * from, or an empty string. A map {file, modified, item}.
	--->
	<cfset this.sharedEntry = "">

	<!---
	 * Note: Use `CacheFactory::getHandler()` to instantiate.
	 *
	 * @throws CacheException
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">
		<cfset var dir = "">
		<cfset var path = request.WRITEPATH & "cache/">
		<cfset var last = "">

		<cfif StructKeyExists(arguments.config.file_, "storePath") AND Compare(arguments.config.file_["storePath"], "") NEQ 0>
			<cfset path = arguments.config.file_["storePath"]>
		</cfif>

		<!--- rtrim($path, '\\/') . '/' --->
		<cfloop condition="Len(path) GT 0">
			<cfset last = Right(path, 1)>

			<cfif Compare(last, "/") NEQ 0 AND Compare(last, "\") NEQ 0>
				<cfbreak>
			</cfif>

			<cfset path = Left(path, Len(path) - 1)>
		</cfloop>

		<cfset this.path = path & "/">

		<cfset dir = CreateObject("java", "java.io.File").init(this.path)>

		<cfif NOT dir.isDirectory() AND NOT dir.mkdirs()>
			<cfset static_("ColdIgniter\Cache\Exceptions\CacheException").forUnableToWrite(this.path)>
		</cfif>

		<cfif NOT dir.canWrite()>
			<cfset static_("ColdIgniter\Cache\Exceptions\CacheException").forUnableToWrite(this.path)>
		</cfif>

		<cfset this.prefix = arguments.config.prefix>

		<cfif StructKeyExists(arguments.config.file_, "memoryEntries")>
			<cfset this.memoryEntries = Val(arguments.config.file_["memoryEntries"])>
		</cfif>

		<cfreturn this>
	</cffunction>

	<cffunction name="initialize_" access="public" returntype="void" output="no">
		<!--- Not implemented --->
		<cfreturn>
	</cffunction>

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfset var data = "">

		<cfset arguments.key = fileKey(arguments.key)>
		<cfset data = getItem(arguments.key)>

		<cfif IsStruct(data)>
			<cfreturn data["data"]>
		</cfif>

		<cfreturn "">
	</cffunction>

	<!---
	 * Difference: not in the original. Like get(), but from the map in
	 * the application scope when the item is there. The value is shared:
	 * it must not be changed.
	--->
	<cffunction name="getShared" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfset var name = fileKey(arguments.key)>
		<cfset var memory = getMemory()>
		<cfset var path = this.path & name>
		<cfset var entry = "">
		<cfset var item = "">
		<cfset var modified = 0>

		<cfset this.sharedEntry = "">

		<cfif IsSimpleValue(memory)>
			<cfset item = getItem(name)>

			<cfif IsStruct(item)>
				<cfreturn item["data"]>
			</cfif>

			<cfreturn "">
		</cfif>

		<cfset entry = memory.get(path)>

		<cfif IsDefined("entry") AND IsStruct(entry)>
			<cfif entry["file"].lastModified() EQ entry["modified"] AND NOT isExpired(entry["item"])>
				<cfset this.sharedEntry = entry>

				<cfreturn entry["item"]["data"]>
			</cfif>

			<!--- changed, deleted or expired: read the file --->
			<cfset memory.remove(path)>
		</cfif>

		<!--- the modified time is taken before the read, so a file written after it is read again --->
		<cfset entry = CreateObject("java", "java.io.File").init(path)>
		<cfset modified = entry.lastModified()>
		<cfset item = getItem(name)>

		<cfif NOT IsStruct(item)>
			<cfreturn "">
		</cfif>

		<!--- No time: the file was made after the time was taken. It is not kept, as a deleted file has no time either. --->
		<cfif modified NEQ 0>
			<cfset remember(memory, path, entry, modified, item)>
		</cfif>

		<cfreturn item["data"]>
	</cffunction>

	<cffunction name="save" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="ttl" type="numeric" required="no" default="60">
		<cfset var head = CreateObject("java", "java.util.LinkedHashMap").init()>

		<cfif IsObject(arguments.value)>
			<cfreturn false>
		</cfif>

		<cfset arguments.key = fileKey(arguments.key)>

		<cfset head.put("time", JavaCast("string", Int(time())))>
		<cfset head.put("ttl", JavaCast("string", Int(arguments.ttl)))>

		<cfreturn writeFile(this.path & arguments.key, head, arguments.value)>
	</cffunction>

	<cffunction name="delete" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfset var file_ = "">
		<cfset var result = false>

		<cfset arguments.key = fileKey(arguments.key)>
		<cfset file_ = CreateObject("java", "java.io.File").init(this.path & arguments.key)>

		<cflock name="ColdIgniterCache#md5(this.path & arguments.key)#" type="exclusive" timeout="10">
			<cfif file_.isFile()>
				<cfset result = file_.delete()>
			</cfif>
		</cflock>

		<cfset forget(this.path & arguments.key)>

		<cfreturn result>
	</cffunction>

	<!---
	 * The pattern is matched against file names only and never becomes part
	 * of a path, so it cannot reach files outside the cache directory.
	 * A wildcard does not match a leading period of a name.
	 *
	 * @param pattern A shell wildcard pattern, see fnmatch()
	 *
	 * @return The number of files deleted
	--->
	<cffunction name="deleteMatching" access="public" returntype="numeric" output="no">
		<cfargument name="pattern" type="string" required="yes">
		<cfset var directory = CreateObject("java", "java.io.File").init(this.path)>
		<cfset var files = "">
		<cfset var deleted = 0>
		<cfset var i = 0>
		<cfset var file_ = "">

		<cfif NOT directory.isDirectory()>
			<cfreturn 0>
		</cfif>

		<cfset files = directory.list()>

		<cfif NOT IsDefined("files")>
			<cfreturn 0>
		</cfif>

		<cfloop index="i" from="1" to="#ArrayLen(files)#">
			<!--- FNM_PERIOD keeps glob() semantics: wildcards don't match a leading dot. --->
			<cfif fnmatch(arguments.pattern, files[i], true)>
				<cfset file_ = CreateObject("java", "java.io.File").init(this.path & files[i])>

				<cflock name="ColdIgniterCache#md5(this.path & files[i])#" type="exclusive" timeout="10">
					<cfif file_.isFile() AND file_.delete()>
						<cfset deleted = deleted + 1>
					</cfif>
				</cflock>

				<cfset forget(this.path & files[i])>
			</cfif>
		</cfloop>

		<cfreturn deleted>
	</cffunction>

	<cffunction name="increment" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="offset" type="numeric" required="no" default="1">
		<cfset var prefixedKey = fileKey(arguments.key)>
		<cfset var tmp = getItem(prefixedKey)>
		<cfset var value = "">
		<cfset var ttl = "">

		<cfif NOT IsStruct(tmp)>
			<cfset tmp = CreateObject("java", "java.util.LinkedHashMap").init()>
			<cfset tmp.put("data", "0")>
			<cfset tmp.put("ttl", "60")>
		</cfif>

		<cfset value = tmp["data"]>
		<cfset ttl = tmp["ttl"]>

		<!---
		 if (! is_int($value))
		 Difference: a string of digits such as "5" counts as an integer
		 here, as a number and its text are the same value in CFML.
		--->
		<cfif NOT IsSimpleValue(value) OR NOT CreateObject("java", "java.lang.String").init(JavaCast("string", value)).matches("-?[0-9]+")>
			<cfreturn false>
		</cfif>

		<cfset value = Int(Val(value) + arguments.offset)>

		<cfif save(arguments.key, value, Val(ttl))>
			<cfreturn value>
		</cfif>

		<cfreturn false>
	</cffunction>

	<cffunction name="decrement" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="offset" type="numeric" required="no" default="1">

		<cfreturn increment(arguments.key, -arguments.offset)>
	</cffunction>

	<!---
	 * Difference: the files that are kept are index.html, index.htm,
	 * .htaccess and web.config.
	--->
	<cffunction name="clean" access="public" returntype="boolean" output="no">
		<cfset var result = deleteFiles(this.path, false, true)>

		<!--- Difference: the items of the map in the application scope go as well --->
		<cfset forget("")>

		<cfreturn result>
	</cffunction>

	<cffunction name="getCacheInfo" access="public" returntype="any" output="no">
		<cfreturn getDirFileInfo(this.path)>
	</cffunction>

	<cffunction name="getMetaData_" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfset var data = "">
		<cfset var result = CreateObject("java", "java.util.LinkedHashMap").init()>
		<cfset var file_ = "">

		<cfset arguments.key = fileKey(arguments.key)>
		<cfset data = getItem(arguments.key)>

		<cfif NOT IsStruct(data)>
			<cfreturn "">
		</cfif>

		<cfset file_ = CreateObject("java", "java.io.File").init(this.path & arguments.key)>

		<cfif Val(data["ttl"]) GT 0>
			<cfset result.put("expire", Val(data["time"]) + Val(data["ttl"]))>
		<cfelse>
			<cfset result.put("expire", "")>
		</cfif>

		<cfset result.put("mtime", Int(file_.lastModified() / 1000))>
		<cfset result.put("data", data["data"])>

		<cfreturn result>
	</cffunction>

	<cffunction name="isSupported" access="public" returntype="boolean" output="no">
		<cfreturn CreateObject("java", "java.io.File").init(this.path).canWrite()>
	</cffunction>

	<!---
	 * Validates the key and makes it a name the file system takes.
	 *
	 * Difference: this method is not in the original, see the Difference
	 * at the top of the file.
	 *
	 * @param key The key without a prefix
	--->
	<cffunction name="fileKey" access="private" returntype="string" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfset var name = validateKey(arguments.key, this.prefix)>
		<cfset var i = 0>
		<cfset var code = 0>
		<cfset var base = "">
		<cfset var bad = false>
		<cfset var last = "">

		<!---
		 * A name of 32 hexadecimal digits, as the key of a page is, is a
		 * good file name: the checks below need not run for it.
		--->
		<cfif Len(name) EQ 32 AND CreateObject("java", "java.lang.String").init(name).matches("[0-9a-fA-F]+")>
			<cfreturn name>
		</cfif>

		<cfif Compare(name, ".") EQ 0 OR Compare(name, "..") EQ 0>
			<cfset bad = true>
		</cfif>

		<cfif NOT bad>
			<cfloop index="i" from="1" to="#Len(name)#">
				<cfset code = Asc(Mid(name, i, 1))>

				<cfif code LT 32 OR code EQ 127 OR Find(Mid(name, i, 1), "*?""<>|/\:") GT 0>
					<cfset bad = true>
					<cfbreak>
				</cfif>
			</cfloop>
		</cfif>

		<cfif NOT bad>
			<cfset last = Right(name, 1)>

			<cfif Compare(last, ".") EQ 0 OR Compare(last, " ") EQ 0>
				<cfset bad = true>
			</cfif>
		</cfif>

		<!--- a device name, also with an extension --->
		<cfif NOT bad>
			<cfset base = UCase(RTrim(ListFirst(Replace(name, ".", Chr(1), "all"), Chr(1))))>

			<cfif CreateObject("java", "java.lang.String").init(base).matches("CON|PRN|AUX|NUL|CLOCK\$|CONIN\$|CONOUT\$|COM[1-9]|LPT[1-9]")>
				<cfset bad = true>
			</cfif>
		</cfif>

		<cfif bad>
			<cfreturn md5(name)>
		</cfif>

		<cfreturn name>
	</cffunction>

	<!---
	 * Does the heavy lifting of actually retrieving the file and
	 * verifying its age.
	 *
	 * Difference: the age is checked on the first object of the file, so the
	 * value of an expired file is not read.
	 *
	 * @return A map {data, ttl, time}, or false
	--->
	<cffunction name="getItem" access="private" returntype="any" output="no">
		<cfargument name="filename" type="string" required="yes">
		<cfset var file_ = CreateObject("java", "java.io.File").init(this.path & arguments.filename)>
		<cfset var raw = "">
		<cfset var stream = "">
		<cfset var head = "">
		<cfset var data = "">
		<cfset var ok = true>
		<cfset var expired = false>
		<cfset var integer = CreateObject("java", "java.lang.String")>

		<cfif NOT file_.isFile()>
			<cfreturn false>
		</cfif>

		<cftry>
			<cflock name="ColdIgniterCache#md5(this.path & arguments.filename)#" type="readonly" timeout="10">
				<cfset raw = CreateObject("java", "java.io.FileInputStream").init(this.path & arguments.filename)>

				<!--- There is no finally: the file is closed in both ways out. --->
				<cftry>
					<cfset stream = CreateObject("java", "java.io.ObjectInputStream").init(
						CreateObject("java", "java.io.BufferedInputStream").init(raw)
					)>
					<cfset head = stream.readObject()>

					<cfif IsStruct(head) AND StructKeyExists(head, "ttl") AND StructKeyExists(head, "time") AND IsSimpleValue(head["ttl"]) AND IsSimpleValue(head["time"])>
						<cfif integer.init(head["ttl"]).matches("-?[0-9]+") AND integer.init(head["time"]).matches("-?[0-9]+")>
							<cfif isExpired(head)>
								<cfset expired = true>
							<cfelse>
								<cfset data = stream.readObject()>
							</cfif>
						<cfelse>
							<cfset ok = false>
						</cfif>
					<cfelse>
						<cfset ok = false>
					</cfif>

					<cfset raw.close()>

					<cfcatch type="any">
						<cfset raw.close()>
						<cfrethrow>
					</cfcatch>
				</cftry>
			</cflock>

			<cfcatch type="any">
				<cfset ok = false>
			</cfcatch>
		</cftry>

		<cfif NOT ok>
			<cfreturn false>
		</cfif>

		<cfif expired>
			<cflock name="ColdIgniterCache#md5(this.path & arguments.filename)#" type="exclusive" timeout="10">
				<cfset file_.delete()>
			</cflock>

			<cfreturn false>
		</cfif>

		<cfset head.put("data", data)>

		<cfreturn head>
	</cffunction>

	<!---
	 * Writes a file to disk, or returns false if not successful.
	 *
	 * @param path Path to the file
	 * @param head The map {time, ttl}, the first object of the file
	 * @param data The value to write, the second object (Difference: not text, see the header)
	 * @param mode Not used, the file is always written whole
	--->
	<cffunction name="writeFile" access="private" returntype="boolean" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfargument name="head" type="any" required="yes">
		<cfargument name="data" type="any" required="yes">
		<cfargument name="mode" type="string" required="no" default="wb">
		<cfset var ok = true>
		<cfset var raw = "">
		<cfset var out = "">

		<cftry>
			<cflock name="ColdIgniterCache#md5(arguments.path)#" type="exclusive" timeout="10">
				<cfset raw = CreateObject("java", "java.io.FileOutputStream").init(arguments.path)>

				<!---
				 There is no finally: the file is closed in both ways out.
				 A file with a part of the value (a component inside it
				 cannot be written) is of no use, so it is deleted.
				--->
				<cftry>
					<cfset out = CreateObject("java", "java.io.ObjectOutputStream").init(
						CreateObject("java", "java.io.BufferedOutputStream").init(raw)
					)>
					<cfset out.writeObject(arguments.head)>
					<cfset out.writeObject(arguments.data)>
					<cfset out.close()>

					<cfcatch type="any">
						<cfset raw.close()>
						<cfset CreateObject("java", "java.io.File").init(arguments.path).delete()>
						<cfrethrow>
					</cfcatch>
				</cftry>
			</cflock>

			<cfcatch type="any">
				<cfset ok = false>
			</cfcatch>
		</cftry>

		<!--- Difference: the item of the map in the application scope is out of date --->
		<cfset forget(arguments.path)>

		<cfreturn ok>
	</cffunction>

	<!---
	 * Difference: not in the original. Whether the item has expired.
	 *
	 * @param head A map with time and ttl
	--->
	<cffunction name="isExpired" access="private" returntype="boolean" output="no">
		<cfargument name="head" type="any" required="yes">

		<cfreturn Val(arguments.head["ttl"]) GT 0 AND time() GT Val(arguments.head["time"]) + Val(arguments.head["ttl"])>
	</cffunction>

	<!---
	 * Difference: not in the original. Opens the map of the items in the
	 * application scope, which the front controller has switched on.
	 *
	 * The map is a synchronized java.util.HashMap (the Java of the server has
	 * no ConcurrentHashMap), kept in application.ColdIgniter, the struct of
	 * this framework in the scope. The application is named after the root
	 * path of the site. A scope that can not be used (the flag
	 * request.ColdIgniterApplication) or any failure switches the map off
	 * for the request.
	 *
	 * @return The map, or an empty string when it is off
	--->
	<cffunction name="getMemory" access="private" returntype="any" output="no">
		<cfif this.pageMemoryReady>
			<cfreturn this.pageMemory>
		</cfif>

		<cfset this.pageMemoryReady = true>

		<cfif this.memoryEntries LTE 0>
			<cfreturn this.pageMemory>
		</cfif>

		<cftry>
			<!--- the front controller (public/index.cfm) switches the scope on and sets the flag --->
			<cfif NOT StructKeyExists(request, "ColdIgniterApplication") OR NOT request.ColdIgniterApplication>
				<cfset this.pageMemory = "">

				<cfreturn this.pageMemory>
			</cfif>

			<cfif NOT StructKeyExists(application, "ColdIgniter") OR NOT StructKeyExists(application.ColdIgniter, "pageMemory")>
				<cflock scope="application" type="exclusive" timeout="10">
					<cfif NOT StructKeyExists(application, "ColdIgniter")>
						<cfset application.ColdIgniter = StructNew()>
					</cfif>

					<cfif NOT StructKeyExists(application.ColdIgniter, "pageMemory")>
						<cfset application.ColdIgniter.pageMemory = CreateObject("java", "java.util.Collections").synchronizedMap(
							CreateObject("java", "java.util.HashMap").init()
						)>
					</cfif>
				</cflock>
			</cfif>

			<cfset this.pageMemory = application.ColdIgniter.pageMemory>

			<cfcatch type="any">
				<cfset this.pageMemory = "">
			</cfcatch>
		</cftry>

		<cfreturn this.pageMemory>
	</cffunction>

	<!---
	 * Difference: not in the original. Keeps an item in the map, and makes
	 * room by dropping one when the map is full.
	 *
	 * @param modified The modified time of the file, taken before it was read
	--->
	<cffunction name="remember" access="private" returntype="void" output="no">
		<cfargument name="memory" type="any" required="yes">
		<cfargument name="path" type="string" required="yes">
		<cfargument name="file_" type="any" required="yes">
		<cfargument name="modified" type="numeric" required="yes">
		<cfargument name="item" type="any" required="yes">
		<cfset var entry = CreateObject("java", "java.util.HashMap").init()>
		<cfset var evicted = "">

		<cfif arguments.memory.size() GTE this.memoryEntries AND NOT arguments.memory.containsKey(arguments.path)>
			<cftry>
				<!---
				 * The entry that goes is switched off, as forget() does: a
				 * page of the front controller may still hold it, and
				 * forget() does not find it here any more.
				--->
				<cfset evicted = arguments.memory.remove(arguments.memory.keySet().iterator().next())>

				<cfif IsDefined("evicted") AND NOT IsSimpleValue(evicted)>
					<cfset evicted.put("modified", -1)>
				</cfif>

				<cfcatch type="any">
					<!--- as clean() does: the entries cannot be switched off one by one --->
					<cfset arguments.memory.clear()>

					<cfif StructKeyExists(application.ColdIgniter, "frontPages")>
						<cfset application.ColdIgniter.frontPages.clear()>
					</cfif>
				</cfcatch>
			</cftry>
		</cfif>

		<cfset entry.put("file", arguments.file_)>
		<cfset entry.put("modified", arguments.modified)>
		<cfset entry.put("item", arguments.item)>

		<cfset arguments.memory.put(arguments.path, entry)>

		<cfset this.sharedEntry = entry>
	</cffunction>

	<!---
	 * Difference: not in the original. Drops an item of the map in the
	 * application scope, or all of them when the path is empty.
	 *
	 * The front controller can hold the entry of a page too (see
	 * Cache/FrontPage.cfm). A dropped entry gets a modified time that no
	 * file has, so it is not served from there any more.
	--->
	<cffunction name="forget" access="private" returntype="void" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfset var memory = getMemory()>
		<cfset var entry = "">

		<cfif IsSimpleValue(memory)>
			<cfreturn>
		</cfif>

		<cfif Compare(arguments.path, "") EQ 0>
			<cfset memory.clear()>

			<cfif StructKeyExists(application.ColdIgniter, "frontPages")>
				<cfset application.ColdIgniter.frontPages.clear()>
			</cfif>
		<cfelse>
			<cfset entry = memory.remove(arguments.path)>

			<cfif IsDefined("entry") AND IsStruct(entry)>
				<cfset entry.put("modified", -1)>
			</cfif>
		</cfif>
	</cffunction>

	<!---
	 * Deletes all files contained in the supplied directory path.
	 * Files must be writable or owned by the system in order to be deleted.
	 * If the second parameter is set to TRUE, any directories contained
	 * within the supplied base directory will be nuked as well.
	 *
	 * @param path    File path
	 * @param delDir  Whether to delete any directories found in the path
	 * @param htdocs  Whether to skip deleting .htaccess and index page files
	 * @param level   Internal variable to determine recursion status - do not use in calls
	--->
	<cffunction name="deleteFiles" access="private" returntype="boolean" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfargument name="delDir" type="boolean" required="no" default="false">
		<cfargument name="htdocs" type="boolean" required="no" default="false">
		<cfargument name="level_" type="numeric" required="no" default="0">
		<cfset var directory = "">
		<cfset var files = "">
		<cfset var i = 0>
		<cfset var filename = "">
		<cfset var entry = "">
		<cfset var dirPath = arguments.path>

		<!--- Trim the trailing slash --->
		<cfloop condition="Len(dirPath) GT 0 AND (Compare(Right(dirPath, 1), '/') EQ 0 OR Compare(Right(dirPath, 1), '\') EQ 0)">
			<cfset dirPath = Left(dirPath, Len(dirPath) - 1)>
		</cfloop>

		<cfset directory = CreateObject("java", "java.io.File").init(dirPath)>

		<cfif NOT directory.isDirectory()>
			<cfreturn false>
		</cfif>

		<cfset files = directory.list()>

		<cfif NOT IsDefined("files")>
			<cfreturn false>
		</cfif>

		<cfloop index="i" from="1" to="#ArrayLen(files)#">
			<cfset filename = files[i]>
			<cfset entry = CreateObject("java", "java.io.File").init(dirPath & "/" & filename)>

			<cfif entry.isDirectory() AND Compare(Left(filename, 1), ".") NEQ 0>
				<cfset deleteFiles(dirPath & "/" & filename, arguments.delDir, arguments.htdocs, arguments.level_ + 1)>
			<cfelseif entry.isFile() AND (NOT arguments.htdocs OR NOT CreateObject("java", "java.lang.String").init(LCase(filename)).matches("\.htaccess|index\.(html|htm)|web\.config"))>
				<!--- a folder is left, as unlink() of the original fails on one --->
				<cflock name="ColdIgniterCache#md5(dirPath & '/' & filename)#" type="exclusive" timeout="10">
					<cfset entry.delete()>
				</cflock>
			</cfif>
		</cfloop>

		<cfif arguments.delDir AND arguments.level_ GT 0>
			<cfreturn directory.delete()>
		</cfif>

		<cfreturn true>
	</cffunction>

	<!---
	 * Reads the specified directory and builds a map containing the filenames,
	 * filesize, dates, and permissions
	 *
	 * Any sub-folders contained within the specified path are read as well.
	 *
	 * @param sourceDir    Path to source
	 * @param topLevelOnly Look only at the top level directory specified?
	 * @param recursion_   Internal variable to determine recursion status - do not use in calls
	 *
	 * @return A map of filename -> {name, server_path, size, date, relative_path}
	--->
	<cffunction name="getDirFileInfo" access="private" returntype="any" output="no">
		<cfargument name="sourceDir" type="string" required="yes">
		<cfargument name="topLevelOnly" type="boolean" required="no" default="true">
		<cfargument name="fileData_" type="any" required="no" default="">
		<cfset var relativePath = arguments.sourceDir>
		<cfset var fileData = arguments.fileData_>
		<cfset var directory = "">
		<cfset var files = "">
		<cfset var i = 0>
		<cfset var file_ = "">
		<cfset var info = "">
		<cfset var dirPath = arguments.sourceDir>

		<!--- reset the map and make sure sourceDir has a trailing slash on the initial call --->
		<cfif NOT IsStruct(fileData)>
			<cfset fileData = CreateObject("java", "java.util.LinkedHashMap").init()>

			<cfloop condition="Len(dirPath) GT 0 AND (Compare(Right(dirPath, 1), '/') EQ 0 OR Compare(Right(dirPath, 1), '\') EQ 0)">
				<cfset dirPath = Left(dirPath, Len(dirPath) - 1)>
			</cfloop>

			<cfset dirPath = dirPath & "/">
		</cfif>

		<cfset directory = CreateObject("java", "java.io.File").init(dirPath)>

		<cfif NOT directory.isDirectory()>
			<cfreturn CreateObject("java", "java.util.LinkedHashMap").init()>
		</cfif>

		<cfset files = directory.list()>

		<cfif NOT IsDefined("files")>
			<cfreturn CreateObject("java", "java.util.LinkedHashMap").init()>
		</cfif>

		<cfloop index="i" from="1" to="#ArrayLen(files)#">
			<cfset file_ = CreateObject("java", "java.io.File").init(dirPath & files[i])>

			<cfif file_.isDirectory() AND Compare(Left(files[i], 1), ".") NEQ 0 AND NOT arguments.topLevelOnly>
				<cfset getDirFileInfo(dirPath & files[i] & "/", arguments.topLevelOnly, fileData)>
			<cfelseif Compare(Left(files[i], 1), ".") NEQ 0>
				<cfset info = getFileInfo(dirPath & files[i])>

				<cfif IsStruct(info)>
					<cfset info.put("relative_path", relativePath)>
					<cfset fileData.put(files[i], info)>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn fileData>
	</cffunction>

	<!---
	 * Get File Info
	 *
	 * Given a file and path, returns the name, path, size, date modified
	 *
	 * Difference: the second argument of the original (the values to
	 * return) is not ported, the four values name, server_path, size and
	 * date are always returned. Returns false when the file cannot be
	 * found, where the original returns null.
	 *
	 * @param file_ Path to file
	--->
	<cffunction name="getFileInfo" access="private" returntype="any" output="no">
		<cfargument name="file_" type="string" required="yes">
		<cfset var handle = CreateObject("java", "java.io.File").init(arguments.file_)>
		<cfset var info = "">

		<cfif NOT handle.isFile()>
			<cfreturn false>
		</cfif>

		<cfset info = CreateObject("java", "java.util.LinkedHashMap").init()>

		<cfset info.put("name", handle.getName())>
		<cfset info.put("server_path", arguments.file_)>
		<cfset info.put("size", handle.length())>
		<cfset info.put("date", Int(handle.lastModified() / 1000))>

		<cfreturn info>
	</cffunction>

</cfcomponent>
