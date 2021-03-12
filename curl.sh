#!/bin/sh

curl -X POST http://localhost:4000/api/users -H "Content-Type: application/json" -d '{"user": {"username": "user1", "password": "password"}}'
