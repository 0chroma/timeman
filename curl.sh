#!/bin/sh

curl -X POST http://localhost:4000/api/users -H "Content-Type: application/json" -d '{"user": {"username": "user1", "password": "password"}}'

curl -X POST http://localhost:4000/api/users/signin -H "Content-Type: application/json" -d '{"username": "user1", "password": "password"}'

curl -X GET http://localhost:4000/api/entries -H "Authorization: Bearer ..."

curl -X DELETE http://localhost:4000/api/users/10 -H "Authorization: Bearer ..."
