<!---
 * HTTP language settings
 *
 * A language file is included by the Language component, and has to
 * set the variable "lines" to a map (see array_()); that stands in for
 * the "return [...]" of the original. The keys keep their order.
 *
 * Not ported yet: the lines of the CurlRequest, IncomingRequest, Response,
 * RedirectResponse and the other classes of the HTTP folder, which are
 * written out where they are used. Only the lines for uploaded files are here.
 *
 * Difference: the line uploadErrExtension does not name the language of the
 * original, as the extension is that of the server.
--->
<cfset lines = array_()>

<!--- Uploaded file moving --->
<cfset lines["alreadyMoved"] = "The uploaded file has already been moved.">
<cfset lines["invalidFile"] = "The original file is not a valid file.">
<cfset lines["moveFailed"] = "Could not move file ""{0}"" to ""{1}"". Reason: {2}">

<cfset lines["uploadErrOk"] = "The file uploaded with success.">
<cfset lines["uploadErrIniSize"] = "The file ""%s"" exceeds your upload_max_filesize ini directive.">
<cfset lines["uploadErrFormSize"] = "The file ""%s"" exceeds the upload limit defined in your form.">
<cfset lines["uploadErrPartial"] = "The file ""%s"" was only partially uploaded.">
<cfset lines["uploadErrNoFile"] = "No file was uploaded.">
<cfset lines["uploadErrCantWrite"] = "The file ""%s"" could not be written on disk.">
<cfset lines["uploadErrNoTmpDir"] = "File could not be uploaded: missing temporary directory.">
<cfset lines["uploadErrExtension"] = "File upload was stopped by an extension.">
<cfset lines["uploadErrUnknown"] = "The file ""%s"" was not uploaded due to an unknown error.">
