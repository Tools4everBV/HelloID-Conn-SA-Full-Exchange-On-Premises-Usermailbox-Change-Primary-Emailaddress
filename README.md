# HelloID-Conn-SA-Full-Exchange-On-Premises-Usermailbox-Change-Primary-Emailaddress

| :information_source: Information                                                                                                                                                                                                                                                                                                                                                          |
| :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| This repository contains the connector and configuration code only. The implementer is responsible for acquiring the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements. |

## Description

_HelloID-Conn-SA-Full-Exchange-On-Premises-Usermailbox-Change-Primary-Emailaddress_ is a template designed for use with HelloID Service Automation (SA) Delegated Forms. It can be imported into HelloID and customized according to your requirements.

By using this delegated form, you can change the primary email address of Exchange On-Premises user mailboxes. The following workflow is available:

1.  Search for a mailbox by entering a search value (wildcard search across Name, Alias, SamAccountName, or PrimarySmtpAddress)
2.  Select the target mailbox from the search results
3.  View all email addresses associated with the selected mailbox (primary address marked with IsPrimary = true)
4.  Select the email address to set as the new primary address
5.  Optionally enable the checkbox to update the Active Directory UserPrincipalName to match the new primary email address
6.  The primary email address is updated in Exchange, and all proxy addresses are reconfigured accordingly
7.  If selected, the UserPrincipalName is updated in Active Directory

## Getting started

### Requirements

- **Exchange On-Premises Access**:<br>
  Remote PowerShell access to Exchange On-Premises server is required. The connection URI must be accessible from the HelloID Agent or service that executes the delegated form. Ensure the Exchange server is configured to allow remote PowerShell connections.
- **Active Directory Access** (Optional):<br>
  If using the UserPrincipalName update feature, the HelloID service account must have permissions to modify the UserPrincipalName attribute in Active Directory for the target user objects.
- **Exchange Mailbox Permissions**:<br>
  The service account must have sufficient Exchange permissions to read mailbox properties and modify email addresses. Typically requires Exchange Organization Management or Recipient Management role group membership.

### Connection settings

The following user-defined variables are used by the connector.

| Setting               | Description                                                                                                   | Mandatory |
| --------------------- | ------------------------------------------------------------------------------------------------------------- | --------- |
| ExchangeConnectionUri | The URI to the Exchange On-Premises PowerShell endpoint (e.g., http://exchangeserver.domain.local/powershell) | Yes       |
| ExchangeAdminUsername | The username for Exchange administration (e.g., DOMAIN\username)                                              | Yes       |
| ExchangeAdminPassword | The password for the Exchange admin account                                                                   | Yes       |

## Remarks

### Authentication Method

- The connector uses Default authentication when establishing the PowerShell session to Exchange. This typically uses Kerberos authentication in a domain environment. Ensure the HelloID service is running under an account that can authenticate to Exchange.

### UserPrincipalName Update

- The optional UserPrincipalName update feature requires the Active Directory PowerShell module to be available on the system executing the task. This feature will attempt to update the UPN to match the newly selected primary email address.

### Session Management

- The connector explicitly imports only required Exchange cmdlets (Get-Mailbox, Set-Mailbox) to optimize session performance and reduce memory usage. The session is automatically cleaned up in a finally block to ensure proper disconnection even if errors occur.

### Proxy Address Handling

- When setting a new primary email address, the connector automatically converts the existing primary SMTP address to a secondary (smtp:) address and promotes the selected address to primary (SMTP:). All existing proxy addresses are preserved, and duplicates are prevented.

### Search Flexibility

- The mailbox search uses Exchange filter queries instead of OU-scoped searches, providing more flexibility. Users can search across Name, SamAccountName, Alias, and PrimarySmtpAddress fields using wildcard patterns.

### Error Handling

- All error messages include the script line number and context for easier troubleshooting. Audit logs are sent to HelloID for both successful operations and errors.

## Development resources

### API documentation

- [Connect to Exchange servers using remote PowerShell](https://learn.microsoft.com/en-us/powershell/exchange/connect-to-exchange-servers-using-remote-powershell)
- [Get-Mailbox cmdlet](https://learn.microsoft.com/en-us/powershell/module/exchange/get-mailbox)
- [Set-Mailbox cmdlet](https://learn.microsoft.com/en-us/powershell/module/exchange/set-mailbox)
- [Remove-PSSession cmdlet](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/remove-pssession)

## Getting help

> :bulb: **Tip:**  
> _For more information on Delegated Forms, please refer to our [documentation](https://docs.helloid.com/en/service-automation/delegated-forms.html) pages_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
