#!/bin/sh

# Performs an HTTP request
#
# Usage: ./request [request]
#   request - a custom request name (optional)
#
# Dependencies: curl, jq
#   curl - to perform HTTP requests (required)
#   jq - to format the JSON response (optional - remove pipe to jq in request())
#
# Author: Joshua Hong


# Parameters
# Change below and run ./request
# token and content are optional - to remove set to empty string

# Constants
protocol="HTTP/1.1"
hostname="http://localhost:8008"
token="token"

# Variables
method="POST"
path="/_matrix/client/r0/user_directory/search"
content='{
    "search_term": "josh",
    "limit": 10
}'


# Requests
# Create a custom function with name [request] and run ./request [request]
# Functions should only change the above variables
# Functions cannot be named "request", "setRequest" "main", "usage", or "help"
# Function names should be unique - same name functions will be overridden

# Registers a new user and returns an access token
register() {
    username="josh"
    password="password"

    token=""
    method="POST"
    path="/_matrix/client/r0/register?kind=user"
    content='{
        "auth": {
            "type": "m.login.dummy"
        },
        "username": "'"${username}"'",
        "password": "'"${password}"'"
    }'
}

# Authenticates a user and returns an access token
login() {
    username="josh"
    password="password"

    token=""
    method="POST"
    path="/_matrix/client/r0/login"
    content='{
        "type": "m.login.password",
        "identifier": {
            "type": "m.id.user",
            "user": "'"${username}"'"
        },
        "password": "'"${password}"'"
    }'
}

# Creates a public room and returns the room information
createPublicRoom() {
    roomAliasName="publicroom"
    name="public room name"
    topic="public room topic"

    method="POST"
    path="/_matrix/client/r0/createRoom"
    content='{
        "visibility": "public",
        "preset": "public_chat",
        "room_alias_name": "'"${roomAliasName}"'",
        "name": "'"${name}"'",
        "topic": "'"${topic}"'"
    }'
}

# Creates a private room and returns the room information
createPrivateRoom() {
    roomAliasName="privateroom"
    name="private room name"
    topic="private room topic"

    method="POST"
    path="/_matrix/client/r0/createRoom"
    content='{
        "visibility": "private",
        "preset": "private_chat",
        "room_alias_name": "'"${roomAliasName}"'",
        "name": "'"${name}"'",
        "topic": "'"${topic}"'"
    }'
}

# Lists public rooms on the server
getPublicRooms() {
    method="GET"
    path="/_matrix/client/r0/publicRooms"
    content=""
}


# Driver code
# Don't change below

# Prints the program usage
usage() {
    echo "Usage: ./request [request]"
}

# Sets the above parameters based on the optional custom request name provided
setRequest() {
    if [ "${#}" -eq 0 ]; then
        return
    fi
    if [ "${#}" -gt 1 ] ; then
        echo "Error: Too many arguments"
        usage
        exit
    fi
    request="$1"
    if [ "${request}" = "help" ] || [ "${request}" = "usage" ] ; then
        usage
        exit
    fi
    if [ "${request}" = "request" ] || [ "${request}" = "setRequest" ] \
            || [ "${request}" = "main" ] || [ "${request}" = "usage" ]; then
        echo "Error: Invalid request name"
        usage
        exit
    fi
    requestType="$(command -V "${request}" 2> /dev/null)"
    if [ -z "${requestType}" ] || [ -n "${requestType##*is a function*}" ]; then
        echo "Error: Request does not exist"
        usage
        exit
    fi

    ${request}
}

# Executes the HTTP request based on the above parameters
request() {
    curl \
        -X "${method}" \
        -H "Content-Type: application/json" \
        ${token:+-H "Authorization: Bearer ${token}"} \
        ${content:+-d "${content}"} \
        "${hostname}${path}" \
        "${protocol}" \
        2> /dev/null \
        | jq
}

main() {
    setRequest "${@}"
    request
}

main "${@}"
