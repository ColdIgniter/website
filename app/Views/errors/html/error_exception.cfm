<!---
 * The headers are plain strings here, there is no Header class.
 *
 * static:: is exceptionHandler here, the handler that renders the view.
 *
 * file is read as variables.file, because file is also a scope.
--->
<cfset errorId = "error" & Replace(CreateUUID(), "-", "", "all")>
<cfset __dir = GetDirectoryFromPath(GetCurrentTemplatePath())>
<cffile action="read" file="#__dir#debug.css" variable="__css">
<cfset __css = REReplace(__css, "[#Chr(13)##Chr(10)##Chr(9)# ]+", " ", "all")>
<cffile action="read" file="#__dir#debug.js" variable="__js">
<cfset __code = "">
<cfif StructKeyExists(exception, "errorcode") AND Len(exception.errorcode) GT 0 AND exception.errorcode NEQ 0>
    <cfset __code = " ##" & exception.errorcode>
</cfif>
<cfset __runtime = CreateObject("java", "java.lang.Runtime").getRuntime()>
<cfoutput><!doctype html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="robots" content="noindex">

    <title>#esc(title)#</title>
    <style>
        #__css#
    </style>

    <script>
        #__js#
    </script>
</head>
<body onload="init()">

    <!-- Header -->
    <div class="header">
        <div class="environment">
            Displayed at #esc(TimeFormat(Now(), "HH:mm:ss"))# &mdash;
            CFML: #esc(Server.ColdFusion.ProductVersion)#  &mdash;
            ColdIgniter: #esc(service("coldigniter").CI_VERSION)# --
            Environment: #request.ENVIRONMENT#
        </div>
        <div class="container">
            <h1>#esc(title)##esc(__code)#</h1>
            <p>
                #nl2br(esc(message))#
                <a href="https://www.duckduckgo.com/?q=#URLEncodedFormat(title & ' ' & REReplace(message, "'[^']*'|""[^""]*""", "", "all"))#"
                   rel="noreferrer" target="_blank">search &rarr;</a>
            </p>
        </div>
    </div>

    <!-- Source -->
    <div class="container">
        <p><b>#esc(clean_path(variables.file))#</b> at line <b>#esc(line)#</b></p>

        <cfif is_file(variables.file)>
            <cfset __source = exceptionHandler.highlightFile(variables.file, line, 15)>
            <div class="source">
                <cfif NOT IsBoolean(__source)>#__source#</cfif>
            </div>
        </cfif>
    </div>

    <div class="container">
        <!--- Not ported yet: the exceptions that caused this one, a caught error has no previous one --->
    </div>

    <cfset __showBacktrace = false>
    <cfif defined("SHOW_DEBUG_BACKTRACE")>
        <cfset __showBacktrace = request.SHOW_DEBUG_BACKTRACE>
    </cfif>
    <cfif __showBacktrace>
    <div class="container">

        <ul class="tabs" id="tabs">
            <li><a href="##backtrace">Backtrace</a></li>
            <li><a href="##server">Server</a></li>
            <li><a href="##request">Request</a></li>
            <li><a href="##response">Response</a></li>
            <li><a href="##files">Files</a></li>
            <li><a href="##memory">Memory</a></li>
        </ul>

        <div class="tab-content">

            <!-- Backtrace -->
            <div class="content" id="backtrace">

                <ol class="trace">
                <cfloop from="1" to="#ArrayLen(trace)#" index="index">
                    <cfset row = trace[index]>

                    <li>
                        <p>
                            <!-- Trace info -->
                            <cfif StructKeyExists(row, "file") AND is_file(row["file"])>
                                #esc(clean_path(row["file"]) & " : " & row["line"])#
                            <cfelse>
                                {CFML internal code}
                            </cfif>

                            <!--- Not ported yet: the class, the method and the arguments of a row, and the source of the rows: a CFML trace has only the template and the line --->
                        </p>
                    </li>

                </cfloop>
                </ol>

            </div>

            <!-- Server -->
            <div class="content" id="server">
                <!--- Not ported yet: $_SESSION --->
                <h3>CGI</h3>

                <table>
                    <thead>
                        <tr>
                            <th>Key</th>
                            <th>Value</th>
                        </tr>
                    </thead>
                    <tbody>
                    <cfloop collection="#CGI#" item="key">
                        <tr>
                            <td>#esc(key)#</td>
                            <td>
                                <cfif IsSimpleValue(CGI[key])>
                                    #esc(CGI[key])#
                                </cfif>
                            </td>
                        </tr>
                    </cfloop>
                    </tbody>
                </table>

                <!-- Constants -->
                <!--- Not ported yet: get_defined_constants(), the constants are the simple values of the Request scope --->
                <h3>Constants</h3>

                <table>
                    <thead>
                        <tr>
                            <th>Key</th>
                            <th>Value</th>
                        </tr>
                    </thead>
                    <tbody>
                    <cfloop collection="#request#" item="key">
                        <cfif IsSimpleValue(request[key])>
                            <tr>
                                <td>#esc(key)#</td>
                                <td>#esc(request[key])#</td>
                            </tr>
                        </cfif>
                    </cfloop>
                    </tbody>
                </table>
            </div>

            <!-- Request -->
            <div class="content" id="request">
                <cfset request_ = service("request")>

                <table>
                    <tbody>
                        <tr>
                            <td style="width: 10em">Path</td>
                            <td>#esc(request_.getUri().__toString())#</td>
                        </tr>
                        <tr>
                            <td>HTTP Method</td>
                            <td>#esc(request_.getMethod())#</td>
                        </tr>
                        <!--- Not ported yet: the IP address, and the AJAX, CLI and secure flags of the request --->
                        <tr>
                            <td>User Agent</td>
                            <td>#esc(request_.getHeaderLine("user-agent"))#</td>
                        </tr>

                    </tbody>
                </table>


                <cfset empty = true>
                <cfloop list="url,form,cookie" index="scopeName">
                    <cfset scope = Evaluate(scopeName)>
                    <cfif StructCount(scope) EQ 0>
                        <cfset empty = empty>
                    <cfelse>
                        <cfset empty = false>

                        <h3>#esc(scopeName)#</h3>

                        <table style="width: 100%">
                            <thead>
                                <tr>
                                    <th>Key</th>
                                    <th>Value</th>
                                </tr>
                            </thead>
                            <tbody>
                            <cfloop collection="#scope#" item="key">
                                <tr>
                                    <td>#esc(key)#</td>
                                    <td>
                                        <cfif IsSimpleValue(scope[key])>
                                            #esc(scope[key])#
                                        <cfelse>
                                            <pre>[complex value]</pre>
                                        </cfif>
                                    </td>
                                </tr>
                            </cfloop>
                            </tbody>
                        </table>
                    </cfif>
                </cfloop>

                <cfif empty>

                    <div class="alert">
                        No URL, form, or cookie information to show.
                    </div>

                </cfif>

                <cfset headers = request_.headers()>
                <cfif StructCount(headers) GT 0>

                    <h3>Headers</h3>

                    <table>
                        <thead>
                            <tr>
                                <th>Header</th>
                                <th>Value</th>
                            </tr>
                        </thead>
                        <tbody>
                        <cfloop collection="#headers#" item="name">
                            <tr>
                                <td>#esc(name, "html")#</td>
                                <td>
                                <cfif IsArray(headers[name])>
                                    <cfloop from="1" to="#ArrayLen(headers[name])#" index="headerIndex">
                                        #" (" & headerIndex & ") " & esc(headers[name][headerIndex].getValueLine(), "html")#
                                    </cfloop>
                                <cfelse>
                                    #esc(headers[name].getValueLine(), "html")#
                                </cfif>
                                </td>
                            </tr>
                        </cfloop>
                        </tbody>
                    </table>

                </cfif>
            </div>

            <!-- Response -->
            <cfset response = service("response")>
            <!--- Not ported yet: response.setStatusCode(http_response_code()), the handler has set the status code already --->
            <div class="content" id="response">
                <table>
                    <tr>
                        <td style="width: 15em">Response Status</td>
                        <td>#esc(response.getStatusCode() & " - " & response.getReasonPhrase())#</td>
                    </tr>
                </table>

                <cfset headers = response.headers()>
                <cfif StructCount(headers) GT 0>
                    <h3>Headers</h3>

                    <table>
                        <thead>
                            <tr>
                                <th>Header</th>
                                <th>Value</th>
                            </tr>
                        </thead>
                        <tbody>
                        <cfloop collection="#headers#" item="name">
                            <tr>
                                <td>#esc(name, "html")#</td>
                                <td>
                                <cfif IsArray(headers[name])>
                                    <cfloop from="1" to="#ArrayLen(headers[name])#" index="headerIndex">
                                        #" (" & headerIndex & ") " & esc(headers[name][headerIndex].getValueLine(), "html")#
                                    </cfloop>
                                <cfelse>
                                    #esc(response.getHeaderLine(name), "html")#
                                </cfif>
                                </td>
                            </tr>
                        </cfloop>
                        </tbody>
                    </table>

                </cfif>
            </div>

            <!-- Files -->
            <div class="content" id="files">
                <!--- Not ported yet: get_included_files(), these are the files of functions that require_once() loaded --->
                <ol>
                <cfloop collection="#request.ColdIgniter.included#" item="key">
                    <li>#esc(clean_path(key))#</li>
                </cfloop>
                </ol>
            </div>

            <!-- Memory -->
            <div class="content" id="memory">

                <!--- Not ported yet: there is no peak usage, so the memory the runtime holds is shown, and its maximum as the limit --->
                <table>
                    <tbody>
                        <tr>
                            <td>Memory Usage</td>
                            <td>#esc(exceptionHandler.describeMemory(__runtime.totalMemory() - __runtime.freeMemory()))#</td>
                        </tr>
                        <tr>
                            <td style="width: 12em">Peak Memory Usage:</td>
                            <td>#esc(exceptionHandler.describeMemory(__runtime.totalMemory()))#</td>
                        </tr>
                        <tr>
                            <td>Memory Limit:</td>
                            <td>#esc(exceptionHandler.describeMemory(__runtime.maxMemory()))#</td>
                        </tr>
                    </tbody>
                </table>

            </div>

        </div>  <!-- /tab-content -->

    </div> <!-- /container -->
    </cfif>

</body>
</html>
</cfoutput>
