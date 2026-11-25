<cfset __dir = GetDirectoryFromPath(GetCurrentTemplatePath())>
<cffile action="read" file="#__dir#debug.css" variable="__css">
<cfset __css = REReplace(__css, "[#Chr(13)##Chr(10)##Chr(9)# ]+", " ", "all")>
<!doctype html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="robots" content="noindex">

    <!--- Not ported yet: lang('Errors.whoops') --->
    <title>Whoops!</title>

    <style>
        <cfoutput>#__css#</cfoutput>
    </style>
</head>
<body>

    <div class="container text-center">

        <!--- Not ported yet: lang('Errors.whoops') --->
        <h1 class="headline">Whoops!</h1>

        <!--- Not ported yet: lang('Errors.weHitASnag') --->
        <p class="lead">We seem to have hit a snag. Please try again later...</p>

    </div>

</body>

</html>
