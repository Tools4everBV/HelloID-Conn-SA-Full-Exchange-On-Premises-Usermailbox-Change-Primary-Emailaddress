# Variables configured in form
$mailbox = $form.selectedmailbox
$selectedmailaddress = $form.selectedmailaddres
$blnSetUpn = [System.Convert]::ToBoolean($form.blnsetupn)

# Build proxy address with appropriate prefix based on whether it should be primary
if ($selectedmailaddress.IsPrimary -eq 'false') {
    $mailboxProxyAddress = "SMTP:$($selectedmailaddress.EmailAddress)"
}
else {
    $mailboxProxyAddress = "smtp:$($selectedmailaddress.EmailAddress)"
}

# Global variables
# Outcommented as these are set from Global Variables
# $ExchangeConnectionUri = ""
# $ExchangeAdminUsername = ""
# $ExchangeAdminPassword = ""

# Fixed values
$commands = @(    
    "Set-Mailbox"
)

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

# Set debug logging
$VerbosePreference = "SilentlyContinue"
$InformationPreference = "Continue"
$WarningPreference = "Continue"

#region functions
#endregion functions

try {
    # Create credentials
    $actionMessage = "creating credentials object"
    
    $securePassword = ConvertTo-SecureString -String $ExchangeAdminPassword -AsPlainText -Force
    $credential = [System.Management.Automation.PSCredential]::new($ExchangeAdminUsername, $securePassword)
    
    Write-Verbose "Created credentials for user [$ExchangeAdminUsername]"

    # Connect to Exchange On-Premises
    # Docs: https://learn.microsoft.com/en-us/powershell/exchange/connect-to-exchange-servers-using-remote-powershell
    $actionMessage = "connecting to Exchange On-Premises"

    $sessionOptionParams = @{
        SkipCACheck         = $false
        SkipCNCheck         = $false
        SkipRevocationCheck = $false
    }

    $sessionOption = New-PSSessionOption @sessionOptionParams

    $sessionParams = @{
        Authentication    = 'Default'
        ConfigurationName = 'Microsoft.Exchange'
        Credential        = $credential
        ConnectionUri     = $ExchangeConnectionUri
        SessionOption     = $sessionOption
        ErrorAction       = "Stop"
    }

    $exchangeSession = New-PSSession @sessionParams
    $null = Import-PSSession -Session $exchangeSession -DisableNameChecking -AllowClobber -CommandName $commands -ErrorAction Stop

    # Send initial audit log
    $Log = @{
        Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
        System            = "Exchange On-Premises" # optional (free format text) 
        Message           = "Successfully connected to Exchange using URI [$ExchangeConnectionUri]" # required (free format text) 
        IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
        TargetDisplayName = $ExchangeConnectionUri # optional (free format text) 
        TargetIdentifier  = $([string]$exchangeSession.InstanceId) # optional (free format text) 
    }
    Write-Information -Tags "Audit" -MessageData $log

    if ($selectedmailaddress.IsPrimary -eq "true") {
        Write-Information "No changes where made. The selected primary address [$($selectedmailaddress.EmailAddress)] is the same as the existing primary address"        
        $Log = @{
            Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
            System            = "Exchange On-Premises" # optional (free format text) 
            Message           = "No changes where made. The selected primary address [$($selectedmailaddress.EmailAddress)] is the same as the existing primary address" # required (free format text) 
            IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
            TargetDisplayName = $mailbox.DisplayName # optional (free format text) 
            TargetIdentifier  = $mailbox.ExchangeGuid # optional (free format text) 
        }
        #send result back  
        Write-Information -Tags "Audit" -MessageData $log
    }

    if ($selectedmailaddress.IsPrimary -eq "false") {         
        # Get current email addresses and prepare new email address list, while keeping existing proxy addresses (except the current address if already present)
        $currentAddresses = $mailbox.EmailAddresses
        $proxyAddresses = @()

        # Extract the email address without prefix for comparison
        $emailAddressOnly = $mailboxProxyAddress -replace '^(smtp|SMTP):', ''

        foreach ($address in $currentAddresses) {
            # If setting as primary, convert any existing primary SMTP to secondary
            if ($address.StartsWith('SMTP:')) {
                $address = $address -replace 'SMTP:', 'smtp:'
            }
            # Remove the address if it already exists (to avoid duplicates)
            if ($address -ne "smtp:$emailAddressOnly" -and $address -ne "SMTP:$emailAddressOnly") {
                $proxyAddresses += $address
            }
        }
        $proxyAddresses += $mailboxProxyAddress

        $updateMailboxParams = @{
            Identity                  = $mailbox.ExchangeGuid
            EmailAddresses            = $proxyAddresses
            EmailAddressPolicyEnabled = $false
            Confirm                   = $false
            ErrorAction               = 'Stop'
        }
        $actionMessage = "setting proxyaddresses on mailbox"
        $null = Set-Mailbox @updateMailboxParams    

        Write-Information "Successfully set primary emailaddress to [$($selectedmailaddress.EmailAddress)] for [$($mailbox.DisplayName)]"
        $Log = @{
            Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
            System            = "Exchange On-Premises" # optional (free format text) 
            Message           = "Successfully set primary emailaddress to [$($selectedmailaddress.EmailAddress)] for [$($mailbox.DisplayName)]." # required (free format text) 
            IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
            TargetDisplayName = $($mailbox.DisplayName) # optional (free format text) 
            TargetIdentifier  = $([string]$mailbox.ExchangeGuid) # optional (free format text) 
        }
        #send result back  
        Write-Information -Tags "Audit" -MessageData $log    
    }
}
catch {
    $ex = $PSItem
    if (-not [string]::IsNullOrEmpty($ex.Exception.Message)) {
        $warningMessage = "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
        $auditMessage = "Error $($actionMessage). Error: $($ex.Exception.Message)"
    }
    else {
        $warningMessage = "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception)"
        $auditMessage = "Error $($actionMessage). Error: $($ex.Exception)"
    }

    # Send error audit log to HelloID
    $Log = @{
        Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
        System            = "Exchange On-Premises" # optional (free format text) 
        Message           = $auditMessage # required (free format text) 
        IsError           = $true # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
        TargetDisplayName = $mailbox.DisplayName # optional (free format text) 
        TargetIdentifier  = $mailbox.ExchangeGuid # optional (free format text) 
    }
    
    Write-Information -Tags "Audit" -MessageData $log
    Write-Warning $warningMessage
    Write-Error $auditMessage
}
finally {
    # Disconnect from Exchange
    # Docs: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/remove-pssession
    if ($null -ne $exchangeSession) {
        try {
            $deleteExchangeSessionSplatParams = @{
                Session     = $exchangeSession
                Confirm     = $false
                ErrorAction = "Stop"
            }
            $null = Remove-PSSession @deleteExchangeSessionSplatParams

            # Send disconnect audit log
            $Log = @{
                Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
                System            = "Exchange On-Premises" # optional (free format text) 
                Message           = "Successfully disconnected from Exchange using URI [$ExchangeConnectionUri]" # required (free format text) 
                IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
                TargetDisplayName = $ExchangeConnectionUri # optional (free format text) 
                TargetIdentifier  = $([string]$exchangeSession.InstanceId) # optional (free format text) 
            }
            Write-Information -Tags "Audit" -MessageData $log
        }
        catch {
            Write-Warning "Failed to disconnect from Exchange using URI [$ExchangeConnectionUri]. Error: $($_.Exception.Message)"
        }
    }
}

#Change UPN
if ($blnSetUpn) {    
    try {       
        $actionMessage = "getting aduser object"
        $userPrincipalName = $mailbox.UserPrincipalName
        $user = Get-ADUser -Filter { UserPrincipalName -eq $userPrincipalName } -Properties displayname

        if ($user) {
            $actionMessage = "setting userPrincipalName for aduser"
            Set-ADUser -Identity $user -UserPrincipalName $($selectedmailaddress.EmailAddress)
        
            Write-Information "Successfully changed userprincipalname to [$($selectedmailaddress.EmailAddress)] for [$($user.DisplayName)]"
            $Log = @{
                Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
                System            = "ActiveDirectory" # optional (free format text) 
                Message           = "Successfully changed userprincipalname for AD user $($user.DisplayName)" # required (free format text) 
                IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
                TargetDisplayName = $($user.DisplayName) # optional (free format text) 
                TargetIdentifier  = $([string]$user.SID.value) # optional (free format text) 
            }
            #send result back  
            Write-Information -Tags "Audit" -MessageData $log        
        }
    } 
    catch {
        $ex = $PSItem
        if (-not [string]::IsNullOrEmpty($ex.Exception.Message)) {
            $warningMessage = "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
            $auditMessage = "Error $($actionMessage). Error: $($ex.Exception.Message)"
        }
        else {
            $warningMessage = "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception)"
            $auditMessage = "Error $($actionMessage). Error: $($ex.Exception)"
        }

        # Send error audit log to HelloID
        $Log = @{
            Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
            System            = "ActiveDirectory" # optional (free format text) 
            Message           = $auditMessage # required (free format text) 
            IsError           = $true # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
            TargetDisplayName = $($mailbox.DisplayName) # optional (free format text) 
            TargetIdentifier  = $mailbox.ExchangeGuid # optional (free format text) 
        }
        
        Write-Information -Tags "Audit" -MessageData $log
        Write-Warning $warningMessage
        Write-Error $auditMessage
    }
}
