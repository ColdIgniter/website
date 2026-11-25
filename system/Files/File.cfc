<!---
 * Wrapper for a file on disk, with goodies.
 *
 * Difference: the original extends SplFileInfo, which has no counterpart
 * here, so the parts of it that File and UploadedFile use are written out:
 * getPathname(), __toString(), getFilename(), getBasename(), getExtension(),
 * getRealPath() and the file size. getRealPath() gives an empty string, not
 * false, for a file that does not exist.
 *
 * Difference: client-supplied, not trusted. There is no fileinfo extension,
 * so getMimeType() gives the type the file came with (what the original does
 * when finfo_open() is missing), or application/octet-stream. For an uploaded
 * file that is the type the client sent. Config\Mimes is only used to guess
 * the extension from that type.
 *
 * Difference: a file is moved with cffile action="move" (a rename does not
 * cross a volume), and the permissions are not set, as they follow the
 * folder on the server.
 *
 * Not ported yet: getSizeByBinaryUnit(), getSizeByMetricUnit() and
 * getSizeByUnit() (the FileSizeUnit enum).
--->
<cfcomponent output="no" hint="Wrapper for a file, with goodies">

	<!---
	 * The files size in bytes
	 *
	 * @var false|int|null
	--->
	<cfset this.size = "">

	<!---
	 * @var string|null
	--->
	<cfset this.originalMimeType = "">

	<!---
	 * The path of the file, which SplFileInfo keeps in the original.
	 *
	 * @var string
	--->
	<cfset this.pathName = "">

	<!---
	 * Run our constructor with an optional verification
	 * that the path is really a file.
	 *
	 * @throws FileNotFoundException
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfargument name="checkFile" type="boolean" required="no" default="false">

		<cfif arguments.checkFile AND NOT is_file(arguments.path)>
			<cfset static_("ColdIgniter\Files\Exceptions\FileNotFoundException").forFileNotFound(arguments.path)>
		</cfif>

		<cfset this.pathName = arguments.path>

		<cfreturn this>
	</cffunction>

	<!---
	 * The path of the file, as it was given.
	--->
	<cffunction name="getPathname" access="public" returntype="string" output="no">
		<cfreturn this.pathName>
	</cffunction>

	<!---
	 * The path of the file, as it was given.
	--->
	<cffunction name="__toString" access="public" returntype="string" output="no">
		<cfreturn this.pathName>
	</cffunction>

	<!---
	 * The name of the file, with the extension.
	--->
	<cffunction name="getFilename" access="public" returntype="string" output="no">
		<cfreturn basename(this.pathName)>
	</cffunction>

	<!---
	 * The base name of the file, without the suffix when it is given.
	--->
	<cffunction name="getBasename" access="public" returntype="string" output="no">
		<cfargument name="suffix" type="string" required="no" default="">

		<cfreturn basename(this.pathName, arguments.suffix)>
	</cffunction>

	<!---
	 * The extension of the file, without the dot, or an empty string.
	--->
	<cffunction name="getExtension" access="public" returntype="string" output="no">
		<cfset var name = basename(this.pathName)>
		<cfset var position = Find(".", Reverse(name))>

		<cfif position EQ 0>
			<cfreturn "">
		</cfif>

		<!--- Difference: a name that ends in a dot has the extension "", and Right() cannot take 0 --->
		<cfif position EQ 1>
			<cfreturn "">
		</cfif>

		<cfreturn Right(name, position - 1)>
	</cffunction>

	<!---
	 * The canonical path of the file, or an empty string (false) when it
	 * does not exist.
	--->
	<cffunction name="getRealPath" access="public" returntype="string" output="no">
		<cfreturn realpath(this.pathName)>
	</cffunction>

	<!---
	 * Retrieve the file size.
	 *
	 * Implementations SHOULD return the value stored in the "size" key of
	 * the file in the files array if available, as the server calculates
	 * this based on the actual size transmitted.
	 *
	 * @throws RuntimeException if the file does not exist or an error occurs
	--->
	<cffunction name="getSize" access="public" returntype="any" output="no">
		<cfset var file = "">

		<cfif is_null(this.size)>
			<cfset file = CreateObject("java", "java.io.File").init(JavaCast("string", this.pathName))>

			<cfif NOT file.isFile()>
				<cfthrow type="ColdIgniter.RuntimeException" message="SplFileInfo::getSize(): stat failed for #this.pathName#">
			</cfif>

			<cfset this.size = file.length()>
		</cfif>

		<cfreturn this.size>
	</cffunction>

	<!---
	 * Attempts to determine the file extension based on the trusted
	 * getType() method. If the mime type is unknown, will return an empty
	 * string (null).
	--->
	<cffunction name="guessExtension" access="public" returntype="string" output="no">
		<!--- naively get the path extension --->
		<cfset var proposedExtension = getExtension()>

		<cfreturn static_("Config\Mimes").guessExtensionFromType(getMimeType(), proposedExtension)>
	</cffunction>

	<!---
	 * Retrieve the media type of the file. SHOULD not use information from
	 * the files array, but should use other methods to more accurately
	 * determine the type of file, like finfo, or mime_content_type().
	 *
	 * @return The media type we determined it to be.
	--->
	<cffunction name="getMimeType" access="public" returntype="string" output="no">
		<!--- Not ported yet: finfo_file(), there is no fileinfo extension. --->
		<cfif is_null(this.originalMimeType)>
			<cfreturn "application/octet-stream">
		</cfif>

		<cfreturn this.originalMimeType>
	</cffunction>

	<!---
	 * Generates a random names based on a simple hash and the time, with
	 * the correct file extension attached.
	--->
	<cffunction name="getRandomName" access="public" returntype="string" output="no">
		<cfset var extension = getExtension()>

		<cfif extension NEQ "">
			<cfset extension = "." & extension>
		</cfif>

		<cfreturn time() & "_" & bin2hex(random_bytes(10)) & extension>
	</cffunction>

	<!---
	 * Moves a file to a new location.
	 *
	 * @return File
	--->
	<cffunction name="move" access="public" returntype="any" output="no">
		<cfargument name="targetPath" type="string" required="yes">
		<cfargument name="name" type="any" required="no" default="">
		<cfargument name="overwrite" type="boolean" required="no" default="false">
		<cfset var destination = "">
		<cfset var oldName = "">
		<cfset var target = "">

		<cfset arguments.targetPath = rtrim_(arguments.targetPath, "/") & "/">

		<cfif is_null(arguments.name)>
			<cfset arguments.name = getBasename()>
		</cfif>

		<cfif arguments.overwrite>
			<cfset destination = arguments.targetPath & arguments.name>
		<cfelse>
			<cfset destination = getDestination(arguments.targetPath & arguments.name)>
		</cfif>

		<cfset oldName = getRealPath()>

		<cfif oldName EQ "">
			<cfset oldName = this.pathName>
		</cfif>

		<cftry>
			<cfif arguments.overwrite>
				<cfset target = CreateObject("java", "java.io.File").init(JavaCast("string", destination))>

				<cfif target.isFile()>
					<cfset target.delete()>
				</cfif>
			</cfif>

			<cffile action="move" source="#oldName#" destination="#destination#">

			<cfcatch type="any">
				<cfset static_("ColdIgniter\Files\Exceptions\FileException").forUnableToMove(getBasename(), arguments.targetPath, strip_tags(cfcatch.message))>
			</cfcatch>
		</cftry>

		<cfreturn new_("ColdIgniter\Files\File", destination)>
	</cffunction>

	<!---
	 * Returns the destination path for the move operation where overwriting is not expected.
	 *
	 * First, it checks whether the delimiter is present in the filename, if it is, then it checks whether the
	 * last element is an integer as there may be cases that the delimiter may be present in the filename.
	 * For the all other cases, it appends an integer starting from zero before the file's extension.
	--->
	<cffunction name="getDestination" access="public" returntype="string" output="no">
		<cfargument name="destination" type="string" required="yes">
		<cfargument name="delimiter" type="string" required="no" default="_">
		<cfargument name="i" type="numeric" required="no" default="0">
		<cfset var dirname = "">
		<cfset var base = "">
		<cfset var extension = "">
		<cfset var filename = "">
		<cfset var parts = "">
		<cfset var last = "">
		<cfset var slash = 0>
		<cfset var position = 0>

		<cfif arguments.delimiter EQ "">
			<cfset arguments.delimiter = "_">
		</cfif>

		<cfloop condition="is_file(arguments.destination)">
			<!--- pathinfo(): the directory, the file name and the extension --->
			<cfset base = basename(arguments.destination)>
			<cfset slash = Len(arguments.destination) - Len(base)>
			<cfset dirname = ".">

			<cfif slash GT 1>
				<cfset dirname = Left(arguments.destination, slash - 1)>
			<cfelseif slash EQ 1>
				<cfset dirname = Left(arguments.destination, 1)>
			</cfif>

			<cfset position = Find(".", Reverse(base))>
			<cfset extension = "">
			<cfset filename = base>

			<cfif position GT 0>
				<!--- Difference: Right() cannot take 0, so a name that ends in a dot has the extension "." --->
				<cfif position EQ 1>
					<cfset extension = ".">
				<cfelse>
					<cfset extension = "." & Right(base, position - 1)>
				</cfif>

				<!--- Difference: Left() cannot take 0, so a dotfile has the filename "" --->
				<cfif Len(base) GT position>
					<cfset filename = Left(base, Len(base) - position)>
				<cfelse>
					<cfset filename = "">
				</cfif>
			</cfif>

			<cfif Find(arguments.delimiter, filename) GT 0>
				<cfset parts = explode(arguments.delimiter, filename)>
				<cfset last = parts[ArrayLen(parts)]>

				<cfif is_numeric(last)>
					<cfset arguments.i = last>
					<cfset ArrayDeleteAt(parts, ArrayLen(parts))>
					<cfset arguments.i = arguments.i + 1>
					<cfset ArrayAppend(parts, arguments.i)>
					<cfset arguments.destination = dirname & request.DIRECTORY_SEPARATOR & implode(arguments.delimiter, parts) & extension>
				<cfelse>
					<cfset arguments.i = arguments.i + 1>
					<cfset arguments.destination = dirname & request.DIRECTORY_SEPARATOR & filename & arguments.delimiter & arguments.i & extension>
				</cfif>
			<cfelse>
				<cfset arguments.i = arguments.i + 1>
				<cfset arguments.destination = dirname & request.DIRECTORY_SEPARATOR & filename & arguments.delimiter & arguments.i & extension>
			</cfif>
		</cfloop>

		<cfreturn arguments.destination>
	</cffunction>

</cfcomponent>
