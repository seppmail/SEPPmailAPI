# Issues  in the API

## Find-SMAUser

When using 'partialMatch' query string and use i.e. 'admin' as string all users are emitted. Same with partialMatch 'r', also admin@local and mde@local are emitted.
Reason is that partialMatch also looks into the name field.

## Set-SMAUser

Change of customer is not possible - User not found error, bug reported.