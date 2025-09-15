# CouchDB

## Commands

1. Get password
```sh
kubectl -n couchdb get secret/couchdb-couchdb -o go-template='{{ .data.adminPassword }}' | base64 --decode
```

2. Credentials
```
Username: Admin
Password: <password from the step 1>
```

