<!---
 * -------------------------------------------------------------------
 * Mimes
 * -------------------------------------------------------------------
 *
 * This file contains an array of mime types. It is used by the
 * Upload class to help identify allowed file types.
 *
 * When working with mime types, please make sure you have the
 * fileinfo extension enabled to reliably detect the media types.
 *
 * Not ported yet: the fileinfo extension, so File.getMimeType() cannot
 * detect a media type (see Files/File.cfc).
 *
 * Not ported yet: the extensions of the upstream language (its script
 * files), which the source does not name.
 *
 * Difference: the mime types of an extension are one comma separated list
 * (a string, also for a single type; no mime type holds a comma), and the
 * map keeps the order of the extensions, as the search for an extension
 * by type is order sensitive. A map keeps no list, so a type is looked up
 * with ListFind(), which is case-sensitive, as the strict in_array() of
 * the original is.
--->
<cfcomponent output="no" hint="Mime types by file extension">

	<!---
	 * Map of extensions to mime types.
	 *
	 * @var array<string, string>
	--->
	<cfset this.mimes = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.mimes["hqx"] = "application/mac-binhex40,application/mac-binhex,application/x-binhex40,application/x-mac-binhex40">
	<cfset this.mimes["cpt"] = "application/mac-compactpro">
	<cfset this.mimes["csv"] = "text/csv,text/x-comma-separated-values,text/comma-separated-values,application/vnd.ms-excel,application/x-csv,text/x-csv,application/csv,application/excel,application/vnd.msexcel,text/plain">
	<cfset this.mimes["bin"] = "application/macbinary,application/mac-binary,application/octet-stream,application/x-binary,application/x-macbinary">
	<cfset this.mimes["dms"] = "application/octet-stream">
	<cfset this.mimes["lha"] = "application/octet-stream">
	<cfset this.mimes["lzh"] = "application/octet-stream">
	<cfset this.mimes["exe"] = "application/octet-stream,application/vnd.microsoft.portable-executable,application/x-dosexec,application/x-msdownload">
	<cfset this.mimes["class"] = "application/octet-stream">
	<cfset this.mimes["psd"] = "application/x-photoshop,image/vnd.adobe.photoshop">
	<cfset this.mimes["so"] = "application/octet-stream">
	<cfset this.mimes["sea"] = "application/octet-stream">
	<cfset this.mimes["dll"] = "application/octet-stream">
	<cfset this.mimes["oda"] = "application/oda">
	<cfset this.mimes["pdf"] = "application/pdf,application/force-download,application/x-download">
	<cfset this.mimes["ai"] = "application/pdf,application/postscript">
	<cfset this.mimes["eps"] = "application/postscript">
	<cfset this.mimes["ps"] = "application/postscript">
	<cfset this.mimes["smi"] = "application/smil">
	<cfset this.mimes["smil"] = "application/smil">
	<cfset this.mimes["mif"] = "application/vnd.mif">
	<cfset this.mimes["xls"] = "application/vnd.ms-excel,application/msexcel,application/x-msexcel,application/x-ms-excel,application/x-excel,application/x-dos_ms_excel,application/xls,application/x-xls,application/excel,application/download,application/vnd.ms-office,application/msword">
	<cfset this.mimes["ppt"] = "application/vnd.ms-powerpoint,application/powerpoint,application/vnd.ms-office,application/msword">
	<cfset this.mimes["pptx"] = "application/vnd.openxmlformats-officedocument.presentationml.presentation">
	<cfset this.mimes["wbxml"] = "application/wbxml">
	<cfset this.mimes["wmlc"] = "application/wmlc">
	<cfset this.mimes["dcr"] = "application/x-director">
	<cfset this.mimes["dir"] = "application/x-director">
	<cfset this.mimes["dxr"] = "application/x-director">
	<cfset this.mimes["dvi"] = "application/x-dvi">
	<cfset this.mimes["gtar"] = "application/x-gtar">
	<cfset this.mimes["gz"] = "application/x-gzip">
	<cfset this.mimes["gzip"] = "application/x-gzip">
	<cfset this.mimes["js"] = "application/x-javascript,text/plain">
	<cfset this.mimes["swf"] = "application/x-shockwave-flash">
	<cfset this.mimes["sit"] = "application/x-stuffit">
	<cfset this.mimes["tar"] = "application/x-tar">
	<cfset this.mimes["tgz"] = "application/x-tar,application/x-gzip-compressed">
	<cfset this.mimes["z"] = "application/x-compress">
	<cfset this.mimes["xhtml"] = "application/xhtml+xml">
	<cfset this.mimes["xht"] = "application/xhtml+xml">
	<cfset this.mimes["zip"] = "application/x-zip,application/zip,application/x-zip-compressed,application/s-compressed,multipart/x-zip">
	<cfset this.mimes["rar"] = "application/vnd.rar,application/x-rar,application/rar,application/x-rar-compressed">
	<cfset this.mimes["mid"] = "audio/midi">
	<cfset this.mimes["midi"] = "audio/midi">
	<cfset this.mimes["mpga"] = "audio/mpeg">
	<cfset this.mimes["mp2"] = "audio/mpeg">
	<cfset this.mimes["mp3"] = "audio/mpeg,audio/mpg,audio/mpeg3,audio/mp3">
	<cfset this.mimes["aif"] = "audio/x-aiff,audio/aiff">
	<cfset this.mimes["aiff"] = "audio/x-aiff,audio/aiff">
	<cfset this.mimes["aifc"] = "audio/x-aiff">
	<cfset this.mimes["ram"] = "audio/x-pn-realaudio">
	<cfset this.mimes["rm"] = "audio/x-pn-realaudio">
	<cfset this.mimes["rpm"] = "audio/x-pn-realaudio-plugin">
	<cfset this.mimes["ra"] = "audio/x-realaudio">
	<cfset this.mimes["rv"] = "video/vnd.rn-realvideo">
	<cfset this.mimes["wav"] = "audio/x-wav,audio/wave,audio/wav">
	<cfset this.mimes["bmp"] = "image/bmp,image/x-bmp,image/x-bitmap,image/x-xbitmap,image/x-win-bitmap,image/x-windows-bmp,image/ms-bmp,image/x-ms-bmp,application/bmp,application/x-bmp,application/x-win-bitmap">
	<cfset this.mimes["gif"] = "image/gif">
	<cfset this.mimes["jpg"] = "image/jpeg,image/pjpeg">
	<cfset this.mimes["jpeg"] = "image/jpeg,image/pjpeg">
	<cfset this.mimes["jpe"] = "image/jpeg,image/pjpeg">
	<cfset this.mimes["jp2"] = "image/jp2,video/mj2,image/jpx,image/jpm">
	<cfset this.mimes["j2k"] = "image/jp2,video/mj2,image/jpx,image/jpm">
	<cfset this.mimes["jpf"] = "image/jp2,video/mj2,image/jpx,image/jpm">
	<cfset this.mimes["jpg2"] = "image/jp2,video/mj2,image/jpx,image/jpm">
	<cfset this.mimes["jpx"] = "image/jp2,video/mj2,image/jpx,image/jpm">
	<cfset this.mimes["jpm"] = "image/jp2,video/mj2,image/jpx,image/jpm">
	<cfset this.mimes["mj2"] = "image/jp2,video/mj2,image/jpx,image/jpm">
	<cfset this.mimes["mjp2"] = "image/jp2,video/mj2,image/jpx,image/jpm">
	<cfset this.mimes["png"] = "image/png,image/x-png">
	<cfset this.mimes["webp"] = "image/webp">
	<cfset this.mimes["tif"] = "image/tiff">
	<cfset this.mimes["tiff"] = "image/tiff">
	<cfset this.mimes["css"] = "text/css,text/plain">
	<cfset this.mimes["html"] = "text/html,text/plain">
	<cfset this.mimes["htm"] = "text/html,text/plain">
	<cfset this.mimes["shtml"] = "text/html,text/plain">
	<cfset this.mimes["txt"] = "text/plain">
	<cfset this.mimes["text"] = "text/plain">
	<cfset this.mimes["log"] = "text/plain,text/x-log">
	<cfset this.mimes["rtx"] = "text/richtext">
	<cfset this.mimes["rtf"] = "text/rtf">
	<cfset this.mimes["xml"] = "application/xml,text/xml,text/plain">
	<cfset this.mimes["xsl"] = "application/xml,text/xsl,text/xml">
	<cfset this.mimes["mpeg"] = "video/mpeg">
	<cfset this.mimes["mpg"] = "video/mpeg">
	<cfset this.mimes["mpe"] = "video/mpeg">
	<cfset this.mimes["qt"] = "video/quicktime">
	<cfset this.mimes["mov"] = "video/quicktime">
	<cfset this.mimes["avi"] = "video/x-msvideo,video/msvideo,video/avi,application/x-troff-msvideo">
	<cfset this.mimes["movie"] = "video/x-sgi-movie">
	<cfset this.mimes["doc"] = "application/msword,application/vnd.ms-office">
	<cfset this.mimes["docx"] = "application/vnd.openxmlformats-officedocument.wordprocessingml.document,application/zip,application/msword,application/x-zip">
	<cfset this.mimes["dot"] = "application/msword,application/vnd.ms-office">
	<cfset this.mimes["dotx"] = "application/vnd.openxmlformats-officedocument.wordprocessingml.document,application/zip,application/msword">
	<cfset this.mimes["xlsx"] = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/zip,application/vnd.ms-excel,application/msword,application/x-zip">
	<cfset this.mimes["xlsb"] = "application/vnd.ms-excel.sheet.binary.macroEnabled.12">
	<cfset this.mimes["xlsm"] = "application/vnd.ms-excel.sheet.macroEnabled.12">
	<cfset this.mimes["word"] = "application/msword,application/octet-stream">
	<cfset this.mimes["xl"] = "application/excel">
	<cfset this.mimes["eml"] = "message/rfc822">
	<cfset this.mimes["json"] = "application/json,text/json">
	<cfset this.mimes["pem"] = "application/x-x509-user-cert,application/x-pem-file,application/octet-stream">
	<cfset this.mimes["p10"] = "application/x-pkcs10,application/pkcs10">
	<cfset this.mimes["p12"] = "application/x-pkcs12">
	<cfset this.mimes["p7a"] = "application/x-pkcs7-signature">
	<cfset this.mimes["p7c"] = "application/pkcs7-mime,application/x-pkcs7-mime">
	<cfset this.mimes["p7m"] = "application/pkcs7-mime,application/x-pkcs7-mime">
	<cfset this.mimes["p7r"] = "application/x-pkcs7-certreqresp">
	<cfset this.mimes["p7s"] = "application/pkcs7-signature">
	<cfset this.mimes["crt"] = "application/x-x509-ca-cert,application/x-x509-user-cert,application/pkix-cert">
	<cfset this.mimes["crl"] = "application/pkix-crl,application/pkcs-crl">
	<cfset this.mimes["der"] = "application/x-x509-ca-cert">
	<cfset this.mimes["kdb"] = "application/octet-stream">
	<cfset this.mimes["pgp"] = "application/pgp">
	<cfset this.mimes["gpg"] = "application/gpg-keys">
	<cfset this.mimes["sst"] = "application/octet-stream">
	<cfset this.mimes["csr"] = "application/octet-stream">
	<cfset this.mimes["rsa"] = "application/x-pkcs7">
	<cfset this.mimes["cer"] = "application/pkix-cert,application/x-x509-ca-cert">
	<cfset this.mimes["3g2"] = "video/3gpp2">
	<cfset this.mimes["3gp"] = "video/3gp,video/3gpp">
	<cfset this.mimes["mp4"] = "video/mp4">
	<cfset this.mimes["m4a"] = "audio/x-m4a">
	<cfset this.mimes["f4v"] = "video/mp4,video/x-f4v">
	<cfset this.mimes["flv"] = "video/x-flv">
	<cfset this.mimes["webm"] = "video/webm">
	<cfset this.mimes["aac"] = "audio/x-acc">
	<cfset this.mimes["m4u"] = "application/vnd.mpegurl">
	<cfset this.mimes["m3u"] = "text/plain">
	<cfset this.mimes["xspf"] = "application/xspf+xml">
	<cfset this.mimes["vlc"] = "application/videolan">
	<cfset this.mimes["wmv"] = "video/x-ms-wmv,video/x-ms-asf">
	<cfset this.mimes["au"] = "audio/x-au">
	<cfset this.mimes["ac3"] = "audio/ac3">
	<cfset this.mimes["flac"] = "audio/x-flac">
	<cfset this.mimes["ogg"] = "audio/ogg,video/ogg,application/ogg">
	<cfset this.mimes["kmz"] = "application/vnd.google-earth.kmz,application/zip,application/x-zip">
	<cfset this.mimes["kml"] = "application/vnd.google-earth.kml+xml,application/xml,text/xml">
	<cfset this.mimes["ics"] = "text/calendar">
	<cfset this.mimes["ical"] = "text/calendar">
	<cfset this.mimes["zsh"] = "text/x-scriptzsh">
	<cfset this.mimes["7zip"] = "application/x-compressed,application/x-zip-compressed,application/zip,multipart/x-zip">
	<cfset this.mimes["cdr"] = "application/cdr,application/coreldraw,application/x-cdr,application/x-coreldraw,image/cdr,image/x-cdr,zz-application/zz-winassoc-cdr">
	<cfset this.mimes["wma"] = "audio/x-ms-wma,video/x-ms-asf">
	<cfset this.mimes["jar"] = "application/java-archive,application/x-java-application,application/x-jar,application/x-compressed">
	<cfset this.mimes["svg"] = "image/svg+xml,image/svg,application/xml,text/xml">
	<cfset this.mimes["vcf"] = "text/x-vcard">
	<cfset this.mimes["srt"] = "text/srt,text/plain">
	<cfset this.mimes["vtt"] = "text/vtt,text/plain">
	<cfset this.mimes["ico"] = "image/x-icon,image/x-ico,image/vnd.microsoft.icon">
	<cfset this.mimes["stl"] = "application/sla,application/vnd.ms-pki.stl,application/x-navistyle,model/stl,application/octet-stream">

	<!---
	 * Attempts to determine the best mime type for the given file extension.
	 *
	 * @return The mime type found, or an empty string (null) if unable to determine
	--->
	<cffunction name="guessTypeFromExtension" access="public" returntype="string" output="no">
		<cfargument name="extension" type="string" required="yes">

		<cfset arguments.extension = trim_(LCase(arguments.extension), ". ")>

		<cfif NOT array_key_exists(arguments.extension, this.mimes)>
			<cfreturn "">
		</cfif>

		<cfreturn ListFirst(this.mimes[arguments.extension])>
	</cffunction>

	<!---
	 * Attempts to determine the best file extension for a given mime type.
	 *
	 * @param proposedExtension default extension (in case there is more than one with the same mime type)
	 *
	 * @return The extension determined, or an empty string (null) if unable to match
	--->
	<cffunction name="guessExtensionFromType" access="public" returntype="string" output="no">
		<cfargument name="type" type="string" required="yes">
		<cfargument name="proposedExtension" type="string" required="no" default="">
		<cfset var ext = "">

		<cfset arguments.type = trim_(LCase(arguments.type), ". ")>

		<cfset arguments.proposedExtension = Trim(LCase(arguments.proposedExtension))>

		<cfif arguments.proposedExtension NEQ ""
			AND array_key_exists(arguments.proposedExtension, this.mimes)
			AND ListFind(this.mimes[arguments.proposedExtension], arguments.type) GT 0>
			<!--- The detected mime type matches with the proposed extension. --->
			<cfreturn arguments.proposedExtension>
		</cfif>

		<!--- Reverse check the mime type list if no extension was proposed. --->
		<!--- This search is order sensitive! --->
		<cfloop collection="#this.mimes#" item="ext">
			<cfif ListFind(this.mimes[ext], arguments.type) GT 0>
				<cfreturn ext>
			</cfif>
		</cfloop>

		<cfreturn "">
	</cffunction>

</cfcomponent>
