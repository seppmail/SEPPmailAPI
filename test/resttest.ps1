# PUT /system/comments
$bodyHt = @{
    "name"     = 'Labnode2'
    "location" = "Azure Hypervisor"
    "objectid" = "944802f5-9060-43cb-badf-600528cc56ad"
    "contact"  = "System Admin"
    "comment"  = "Testsystem for release deployment and Powershell development"
}
$body = $bodyHt | ConvertTo-Json -Depth 10
$headersHt = @{
             "accept" = 'application/json'
    "X-SM-API-TOKEN"  = 'eeac5df8-83ad-42cd-8e28-d157f828437e'
    "X-SM-API-SECRET" = 'SZ7$$UW598b8V@wA#6'
}
$invokeParam = @{
    uri         = 'https://labnode2.seppmail365lab.com:8445/v1/system/comment'
    method      = 'PUT'
    headers     = $headersHt
    body        = $body
    ContentType = 'application/json'
}
Invoke-RestMethod @invokeParam
# $result = Invoke-RestMethod -uri $uri -Method PUT -Headers $headersHT -body $body -ContentType 'application/json' #; charset=utf-8'

