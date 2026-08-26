# Changelog

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [2.0.0] - 2026-08-26

### Added

- Added checkbox option to update Active Directory UserPrincipalName along with primary email address
- Added support for wildcard search across Name, SamAccountName, Alias, and PrimarySmtpAddress fields
- Added comprehensive error handling with actionMessage context for better troubleshooting
- Added explicit command imports (Get-Mailbox, Set-Mailbox) to session for better performance
- Added propertiesToSelect array to limit memory usage and speed up datasource processing
- Added ExchangeGuid to mailbox properties for more reliable identification
- Added HiddenFromAddressListsEnabled field to mailbox grid display

### Changed

- Changed mailbox search from OrganizationalUnit-based to Filter-based queries for better flexibility
- Changed from Invoke-Command pattern to direct cmdlet execution after Import-PSSession
- Improved proxy address handling logic to prevent duplicates and properly manage SMTP prefix casing
- Enhanced audit logging with more detailed messages and consistent use of InstanceId for session tracking
- Refactored error handling to use try-catch-finally blocks with detailed error messages including line numbers
- Updated form field names for better clarity (gridmailbox → selectedmailbox, grid → selectedmailaddres)
- Changed datasource naming convention to include connector context in names
- Improved session cleanup in finally block to ensure disconnection regardless of errors

### Fixed

- Fixed potential duplicate email addresses when setting primary address
- Fixed inconsistent SMTP prefix handling in proxy addresses
- Improved error message formatting to include script line numbers and full context

### Removed

- Removed ExchangeSearchOU variable dependency (no longer needed with Filter-based search)

## [1.0.2] - 2022-08-24

### Added

- Added version number and updated code for SA-agent and auditlogging

## [1.0.1] - 2021-11-16

### Added

- Added version number and updated all-in-one script

## [1.0.0] - 2021-04-29

Initial release of HelloID-Conn-SA-Full-Exchange-On-Premises-Usermailbox-Change-Primary-Emailaddress.

### Added

- Initial release for changing primary email address on Exchange On-Premises user mailboxes
