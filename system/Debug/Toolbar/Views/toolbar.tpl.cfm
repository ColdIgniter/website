<!---
 * The page of the Debug Toolbar (the port of toolbar.tpl of the original). It is
 * included by a throwaway object (see Toolbar::format()), so the keys of the
 * data are variables here: url, method, isAJAX, startTime, totalTime,
 * totalMemory, segmentDuration, segmentCount, CI_VERSION, collectors, vars,
 * config, styles, toolbar (the Toolbar) and parser (the Parser).
 *
 * Difference: the toolbar is a variable, where the original has it as this (the object itself),
 * so toolbar.renderTimeline() is what $this->renderTimeline() is there.
 * Difference: the heading of the get values and the post values read GET and
 * POST, as there are no superglobals in a name. Difference: the accent colour
 * of the icon is #3366cc, where the original has its own orange (the same
 * for the style sheet). Difference: a badge that is an empty string is not
 * shown (there is no null). Not ported yet: the session data (the data has no
 * vars.session, so the page says that the session is not active), and the
 * hot reload (the button is there, and the route it reads is not).
--->
<cfoutput><style>
    #REReplace(file_get_contents(toolbar.config.viewsPath & "toolbar.css"), "[\r\n\t ]+", " ", "all")#
</style>

<script id="toolbar_js">
    var ciSiteURL = "#rtrim_(site_url(), "/")#"
    #file_get_contents(toolbar.config.viewsPath & "toolbar.js")#
    #file_get_contents(toolbar.config.viewsPath & "toolbarstandalone.js")#
</script>
<div id="debug-icon" class="debug-bar-ndisplay">
    <a id="debug-icon-link">
        <svg xmlns="http://www.w3.org/2000/svg" version="1.0" viewBox="0 0 155 200"><defs/><path fill="##3366cc" fill-rule="evenodd" d="M80.5 16C86.5 49 125.5 73 131.5 118C136 154 110.5 184 77.5 184C44.5 184 20.5 160 23.5 127C25 103 41.5 88 50.5 70C56.5 88 62.5 94 68.5 94C65.5 67 68.5 37 80.5 16ZM77.5 128.5L72.8 120.2L77.5 100L82.2 120.2ZM81.4 130.8L86.2 122.6L106.1 116.5L90.8 130.6ZM81.4 135.2L90.8 135.4L106.1 149.5L86.2 143.4ZM77.5 137.5L82.2 145.8L77.5 166L72.8 145.8ZM73.6 135.2L68.8 143.4L48.8 149.5L64.2 135.4ZM73.6 130.8L64.2 130.6L48.8 116.5L68.8 122.6Z"/></svg>
    </a>
</div>
<div id="debug-bar">
    <div class="toolbar">
        <span id="toolbar-position">&##8597;</span>
        <span id="toolbar-theme">&##128261;</span>
        <span id="hot-reload-btn" class="ci-label">
            <a id="debug-hot-reload" title="Toggle Hot Reload">
                <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAACXBIWXMAAAsTAAALEwEAmpwYAAABNklEQVR4nN2US04CQRCGv/DaiBxEvYWuBRPDKSCIXsCdcg0ULqTI8xIGN7JwTCU/ScV5tTO64Us6maSq/7+nuqvgkLgHopTl+QAWwBToAg3+wMTzM7YBrihp4jkCToEB8OJyRkCFAB5yDDxVoAd8OpNMOkrcAeMAgz3nzsQ0EqkDayXZqXy5Qugrdy2tGNdKeNWv40xCqGpvJK0YEwXt8ooylMZzUnCh4EkJgzNpmFaMrYLNEgbH0thmGVhSUVrSeE8KLv+7RBMFb0oY3EnDeihGN+WZhmJ7ZlnPtKHB5RvtNwy0d5XWaGgqRmp7a/9QLjRevoDLvOSRM+nnlKumk++0xwZlLhVnEulOhnohTS37vnU1t5M/ho7rPR03/LKW1bxNQep6ETZb5mpGW2/Ak2KpF3oYfAPX9Xpc671kqwAAAABJRU5ErkJggg==" />
            </a>
        </span>
        <span class="ci-label">
            <a data-tab="ci-timeline">
                <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAD7SURBVEhLY6ArSEtLK09NTbWHcvGC9PR0BaDaQiAdUl9fzwQVxg+AFvwHamqHcnGCpKQkeaDa9yD1UD09UCn8AKaBWJySkmIApFehi0ONwwRQBceBLurAh4FqFoHUAtkrgPgREN+ByYEw1DhMANVEMIhAYQ5U1wtU/wmILwLZRlAp/IBYC8gGw88CaFj3A/FnIL4ETDXGUCnyANSC/UC6HIpnQMXAqQXIvo0khxNDjcMEQEmU9AzDuNI7Lgw1DhOAJIEuhQcRKMcC+e+QNHdDpcgD6BaAANSSQqBcENFlDi6AzQKqgkFlwWhxjVI8o2OgmkFaXI8CTMDAAAAxd1O4FzLMaAAAAABJRU5ErkJggg==">
                <span class="hide-sm">#totalTime# ms &nbsp; #totalMemory# MB</span>
            </a>
        </span>

        <cfloop from="1" to="#ArrayLen(collectors)#" index="n">
            <cfset c = collectors[n]>
            <cfif c["isEmpty"] IS "false" AND (c["hasTabContent"] IS "true" OR c["hasLabel"] IS "true")>
                <span class="ci-label">
                    <a data-tab="ci-#c["titleSafe"]#">
                        <img src="#c["icon"]#">
                        <span class="hide-sm">
                            #c["title"]#
                            <cfif Compare(c["badgeValue"], "") NEQ 0>
                                <span class="badge">#c["badgeValue"]#</span>
                            </cfif>
                        </span>
                    </a>
                </span>
            </cfif>
        </cfloop>

        <span class="ci-label">
            <a data-tab="ci-vars">
                <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAACLSURBVEhLYxgFJIHU1NSraWlp/6H4T0pKSjRUijoAyXAwBlrYDpViAFpmARQrJwZDtWACoCROC4D8CnR5XBiqBRMADfyNprgRKkUdAApzoCUdUNwE5MtApYYIALp6NBWBMVQLJgAaOJqK8AOgq+mSio6DggjEBtLUT0UwQ5HZIADkj6aiUTAggIEBANAEDa/lkCRlAAAAAElFTkSuQmCC">
                <span class="hide-sm">Vars</span>
            </a>
        </span>

        <h1>
            <span class="ci-label">
                <a data-tab="ci-config">
                    <svg xmlns="http://www.w3.org/2000/svg" version="1.0" viewBox="0 0 155 200"><defs/><path fill="##3366cc" fill-rule="evenodd" d="M80.5 16C86.5 49 125.5 73 131.5 118C136 154 110.5 184 77.5 184C44.5 184 20.5 160 23.5 127C25 103 41.5 88 50.5 70C56.5 88 62.5 94 68.5 94C65.5 67 68.5 37 80.5 16ZM77.5 128.5L72.8 120.2L77.5 100L82.2 120.2ZM81.4 130.8L86.2 122.6L106.1 116.5L90.8 130.6ZM81.4 135.2L90.8 135.4L106.1 149.5L86.2 143.4ZM77.5 137.5L82.2 145.8L77.5 166L72.8 145.8ZM73.6 135.2L68.8 143.4L48.8 149.5L64.2 135.4ZM73.6 130.8L64.2 130.6L48.8 116.5L68.8 122.6Z"/></svg>
                    #CI_VERSION#
                </a>
            </span>
        </h1>

        <!-- Open/Close Toggle -->
        <a id="debug-bar-link" role="button" title="Open/Close">
            <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAEPSURBVEhL7ZVLDoJAEEThRuoGDwSEG+jCuFU34s3AK3APP1VDDSGMqI1xx0s6M/2rnlHEaMZElmWrPM+vsDvsYbQ7+us0TReSC2EBrEHxCevRYuppYLXkQpC8sVCuGfTvqSE3hFdFwUGuGfRvqSE35NUAfKZrbQNQm2jrMA+gOK+M+FmhDsRL5voHMA8gFGecq0JOXLWlQg7E7AMIxZnjOiZOEJ82gFCcedUE4gS56QP8yf8ywItz7e+RituKlkkDBoIOH4Nd4HZD4NsGYJ/Abn1xEVOcuZ8f0zc/tHiYmzTAwscBvDIK/veyQ9K/rnewjdF26q0kF1IUxZIFPAVW98x/a+qp8L2M/+HMhETRE6S8TxpZ7KGXAAAAAElFTkSuQmCC">
        </a>
    </div>

    <!-- Timeline -->
    <div id="ci-timeline" class="tab">
        <table class="timeline">
            <thead>
            <tr>
                <th class="debug-bar-width30">NAME</th>
                <th class="debug-bar-width10">COMPONENT</th>
                <th class="debug-bar-width10">DURATION</th>
                <cfloop from="0" to="#Val(segmentCount) - 1#" index="i">
                    <th>#i * Val(segmentDuration)# ms</th>
                </cfloop>
            </tr>
            </thead>
            <tbody>
            #toolbar.renderTimeline(collectors, startTime, segmentCount, segmentDuration, styles)#
            </tbody>
        </table>
    </div>

    <!-- Collector-provided Tabs -->
    <cfloop from="1" to="#ArrayLen(collectors)#" index="n">
        <cfset c = collectors[n]>
        <cfif c["isEmpty"] IS "false">
            <cfif c["hasTabContent"] IS "true">
                <div id="ci-#c["titleSafe"]#" class="tab">
                    <h2>#c["title"]# <span>#c["titleDetails"]#</span></h2>

                    <cfif IsSimpleValue(c["display"])>#c["display"]#<cfelse>#parser.setData(c["display"]).render("_" & c["titleSafe"] & ".tpl")#</cfif>
                </div>
            </cfif>
        </cfif>
    </cfloop>

    <!-- In & Out -->
    <div id="ci-vars" class="tab">

        <!-- VarData from Collectors -->
        <cfif array_key_exists("varData", vars)>
            <cfset headings = vars["varData"].keySet().iterator()>
            <cfloop condition="headings.hasNext()">
                <cfset heading = headings.next()>
                <cfset items = vars["varData"].get(heading)>

                <a class="debug-bar-vars" data-toggle="datatable" data-table="#LCase(Replace(heading, " ", "-", "all"))#">
                    <h2>#heading#</h2>
                </a>

                <cfif IsStruct(items)>

                    <table id="#LCase(Replace(heading & "_table", " ", "-", "all"))#">
                        <tbody>
                        <cfset keys = items.keySet().iterator()>
                        <cfloop condition="keys.hasNext()">
                            <cfset key = keys.next()>
                            <tr>
                                <td>#key#</td>
                                <td>#items.get(key)#</td>
                            </tr>
                        </cfloop>
                        </tbody>
                    </table>

                <cfelse>
                    <p class="muted">No data to display.</p>
                </cfif>
            </cfloop>
        </cfif>

        <!-- Session -->
        <a class="debug-bar-vars" data-toggle="datatable" data-table="session">
            <h2>Session User Data</h2>
        </a>

        <p class="muted">Session doesn't seem to be active.</p>

        <h2>Request <span>( #vars["request"]# )</span></h2>

        <cfif array_key_exists("get", vars)>
            <a class="debug-bar-vars" data-toggle="datatable" data-table="get">
                <h3>GET</h3>
            </a>

            <table id="get_table">
                <tbody>
                <cfset keys = vars["get"].keySet().iterator()>
                <cfloop condition="keys.hasNext()">
                    <cfset key = keys.next()>
                    <tr>
                        <td>#key#</td>
                        <td>#vars["get"].get(key)#</td>
                    </tr>
                </cfloop>
                </tbody>
            </table>
        </cfif>

        <cfif array_key_exists("post", vars)>
            <a class="debug-bar-vars" data-toggle="datatable" data-table="post">
                <h3>POST</h3>
            </a>

            <table id="post_table">
                <tbody>
                <cfset keys = vars["post"].keySet().iterator()>
                <cfloop condition="keys.hasNext()">
                    <cfset key = keys.next()>
                    <tr>
                        <td>#key#</td>
                        <td>#vars["post"].get(key)#</td>
                    </tr>
                </cfloop>
                </tbody>
            </table>
        </cfif>

        <cfif array_key_exists("headers", vars)>
            <a class="debug-bar-vars" data-toggle="datatable" data-table="request_headers">
                <h3>Headers</h3>
            </a>

            <table id="request_headers_table">
                <tbody>
                <cfset keys = vars["headers"].keySet().iterator()>
                <cfloop condition="keys.hasNext()">
                    <cfset key = keys.next()>
                    <tr>
                        <td>#key#</td>
                        <td>#vars["headers"].get(key)#</td>
                    </tr>
                </cfloop>
                </tbody>
            </table>
        </cfif>

        <cfif array_key_exists("cookies", vars)>
            <a class="debug-bar-vars" data-toggle="datatable" data-table="cookie">
                <h3>Cookies</h3>
            </a>

            <table id="cookie_table">
                <tbody>
                <cfset keys = vars["cookies"].keySet().iterator()>
                <cfloop condition="keys.hasNext()">
                    <cfset key = keys.next()>
                    <tr>
                        <td>#key#</td>
                        <td>#vars["cookies"].get(key)#</td>
                    </tr>
                </cfloop>
                </tbody>
            </table>
        </cfif>

        <h2>Response
            <span>( #vars["response"]["statusCode"]# - #vars["response"]["reason"]# )</span>
        </h2>

        <cfif array_key_exists("headers", vars["response"])>
            <cfif vars["response"]["headers"].size() GT 0>
                <a class="debug-bar-vars" data-toggle="datatable" data-table="response_headers">
                    <h3>Headers</h3>
                </a>

                <table id="response_headers_table">
                    <tbody>
                    <cfset keys = vars["response"]["headers"].keySet().iterator()>
                    <cfloop condition="keys.hasNext()">
                        <cfset key = keys.next()>
                        <tr>
                            <td>#key#</td>
                            <td>#vars["response"]["headers"].get(key)#</td>
                        </tr>
                    </cfloop>
                    </tbody>
                </table>
            </cfif>
        </cfif>
    </div>

    <!-- Config Values -->
    <div id="ci-config" class="tab">
        <h2>System Configuration</h2>

        #parser.setData(config).render("_config.tpl")#
    </div>
</div>
<style>
<cfset names = styles.keySet().iterator()>
<cfloop condition="names.hasNext()">
<cfset name = names.next()>.#name# { #styles.get(name)# }
</cfloop>
</style></cfoutput>
