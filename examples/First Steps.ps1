# Testing Connectivity
Test-SMAConfiguration -ConfigurationName RC12

# Working with Users
Get-Command -Module SEPPmailAPI -noun 'SMAuser'

Find-SMAuser -list
Find-SMAuser 
Find-SMAuser|select-object -first 1
Find-SMAuser|select-object email,customer


