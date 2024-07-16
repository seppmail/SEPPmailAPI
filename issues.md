# Issues found in API

## Find-SMAUser

When i use the 'partialMatch' query string and use 'admin' as string all users are emitted. Same with partialMatch 'r', also admin@local and mde@local are emitted.
Reason is that partialmatch also looks into the name field.

## Set-SMAUser

- Change of customer is not possible - User not found error.
- Why do i need to add a Serial_or_key when changing the user ?






