<!---
 * Value object representing a single file uploaded through an
 * HTTP request. Used by the IncomingRequest class to
 * provide files.
 *
 * There are no interfaces on 6.1, so this is a component that only says what
 * an uploaded file has to define. UploadedFile cannot extend it, as it
 * extends File, so it is not checked: it is kept for the list of methods.
 * The methods here only throw.
 *
 * Difference: the constructor, getErrorString() and the methods that File
 * gives are not listed.
--->
<cfcomponent output="no" hint="Value object representing a single file uploaded through an HTTP request">

	<!---
	 * Moves the file to a new location.
	 *
	 * $targetPath may be an absolute path, or a relative path. If it is a
	 * relative path, resolution should be the same as used by CFML's rename()
	 * function.
	 *
	 * The original file MUST be removed on completion.
	 *
	 * If this method is called more than once, any subsequent calls MUST raise
	 * an exception.
	 *
	 * When used where the files array is populated, when writing
	 * files via move(), the upload status SHOULD be
	 * verified, to ensure permissions are correct.
	 *
	 * If you wish to move to a stream, use getStream(), as SAPI operations
	 * cannot guarantee writing to stream destinations.
	 *
	 * @param targetPath Path to which to move the uploaded file.
	 * @param name       the name to rename the file to.
	 *
	 * @throws InvalidArgumentException if the $path specified is invalid.
	 * @throws RuntimeException         on any error during the move operation, or on the second or subsequent call to the method.
	--->
	<cffunction name="move" access="public" returntype="any" output="no">
		<cfargument name="targetPath" type="string" required="yes">
		<cfargument name="name" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.LogicException" message="The uploaded file does not define move().">
	</cffunction>

	<!---
	 * Returns whether the file was moved or not.
	 *
	 * If so, the file can no longer be moved.
	--->
	<cffunction name="hasMoved" access="public" returntype="boolean" output="no">
		<cfthrow type="ColdIgniter.LogicException" message="The uploaded file does not define hasMoved().">
	</cffunction>

	<!---
	 * Retrieve the error associated with the uploaded file.
	 *
	 * The return value MUST be one of the upload error constants (0 to 8, the
	 * UPLOAD_ERR_* values).
	 *
	 * If the file was uploaded successfully, this method MUST return 0.
	 *
	--->
	<cffunction name="getError" access="public" returntype="numeric" output="no">
		<cfthrow type="ColdIgniter.LogicException" message="The uploaded file does not define getError().">
	</cffunction>

	<!---
	 * Retrieve the filename sent by the client.
	 *
	 * Do not trust the value returned by this method. A client could send
	 * a malicious filename with the intention to corrupt or hack your
	 * application.
	 *
	 * Implementations SHOULD return the value stored in the "name" key of
	 * the file in the files array.
	--->
	<cffunction name="getName" access="public" returntype="string" output="no">
		<cfthrow type="ColdIgniter.LogicException" message="The uploaded file does not define getName().">
	</cffunction>

	<!---
	 * Gets the temporary filename where the file was uploaded to.
	--->
	<cffunction name="getTempName" access="public" returntype="string" output="no">
		<cfthrow type="ColdIgniter.LogicException" message="The uploaded file does not define getTempName().">
	</cffunction>

	<!---
	 * Returns the client path as provided by the client during upload.
	 *
	 * This is the value of the "full_path" key of the files array.
	 *
	 * @return The client path, or an empty string (null) if it was not available
	--->
	<cffunction name="getClientPath" access="public" returntype="string" output="no">
		<cfthrow type="ColdIgniter.LogicException" message="The uploaded file does not define getClientPath().">
	</cffunction>

	<!---
	 * Returns the original file extension, based on the file name that
	 * was uploaded.
	 *
	 * This is NOT a trusted source. For a trusted version, use guessExtension() instead.
	--->
	<cffunction name="getClientExtension" access="public" returntype="string" output="no">
		<cfthrow type="ColdIgniter.LogicException" message="The uploaded file does not define getClientExtension().">
	</cffunction>

	<!---
	 * Retrieve the media type sent by the client.
	 *
	 * Do not trust the value returned by this method. A client could send
	 * a malicious media type with the intention to corrupt or hack your
	 * application.
	--->
	<cffunction name="getClientMimeType" access="public" returntype="string" output="no">
		<cfthrow type="ColdIgniter.LogicException" message="The uploaded file does not define getClientMimeType().">
	</cffunction>

	<!---
	 * Returns whether the file was uploaded successfully, based on whether
	 * it was uploaded via HTTP and has no errors.
	--->
	<cffunction name="isValid" access="public" returntype="boolean" output="no">
		<cfthrow type="ColdIgniter.LogicException" message="The uploaded file does not define isValid().">
	</cffunction>

	<!---
	 * Returns the destination path for the move operation where overwriting is not expected.
	--->
	<cffunction name="getDestination" access="public" returntype="string" output="no">
		<cfargument name="destination" type="string" required="yes">
		<cfargument name="delimiter" type="string" required="no" default="_">
		<cfargument name="i" type="numeric" required="no" default="0">

		<cfthrow type="ColdIgniter.LogicException" message="The uploaded file does not define getDestination().">
	</cffunction>

</cfcomponent>
