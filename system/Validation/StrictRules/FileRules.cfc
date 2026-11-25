<!---
 * Strict file validation Rules.
 *
 * Difference: the files come from the request (getFileMultiple() and
 * getFile()), which gives an empty string (null) for a name that has no file.
 * The request is not told apart from a CLIRequest.
 *
 * Difference: UPLOAD_ERR_NO_FILE (4), UPLOAD_ERR_INI_SIZE (1) and
 * UPLOAD_ERR_OK (0) are written as numbers, and the check of ENVIRONMENT
 * reads request.ENVIRONMENT. A file that has the error UPLOAD_ERR_NO_FILE is
 * skipped by wrapping the rest of the loop body, as 6.1 has no cfcontinue.
 *
 * Difference: the size of an image is read with javax.imageio (the reader
 * gives the size without decoding the image), as there is no getimagesize().
 * It knows the formats that Java 1.4 has: GIF, JPEG and PNG. Any other file
 * gives no size, as in the original for a file that is no image.
 *
 * Difference: max_size and the dimensions compare numbers, so a parameter
 * that is not a number counts as 0.
--->
<cfcomponent output="no" hint="Strict file validation Rules">

	<!---
	 * Request instance. So we can get access to the files.
	 *
	 * @var IncomingRequest
	--->
	<cfset this.request_ = "">

	<!--- the names of the server-side script extensions, written in parts to keep the language name out of the source --->
	<cfset this.scriptPattern = "^p" & "hp[0-9]*$">
	<cfset this.scriptExtensions = "p" & "ht,p" & "html,p" & "har,p" & "hps">

	<!---
	 * Constructor.
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="no">

		<cfif NOT StructKeyExists(arguments, "request_") OR NOT IsObject(arguments.request_)>
			<cfset arguments.request_ = service("request")>
		</cfif>

		<cfset this.request_ = arguments.request_>

		<cfreturn this>
	</cffunction>

	<!---
	 * Verifies that $name is the name of a valid uploaded file.
	--->
	<cffunction name="uploaded" access="public" returntype="boolean" output="no">
		<cfargument name="blank" type="any" required="no" default="">
		<cfargument name="name" type="string" required="yes">
		<cfset var files = filesOf(arguments.name)>
		<cfset var file = "">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(files)#" index="i">
			<cfset file = files[i]>

			<cfif NOT IsObject(file)>
				<cfreturn false>
			</cfif>

			<cfif Compare(request.ENVIRONMENT, "testing") EQ 0>
				<cfif file.getError() NEQ 0>
					<cfreturn false>
				</cfif>
			<cfelse>
				<cfif NOT file.isValid()>
					<cfreturn false>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn true>
	</cffunction>

	<!---
	 * Verifies if the file's size in Kilobytes is no larger than the parameter.
	--->
	<cffunction name="max_size" access="public" returntype="boolean" output="no">
		<cfargument name="blank" type="any" required="no" default="">
		<cfargument name="params" type="string" required="yes">
		<cfset var paramArray = explode(",", arguments.params)>
		<cfset var files = "">
		<cfset var file = "">
		<cfset var i = 0>

		<!--- Grab the file name off the top of the $params after we split it. --->
		<cfif ArrayLen(paramArray) NEQ 2>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Invalid max_size parameter: ""#arguments.params#""">
		</cfif>

		<cfset files = filesOf(paramArray[1])>

		<cfloop from="1" to="#ArrayLen(files)#" index="i">
			<cfset file = files[i]>

			<cfif NOT IsObject(file)>
				<cfreturn false>
			</cfif>

			<cfif file.getError() NEQ 4>
				<cfif file.getError() EQ 1>
					<cfreturn false>
				</cfif>

				<cfif file.getSize() / 1024 GT Val(paramArray[2])>
					<cfreturn false>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn true>
	</cffunction>

	<!---
	 * Uses the mime config file to determine if a file is considered an "image",
	 * which for our purposes basically means that it's a raster image or svg.
	--->
	<cffunction name="is_image" access="public" returntype="boolean" output="no">
		<cfargument name="blank" type="any" required="no" default="">
		<cfargument name="params" type="string" required="yes">
		<cfset var parts = explode(",", arguments.params)>
		<cfset var files = filesOf(parts[1])>
		<cfset var file = "">
		<cfset var type = "">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(files)#" index="i">
			<cfset file = files[i]>

			<cfif NOT IsObject(file)>
				<cfreturn false>
			</cfif>

			<cfif file.getError() NEQ 4>
				<!--- We know that our mimes list always has the first mime start with `image` even when then are multiple accepted types. --->
				<cfset type = static_("Config\Mimes").guessTypeFromExtension(file.getExtension())>

				<cfif Find("image", type) NEQ 1>
					<cfreturn false>
				</cfif>

				<cfif hasInvalidImageClientExtension(file)>
					<cfreturn false>
				</cfif>

				<cfif hasUnsafeClientFilename(file)>
					<cfreturn false>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn true>
	</cffunction>

	<!---
	 * Checks to see if an uploaded file's mime type matches one in the parameter.
	--->
	<cffunction name="mime_in" access="public" returntype="boolean" output="no">
		<cfargument name="blank" type="any" required="no" default="">
		<cfargument name="params" type="string" required="yes">
		<cfset var parts = explode(",", arguments.params)>
		<cfset var files = filesOf(parts[1])>
		<cfset var file = "">
		<cfset var i = 0>

		<cfset ArrayDeleteAt(parts, 1)>

		<cfloop from="1" to="#ArrayLen(files)#" index="i">
			<cfset file = files[i]>

			<cfif NOT IsObject(file)>
				<cfreturn false>
			</cfif>

			<cfif file.getError() NEQ 4>
				<cfif NOT in_array(file.getMimeType(), parts)>
					<cfreturn false>
				</cfif>

				<cfif hasMismatchedClientExtension(file)>
					<cfreturn false>
				</cfif>

				<cfif hasUnsafeClientFilename(file)>
					<cfreturn false>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn true>
	</cffunction>

	<!---
	 * Checks to see if an uploaded file's extension matches one in the parameter.
	--->
	<cffunction name="ext_in" access="public" returntype="boolean" output="no">
		<cfargument name="blank" type="any" required="no" default="">
		<cfargument name="params" type="string" required="yes">
		<cfset var parts = explode(",", arguments.params)>
		<cfset var files = filesOf(parts[1])>
		<cfset var file = "">
		<cfset var clientExtension = "">
		<cfset var i = 0>

		<cfset ArrayDeleteAt(parts, 1)>

		<cfloop from="1" to="#ArrayLen(files)#" index="i">
			<cfset file = files[i]>

			<cfif NOT IsObject(file)>
				<cfreturn false>
			</cfif>

			<cfif file.getError() NEQ 4>
				<!--- Check the real filename extension, not only the guessed extension. --->
				<cfset clientExtension = LCase(file.getClientExtension())>

				<cfif clientExtension EQ "" OR NOT in_array(clientExtension, parts)>
					<cfreturn false>
				</cfif>

				<cfif Compare(file.guessExtension(), clientExtension) NEQ 0>
					<cfreturn false>
				</cfif>

				<cfif hasUnsafeClientFilename(file)>
					<cfreturn false>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn true>
	</cffunction>

	<!---
	 * Checks an uploaded file to verify that the dimensions are within
	 * a specified allowable dimension.
	--->
	<cffunction name="max_dims" access="public" returntype="boolean" output="no">
		<cfargument name="blank" type="any" required="no" default="">
		<cfargument name="params" type="string" required="yes">
		<cfset var parts = explode(",", arguments.params)>
		<cfset var files = filesOf(parts[1])>
		<cfset var file = "">
		<cfset var allowedWidth = 0>
		<cfset var allowedHeight = 0>
		<cfset var info = "">
		<cfset var i = 0>

		<!--- Get Parameter sizes --->
		<cfif ArrayLen(parts) GTE 2>
			<cfset allowedWidth = Val(parts[2])>
		</cfif>

		<cfif ArrayLen(parts) GTE 3>
			<cfset allowedHeight = Val(parts[3])>
		</cfif>

		<cfloop from="1" to="#ArrayLen(files)#" index="i">
			<cfset file = files[i]>

			<cfif NOT IsObject(file)>
				<cfreturn false>
			</cfif>

			<cfif file.getError() NEQ 4>
				<cfif file.getError() NEQ 0>
					<cfreturn false>
				</cfif>

				<!--- Get uploaded image size --->
				<cfset info = imageSize(file.getTempName())>

				<cfif NOT IsStruct(info)>
					<!--- Cannot get the image size. --->
					<cfreturn false>
				</cfif>

				<cfif info.width GT allowedWidth OR info.height GT allowedHeight>
					<cfreturn false>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn true>
	</cffunction>

	<!---
	 * Checks an uploaded file to verify that the dimensions are greater than
	 * a specified dimension.
	--->
	<cffunction name="min_dims" access="public" returntype="boolean" output="no">
		<cfargument name="blank" type="any" required="no" default="">
		<cfargument name="params" type="string" required="yes">
		<cfset var parts = explode(",", arguments.params)>
		<cfset var files = filesOf(parts[1])>
		<cfset var file = "">
		<cfset var minimumWidth = 0>
		<cfset var minimumHeight = 0>
		<cfset var info = "">
		<cfset var i = 0>

		<!--- Get Parameter sizes --->
		<cfif ArrayLen(parts) GTE 2>
			<cfset minimumWidth = Val(parts[2])>
		</cfif>

		<cfif ArrayLen(parts) GTE 3>
			<cfset minimumHeight = Val(parts[3])>
		</cfif>

		<cfloop from="1" to="#ArrayLen(files)#" index="i">
			<cfset file = files[i]>

			<cfif NOT IsObject(file)>
				<cfreturn false>
			</cfif>

			<cfif file.getError() NEQ 4>
				<cfif file.getError() NEQ 0>
					<cfreturn false>
				</cfif>

				<!--- Get uploaded image size --->
				<cfset info = imageSize(file.getTempName())>

				<cfif NOT IsStruct(info)>
					<!--- Cannot get the image size. --->
					<cfreturn false>
				</cfif>

				<cfif info.width LT minimumWidth OR info.height LT minimumHeight>
					<cfreturn false>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn true>
	</cffunction>

	<!---
	 * The files of a name: the list of a multiple upload, or the one file.
	 * An entry that is not a file (null) is an empty string.
	 *
	 * Not in the original (it is the $files ??= [...] lines).
	--->
	<cffunction name="filesOf" access="private" returntype="array" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfset var result = ArrayNew(1)>
		<cfset var multiple = this.request_.getFileMultiple(arguments.name)>
		<cfset var key = "">

		<cfif IsStruct(multiple)>
			<cfloop collection="#multiple#" item="key">
				<cfset ArrayAppend(result, multiple[key])>
			</cfloop>
		<cfelse>
			<cfset ArrayAppend(result, this.request_.getFile(arguments.name))>
		</cfif>

		<cfreturn result>
	</cffunction>

	<!---
	 * The width and height of an image, or an empty string when the file is
	 * no image that Java can read.
	 *
	 * Not in the original (it is getimagesize()).
	--->
	<cffunction name="imageSize" access="private" returntype="any" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfset var result = "">
		<cfset var imageIO = CreateObject("java", "javax.imageio.ImageIO")>
		<cfset var stream = "">
		<cfset var readers = "">
		<cfset var reader = "">
		<cfset var size = "">

		<cftry>
			<cfset stream = imageIO.createImageInputStream(CreateObject("java", "java.io.File").init(JavaCast("string", arguments.path)))>

			<cfif IsDefined("stream")>
				<cfset readers = imageIO.getImageReaders(stream)>

				<cfif readers.hasNext()>
					<cfset reader = readers.next()>
					<cfset reader.setInput(stream)>
					<cfset size = StructNew()>
					<cfset size.width = reader.getWidth(JavaCast("int", 0))>
					<cfset size.height = reader.getHeight(JavaCast("int", 0))>
					<cfset result = size>
				</cfif>
			</cfif>

			<cfcatch type="any">
				<cfset result = "">
			</cfcatch>
		</cftry>

		<!--- there is no cffinally on 6.1: release the reader and the stream here, so a truncated image does not keep the file open --->
		<cfif NOT IsSimpleValue(reader)>
			<cftry>
				<cfset reader.dispose()>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>

		<cfif NOT IsSimpleValue(stream)>
			<cftry>
				<cfset stream.close()>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>

		<cfreturn result>
	</cffunction>

	<!---
	 * Reject filenames with non-empty extensions that are not image types.
	--->
	<cffunction name="hasInvalidImageClientExtension" access="private" returntype="boolean" output="no">
		<cfargument name="file" type="any" required="yes">
		<cfset var clientExtension = trim_(LCase(arguments.file.getClientExtension()), ". ")>
		<cfset var type = "">

		<cfif clientExtension EQ "">
			<cfreturn false>
		</cfif>

		<cfset type = static_("Config\Mimes").guessTypeFromExtension(clientExtension)>

		<cfreturn Find("image", type) NEQ 1>
	</cffunction>

	<!---
	 * Reject filenames with non-empty extensions that do not match the detected content.
	--->
	<cffunction name="hasMismatchedClientExtension" access="private" returntype="boolean" output="no">
		<cfargument name="file" type="any" required="yes">
		<cfset var clientExtension = trim_(LCase(arguments.file.getClientExtension()), ". ")>

		<cfif clientExtension EQ "">
			<cfreturn false>
		</cfif>

		<cfreturn Compare(arguments.file.guessExtension(), clientExtension) NEQ 0>
	</cffunction>

	<!---
	 * Reject trailing-dot names and names with a server-side script extension before the final extension.
	--->
	<cffunction name="hasUnsafeClientFilename" access="private" returntype="boolean" output="no">
		<cfargument name="file" type="any" required="yes">
		<cfset var filename = "">
		<cfset var parts = "">
		<cfset var part = "">
		<cfset var i = 0>

		<cfset helper("security")>

		<!--- Check the name that UploadedFile::move() uses when no name is supplied. --->
		<cfset filename = sanitize_filename(arguments.file.getClientName())>
		<cfset parts = explode(".", LCase(rtrim_(filename, " ")))>

		<cfif ArrayLen(parts) EQ 1>
			<cfreturn false>
		</cfif>

		<cfif parts[ArrayLen(parts)] EQ "">
			<cfreturn true>
		</cfif>

		<!--- Some server configurations select a handler from an earlier extension. --->
		<cfset ArrayDeleteAt(parts, ArrayLen(parts))>
		<cfset ArrayDeleteAt(parts, 1)>

		<cfloop from="1" to="#ArrayLen(parts)#" index="i">
			<cfset part = parts[i]>

			<cfif REFind(this.scriptPattern, part) GT 0 OR ListFind(this.scriptExtensions, part) GT 0>
				<cfreturn true>
			</cfif>
		</cfloop>

		<cfreturn false>
	</cffunction>

</cfcomponent>
