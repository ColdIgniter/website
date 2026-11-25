<!---
 * ColdIgniter Security Helpers
 *
 * Not ported yet: the function of the original that converts the opening
 * and closing tags of the server-side language of the original to
 * entities. Its name is that of the language, which is kept out of the
 * source here.
 *
 * A function here has no guard against a second definition (the original
 * checks function_exists): helper() keeps the first definition of a name.
--->

<!---
 * Sanitize Filename
 *
 * Tries to sanitize filenames in order to prevent directory traversal attempts
 * and other security threats, which is particularly useful for files that
 * were supplied via user input.
 *
 * If it is acceptable for the user input to include relative paths,
 * e.g. file/in/some/approved/folder.txt, you can set the second optional
 * parameter, relativePath to true.
 * Only forward slashes are preserved, backslashes are always removed.
 *
 * @param filename     Input file name
 * @param relativePath Whether to preserve paths
--->
<cffunction name="sanitize_filename" returntype="string" output="no" hint="Sanitize Filename">
	<cfargument name="filename" type="string" required="yes">
	<cfargument name="relativePath" type="boolean" required="no" default="false">
	<cfset var bad = ArrayNew(1)>
	<cfset var old = "">

	<!--- List of sanitized filename strings --->
	<cfset ArrayAppend(bad, "\")>
	<cfset ArrayAppend(bad, "../")>
	<cfset ArrayAppend(bad, "<!--")>
	<cfset ArrayAppend(bad, "-->")>
	<cfset ArrayAppend(bad, "<")>
	<cfset ArrayAppend(bad, ">")>
	<cfset ArrayAppend(bad, "'")>
	<cfset ArrayAppend(bad, """")>
	<cfset ArrayAppend(bad, "&")>
	<cfset ArrayAppend(bad, "$")>
	<cfset ArrayAppend(bad, "##")>
	<cfset ArrayAppend(bad, "{")>
	<cfset ArrayAppend(bad, "}")>
	<cfset ArrayAppend(bad, "[")>
	<cfset ArrayAppend(bad, "]")>
	<cfset ArrayAppend(bad, "=")>
	<cfset ArrayAppend(bad, ";")>
	<cfset ArrayAppend(bad, "?")>
	<cfset ArrayAppend(bad, "%20")>
	<cfset ArrayAppend(bad, "%22")>
	<cfset ArrayAppend(bad, "%3c")>
	<cfset ArrayAppend(bad, "%253c")>
	<cfset ArrayAppend(bad, "%3e")>
	<cfset ArrayAppend(bad, "%0e")>
	<cfset ArrayAppend(bad, "%28")>
	<cfset ArrayAppend(bad, "%29")>
	<cfset ArrayAppend(bad, "%2528")>
	<cfset ArrayAppend(bad, "%26")>
	<cfset ArrayAppend(bad, "%24")>
	<cfset ArrayAppend(bad, "%3f")>
	<cfset ArrayAppend(bad, "%3b")>
	<cfset ArrayAppend(bad, "%3d")>

	<cfif NOT arguments.relativePath>
		<cfset ArrayAppend(bad, "./")>
		<cfset ArrayAppend(bad, "/")>
	</cfif>

	<cfset arguments.filename = remove_invisible_characters(arguments.filename, false)>

	<cfloop condition="true">
		<cfset old = arguments.filename>
		<cfset arguments.filename = str_replace(bad, "", arguments.filename)>

		<cfif Compare(old, arguments.filename) EQ 0>
			<cfbreak>
		</cfif>
	</cfloop>

	<cfreturn arguments.filename>
</cffunction>

<!---
 * Strip Image Tags
 *
 * Difference: the class [^\1] of the original (a character that is not
 * the code 1, as the backslash-one is read there) is written [^\x01], as
 * the regular expressions of Java do not take [^\1].
 *
 * Difference: the original runs both patterns over the whole text, where
 * .*? and [^\x01]+? can run on to the end of it. The Java engine has no
 * backtrack limit, and input such as <img src='a' repeated took time that
 * grew about with the cube of its length. Here the text is cut into heads
 * first: a head is an <img that is followed by a space or a /, then all the
 * text up to the last > before the next <. Both patterns run on one head at
 * a time, with the lazy parts written [^<]*? and the quoted value [^<]+?
 * (a head holds no <, and it ends in a > that every part can reach), so a
 * match never leaves its head and a failing start costs one pass over its
 * head. The run of spaces and slashes after <img is taken possessively
 * ([\s/]++): the lazy part after it can match the same characters, and
 * without that a head that fails, such as <img, many spaces and >, would be
 * tried once for every way of splitting the run. The attribute name cannot
 * start with a space or a slash, so the matches are the same.
 * For a normal tag the result is the same, with these differences:
 * what the original matches across a < is not matched (a tag with a < in its
 * text, as in <img alt="<" src=x>, is left as it is, and a match that the
 * original spreads over several tags is made one tag at a time), and a tag
 * may run over a line break, which the . of the original does not cross.
--->
<cffunction name="strip_image_tags" returntype="string" output="no" hint="Strip Image Tags">
	<cfargument name="str" type="string" required="yes">
	<cfset var pattern = CreateObject("java", "java.util.regex.Pattern")>
	<cfset var heads = pattern.compile(JavaCast("string", "<img[\s/][^<]*>"), JavaCast("int", 2)).matcher(JavaCast("string", arguments.str))>
	<cfset var quoted = pattern.compile(JavaCast("string", "<img[\s/]++[^<]*?src\s*=\s*([""'])([^<]+?)\1[^<]*?>"), JavaCast("int", 2))>
	<cfset var bare = pattern.compile(JavaCast("string", "<img[\s/]++[^<]*?src\s*=\s*?(([^\s""'=<>`]+))[^<]*?>"), JavaCast("int", 2))>
	<cfset var buffer = CreateObject("java", "java.lang.StringBuffer").init()>
	<cfset var head = "">
	<cfset var last = 0>

	<!--- the two patterns of the original, in order, on one head at a time; \2 is $2 for Java --->
	<cfloop condition="heads.find()">
		<cfset buffer.append(JavaCast("string", Mid(arguments.str, last + 1, heads.start() - last)))>
		<cfset head = quoted.matcher(heads.group()).replaceAll(JavaCast("string", "$2"))>
		<cfset buffer.append(bare.matcher(JavaCast("string", head)).replaceAll(JavaCast("string", "$2")))>
		<cfset last = heads.end()>
	</cfloop>

	<cfset buffer.append(JavaCast("string", Mid(arguments.str, last + 1, Len(arguments.str) - last)))>

	<cfreturn buffer.toString()>
</cffunction>
