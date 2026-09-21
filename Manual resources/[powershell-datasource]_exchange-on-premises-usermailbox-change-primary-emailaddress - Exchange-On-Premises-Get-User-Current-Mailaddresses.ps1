# variables configured in form
$mailbox = $datasource.selectedmailbox

try {
    foreach ($emailAddress in $mailbox.EmailAddresses) {
        $isPrimary = $false
        if ($emailAddress.split(":")[0] -clike "SMTP*") {
            $isPrimary = $true
        }
        $emailAddress = $emailAddress.replace("SMTP:", "").replace("smtp:", "")

        $returnObject = @{
            IsPrimary    = $isPrimary
            EmailAddress = $emailAddress
        }
        Write-Output $returnObject
    }
    
} catch {
    $ex = $PSItem
    if (-not [string]::IsNullOrEmpty($ex.Exception.Message)) {
        $warningMessage = "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
        $auditMessage = "Error $($actionMessage). Error: $($ex.Exception.Message)"
    }
    else {
        $warningMessage = "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception)"
        $auditMessage = "Error $($actionMessage). Error: $($ex.Exception)"
    }
    Write-Warning $warningMessage
    Write-Error $auditMessage
    # exit # use when using multiple try/catch and the script must stop
}

