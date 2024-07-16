# Find all Users with a badpassword count greater than 0
Find-SMAUser | Foreach-object {get-smauser -email $_} | Where-Object {$_.badPasswordCount -notlike '0'} |select-object email,name,badPasswordCount
