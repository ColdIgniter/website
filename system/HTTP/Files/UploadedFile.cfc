<!---
 * Value object representing a single file uploaded through an
 * HTTP request. Used by the IncomingRequest class to
 * provide files.
 *
 * Difference: the web server of the original moves a file with
 * move_uploaded_file(), which only moves a file it received. Here the file
 * is a temp file of the engine, kept by the files array (see
 * Superglobals.readFiles()), and isValid() asks the list of the upload
 * paths of the request, request.ColdIgniter.uploads, which only that
 * method fills. A file made by hand, such as a test makes, is not valid
 * until its path is put in that list.
 *
 * Difference: the original extends File and implements UploadedFileInterface;
 * only the first is possible, so this component takes File as its parent and
 * UploadedFileInterface is a list of methods.
 *
 * Difference: a name that move() takes from the client is cleaned of a colon
 * too (an alternate data stream on NTFS), and a name that is then empty, a
 * dot or two dots gets a random name. A name given to move() may hold a
 * folder, but the destination must stay inside the target path (checked on
 * the canonical paths), else the invalid file exception is thrown.
 *
 * Difference: setPath() is private (protected in the original), as nothing
 * outside this component calls it.
 *
 * Difference: the media type is the one the client sent (see File), so
 * guessExtension(), getExtension() and with them the random name of store()
 * come from the client type and the client extension, as upstream does when
 * the file is not read: Mimes.guessExtensionFromType(clientType, clientExt),
 * else the client extension. Do not trust either.
 *
 * Difference: the chmod after a move is not done.
--->
<cfcomponent output="no" parent="ColdIgniter\Files\File" hint="Value object representing a single file uploaded through an HTTP request">

	<!---
	 * The path to the temporary file.
	 *
	 * @var string
	--->
	<cfset this.path = "">

	<!---
	 * The original filename as provided by the client.
	 *
	 * @var string
	--->
	<cfset this.originalName = "">

	<!---
	 * The filename given to the file during upload.
	 *
	 * @var string
	--->
	<cfset this.name = "">

	<!---
	 * The path as provided by the client during upload (the full_path
	 * key of the files array).
	 *
	 * @var string|null
	--->
	<cfset this.clientPath = "">

	<!---
	 * The type of error that occurred.
	 *
	 * @var int|null
	--->
	<cfset this.error = "">

	<!---
	 * Whether the file has been moved already or not.
	 *
	 * Named with an underscore, because hasMoved() is a method.
	 *
	 * @var bool
	--->
	<cfset this.hasMoved_ = false>

	<!---
	 * Accepts the file information as would be filled in from the files array.
	 *
	 * @param path         The temporary location of the uploaded file.
	 * @param originalName The client name of the file.
	 * @param mimeType     The type of file as provided by the client.
	 * @param size         The size of the file, in bytes.
	 * @param error        The error constant of the upload (one of the 0 to 8 values).
	 * @param clientPath   The webkit relative path of the uploaded file.
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="path" type="string" required="no" default="">
		<cfargument name="originalName" type="string" required="no" default="">
		<cfargument name="mimeType" type="any" required="no" default="">
		<cfargument name="size" type="any" required="no" default="">
		<cfargument name="error" type="any" required="no" default="">
		<cfargument name="clientPath" type="any" required="no" default="">

		<cfset this.path = arguments.path>
		<cfset this.name = arguments.originalName>
		<cfset this.originalName = arguments.originalName>
		<cfset this.originalMimeType = arguments.mimeType>
		<cfset this.size = arguments.size>
		<cfset this.error = arguments.error>
		<cfset this.clientPath = arguments.clientPath>

		<cfset parent.__construct(arguments.path, false)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Move the uploaded file to a new location.
	 *
	 * $targetPath may be an absolute path, or a relative path. If it is a
	 * relative path, resolution should be the same as used by CFML's rename()
	 * function.
	 *
	 * After the move, getName() and getTempName() reflect the new location.
	 *
	 * @param targetPath The target directory to move the file to
	 * @param name       The name to rename the file to, or an empty string (null) for the cleaned client name
	 * @param overwrite  State for indicating whether to overwrite the previously generated file with the same
	 *                   name or not.
	 *
	 * @return bool
	 *
	 * @throws HTTPException
	--->
	<cffunction name="move" access="public" returntype="any" output="no">
		<cfargument name="targetPath" type="string" required="yes">
		<cfargument name="name" type="any" required="no" default="">
		<cfargument name="overwrite" type="boolean" required="no" default="false">
		<cfset var destination = "">
		<cfset var target = "">
		<cfset var message = "">
		<cfset var base = "">
		<cfset var parent = "">

		<cfset arguments.targetPath = rtrim_(arguments.targetPath, "/") & "/">
		<cfset arguments.targetPath = setPath(arguments.targetPath)><!--- set the target path --->

		<cfif this.hasMoved_>
			<cfset static_("ColdIgniter\HTTP\Exceptions\HTTPException").forAlreadyMoved()>
		</cfif>

		<cfif NOT isValid()>
			<cfset static_("ColdIgniter\HTTP\Exceptions\HTTPException").forInvalidFile()>
		</cfif>

		<cfif is_null(arguments.name)>
			<cfset helper("security")>
			<cfset arguments.name = Replace(sanitize_filename(getName()), ":", "", "all")>

			<cfif ListFind(".,..", Trim(arguments.name)) GT 0 OR Trim(arguments.name) EQ "">
				<cfset arguments.name = getRandomName()>
			</cfif>
		</cfif>

		<cfif arguments.overwrite>
			<cfset destination = arguments.targetPath & arguments.name>
		<cfelse>
			<cfset destination = getDestination(arguments.targetPath & arguments.name)>
		</cfif>

		<!---
		 Difference: the destination must be inside the target path, whatever
		 the name holds (a "..", a trailing dot or space): the canonical
		 folder of the destination is the canonical target path or below it,
		 compared without regard to case, with a separator at the boundary.
		--->
		<cfset base = LCase(CreateObject("java", "java.io.File").init(JavaCast("string", arguments.targetPath)).getCanonicalPath() & "")>
		<cfset parent = LCase(CreateObject("java", "java.io.File").init(JavaCast("string", destination)).getCanonicalFile().getParentFile().getPath() & "")>

		<cfif Compare(parent, base) NEQ 0 AND Compare(Left(parent, Len(base) + 1), base & request.DIRECTORY_SEPARATOR) NEQ 0>
			<cfset static_("ColdIgniter\HTTP\Exceptions\HTTPException").forInvalidFile()>
		</cfif>

		<cftry>
			<cfif arguments.overwrite>
				<cfset target = CreateObject("java", "java.io.File").init(JavaCast("string", destination))>

				<cfif target.isFile()>
					<cfset target.delete()>
				</cfif>
			</cfif>

			<cffile action="move" source="#this.path#" destination="#destination#">

			<cfset this.hasMoved_ = true>

			<cfcatch type="any">
				<cfset message = strip_tags(cfcatch.message)>

				<cfset static_("ColdIgniter\HTTP\Exceptions\HTTPException").forMoveFailed(basename(this.path), arguments.targetPath, message)>
			</cfcatch>
		</cftry>

		<!--- Success, so store our new information --->
		<cfset this.path = arguments.targetPath>
		<cfset this.name = basename(destination)>

		<cfreturn true>
	</cffunction>

	<!---
	 * create file target path if
	 * the set path does not exist
	 *
	 * @return The path set or created.
	--->
	<cffunction name="setPath" access="private" returntype="string" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfset var directory = CreateObject("java", "java.io.File").init(JavaCast("string", arguments.path))>

		<cfif NOT directory.isDirectory()>
			<cfif NOT directory.mkdirs()>
				<cfset static_("ColdIgniter\HTTP\Exceptions\HTTPException").forMoveFailed(basename(this.path), arguments.path, "unable to create the directory")>
			</cfif>

			<!--- create the index.html file --->
			<cfif NOT is_file(arguments.path & "index.html")>
				<cffile action="write" file="#arguments.path#index.html" output="" addnewline="no" charset="utf-8">
			</cfif>
		</cfif>

		<cfreturn arguments.path>
	</cffunction>

	<!---
	 * Returns whether the file has been moved or not. If it has,
	 * the move() method will not work and certain properties, like
	 * the tempName, will no longer be available.
	--->
	<cffunction name="hasMoved" access="public" returntype="boolean" output="no">
		<cfreturn this.hasMoved_>
	</cffunction>

	<!---
	 * Retrieve the error associated with the uploaded file.
	 *
	 * The return value will be one of the upload error constants (0 to 8,
	 * the UPLOAD_ERR_* values).
	 *
	 * If the file was uploaded successfully, this method will return 0.
	 *
	 * Difference: the engine reports no error code of its own, so a file
	 * of the files array that Superglobals makes always has the error 0 (a
	 * file that could not be saved gets no entry). The other codes are for
	 * a file made by hand, as a test does.
	--->
	<cffunction name="getError" access="public" returntype="numeric" output="no">
		<cfif is_null(this.error)>
			<cfreturn 0>
		</cfif>

		<cfreturn this.error>
	</cffunction>

	<!---
	 * Get error string
	--->
	<cffunction name="getErrorString" access="public" returntype="string" output="no">
		<cfset var error = getError()>
		<cfset var key = "uploadErrUnknown">

		<cfswitch expression="#error#">
			<cfcase value="0"><cfset key = "uploadErrOk"></cfcase>
			<cfcase value="1"><cfset key = "uploadErrIniSize"></cfcase>
			<cfcase value="2"><cfset key = "uploadErrFormSize"></cfcase>
			<cfcase value="3"><cfset key = "uploadErrPartial"></cfcase>
			<cfcase value="4"><cfset key = "uploadErrNoFile"></cfcase>
			<cfcase value="7"><cfset key = "uploadErrCantWrite"></cfcase>
			<cfcase value="6"><cfset key = "uploadErrNoTmpDir"></cfcase>
			<cfcase value="8"><cfset key = "uploadErrExtension"></cfcase>
		</cfswitch>

		<!--- sprintf() with the one %s of the line --->
		<cfreturn Replace(lang("HTTP." & key), "%s", getName(), "all")>
	</cffunction>

	<!---
	 * Returns the mime type as provided by the client.
	 * This is NOT a trusted value.
	 * For a trusted version, use getMimeType() instead.
	 *
	 * @return The media type sent by the client or an empty string (null) if none was provided.
	--->
	<cffunction name="getClientMimeType" access="public" returntype="string" output="no">
		<cfreturn this.originalMimeType>
	</cffunction>

	<!---
	 * Gets the temporary filename where the file was uploaded to.
	 *
	 * @return string
	--->
	<cffunction name="getName" access="public" returntype="string" output="no">
		<cfreturn this.name>
	</cffunction>

	<!---
	 * Returns the original file name as provided by the client.
	 *
	 * @return string
	--->
	<cffunction name="getClientName" access="public" returntype="string" output="no">
		<cfreturn this.originalName>
	</cffunction>

	<!---
	 * Returns the client path as provided by the client during upload.
	 *
	 * This is the value of the "full_path" key of the files array. It may be
	 * different from getClientName() when the client uploads a folder.
	 *
	 * @return The client path, or an empty string (null) if it was not available
	--->
	<cffunction name="getClientPath" access="public" returntype="string" output="no">
		<cfreturn this.clientPath>
	</cffunction>

	<!---
	 * Gets the temporary filename where the file was uploaded to.
	 *
	 * @return string
	--->
	<cffunction name="getTempName" access="public" returntype="string" output="no">
		<cfreturn this.path>
	</cffunction>

	<!---
	 * Overrides SPLFileInfo's to work with uploaded files, since the temp file
	 * has no extension.
	 *
	 * Uses the mime type to guess the extension and falls back to the client
	 * extension.
	 *
	 * @return string
	--->
	<cffunction name="getExtension" access="public" returntype="string" output="no">
		<cfset var guessExtension_ = guessExtension()>

		<cfif guessExtension_ NEQ "">
			<cfreturn guessExtension_>
		</cfif>

		<cfreturn getClientExtension()>
	</cffunction>

	<!---
	 * Attempts to determine the best file extension.
	 *
	 * @return string
	--->
	<cffunction name="guessExtension" access="public" returntype="string" output="no">
		<cfreturn static_("Config\Mimes").guessExtensionFromType(getMimeType(), getClientExtension())>
	</cffunction>

	<!---
	 * Returns only the file extension from the original name. This is not
	 * a trusted value.
	 *
	 * @return string
	--->
	<cffunction name="getClientExtension" access="public" returntype="string" output="no">
		<cfset var base = basename(this.originalName)>
		<cfset var position = Find(".", Reverse(base))>

		<cfif position EQ 0>
			<cfreturn "">
		</cfif>

		<!--- Difference: a name that ends in a dot has the extension "", and Right() cannot take 0 --->
		<cfif position EQ 1>
			<cfreturn "">
		</cfif>

		<cfreturn Right(base, position - 1)>
	</cffunction>

	<!---
	 * Returns whether the file was uploaded successfully, based on whether
	 * it was uploaded via HTTP and has no errors.
	 *
	 * Difference: is_uploaded_file() is the list request.ColdIgniter.uploads
	 * (see the head of this file), and the error has to be a given 0.
	--->
	<cffunction name="isValid" access="public" returntype="boolean" output="no">
		<cfif NOT StructKeyExists(request.ColdIgniter, "uploads") OR this.path EQ "">
			<cfreturn false>
		</cfif>

		<cfif NOT StructKeyExists(request.ColdIgniter.uploads, LCase(this.path))>
			<cfreturn false>
		</cfif>

		<cfreturn NOT is_null(this.error) AND this.error EQ 0>
	</cffunction>

	<!---
	 * Save the uploaded file to a new location.
	 *
	 * By default, upload files are saved in writable/uploads directory. The YYYYMMDD folder
	 * and random file name will be created.
	 *
	 * @param folderName The folder name to store the file in, or an empty string (null) for the date
	 * @param fileName   The name to rename the file to, or an empty string (null) for a random name
	 *
	 * @return string file full path
	--->
	<cffunction name="store" access="public" returntype="string" output="no">
		<cfargument name="folderName" type="any" required="no" default="">
		<cfargument name="fileName" type="any" required="no" default="">

		<cfif is_null(arguments.folderName)>
			<cfset arguments.folderName = date("Ymd")>
		</cfif>

		<cfset arguments.folderName = rtrim_(arguments.folderName, "/") & "/">

		<cfif is_null(arguments.fileName)>
			<cfset arguments.fileName = getRandomName()>
		</cfif>

		<!--- Move the uploaded file to a new location. --->
		<cfset move(request.WRITEPATH & "uploads/" & arguments.folderName, arguments.fileName)>

		<cfreturn arguments.folderName & this.name>
	</cffunction>

</cfcomponent>
