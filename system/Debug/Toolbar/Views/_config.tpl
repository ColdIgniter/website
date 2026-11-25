{# Difference: the engine version and the web server are shown where the original shows its language version and SAPI. #}
{# Not ported yet: the link to the docs (there is no site for the docs of ColdIgniter yet). #}

<table>
    <tbody>
        <tr>
            <td>ColdIgniter Version:</td>
            <td>{ ciVersion }</td>
        </tr>
        <tr>
            <td>Engine Version:</td>
            <td>{ engineVersion }</td>
        </tr>
        <tr>
            <td>Web Server:</td>
            <td>{ webServer }</td>
        </tr>
        <tr>
            <td>Environment:</td>
            <td>{ environment }</td>
        </tr>
        <tr>
            <td>Base URL:</td>
            <td>
                { if $baseURL == '' }
                    <div class="warning">
                        The $baseURL should always be set manually to prevent possible URL personification from external parties.
                    </div>
                { else }
                    { baseURL }
                { endif }
            </td>
        </tr>
        <tr>
            <td>Timezone:</td>
            <td>{ timezone }</td>
        </tr>
        <tr>
            <td>Locale:</td>
            <td>{ locale }</td>
        </tr>
        <tr>
            <td>Content Security Policy Enabled:</td>
            <td>{ if $cspEnabled } Yes { else } No { endif }</td>
        </tr>
    </tbody>
</table>
