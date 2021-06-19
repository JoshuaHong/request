#!/bin/sh

# Performs an HTTP request
#
# Usage: request [-h | -l | requestName]
#  -h - print the help menu
#  -l - print the list of request names
#   requestName - a custom request name (optional)
#
# Dependencies: curl
#   curl - to perform HTTP requests (required)
#
# Author: Joshua Hong


# Formatter
# Pipes the JSON response output to the program specified below
# Optional - to remove set to empty string
formatter="jq"


# Parameters
# Change below and run ./request
# token and data are optional - to remove set to empty string
# Supports HTTP/0.9, HTTP/1.0, HTTP/1.1, HTTP/2-prior-knowledge, HTTP/2, HTTP/3

# Constants
protocol="HTTP/1.1"
host="http://localhost:8008"
contentType="application/json"
token="token"

# Variables
method="POST"
path="/_matrix/client/r0/user_directory/search"
data='{
    "search_term": "josh",
    "limit": 10
}'


# Requests
# Create a custom function below with name [request] and run ./request [request]
# Functions should only change the above variables
# Function names should be unique - same name functions will be overridden
# Add the all function names and descriptions to the list below to be printed

# List of function names and descriptions to be printed using the "-l" flag
# Each line should contain the function name and description separated as needed
requestNames="
    register             Registers a new user and returns an access token
    login                Authenticates a user and returns an access token
    createPublicRoom     Creates a public room and returns the room information
    createPrivateRoom    Creates a private room and returns the room information
    getPublicRooms       Lists public rooms on the server"

# Registers a new user and returns an access token
register() {
    username="josh"
    password="password"

    token=""
    method="POST"
    path="/_matrix/client/r0/register?kind=user"
    data='{
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
    data='{
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
    data='{
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
    data='{
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
    data=""
}


# Driver code
# Don't change below

# Check for valid command-line input
if [ "${#}" -gt 1 ]; then
    >&2 echo "Error: Too many arguments"
    >&2 echo "Usage: request [-h | -l | requestName]"
    exit 1
fi

# Parse command-line options
options=":hl"
while getopts "${options}" option; do
    case "${option}" in
        h)
            echo "Usage: request [-h | -l | requestName]"
            echo ""
            echo "Performs an HTTP request."
            echo ""
            echo "Options:"
            echo "    -h             print the help menu"
            echo "    -l             print the list of request names"
            echo "    requestName    set the specified request parameters"
            echo ""
            echo "Exit Status:"
            echo "    Returns success if request is valid, failure otherwise."
            echo "    If curl fails, the exit code is the same as that of curl."
            echo "    For any other failure, the exit code is 1."
            exit
            ;;
        l)
            if [ -z "${requestNames}" ]; then
                echo "No request names defined"
                exit
            fi
            printf "%s" "Request names:"
            echo "${requestNames}"
            exit
            ;;
        *)
            >&2 echo "Error: Invalid option \"${OPTARG}\""
            >&2 echo "Usage: request [-h | -l | requestName]"
            exit 1
            ;;
    esac
done

# Set the above parameters based on the custom request name if provided
if [ "${#}" -eq 1 ]; then
    requestName="${1}"
    requestType="$(command -V "${requestName}" 2> /dev/null)"
    if [ -z "${requestType}" ] || [ -n "${requestType##*is a function*}" ]; then
        >&2 echo "Error: Request \"${requestName}\" is not defined"
        >&2 echo "Usage: request [-h | -l | requestName]"
        exit 1
    fi
    ${requestName}  # Execute the requestName function
fi

# Verify the protocol
if [ "${protocol}" == "HTTP/0.9" ]; then
    protocol="0.9"
elif [ "${protocol}" == "HTTP/1.0" ]; then
    protocol="1.0"
elif [ "${protocol}" == "HTTP/1.1" ]; then
    protocol="1.1"
elif [ "${protocol}" == "HTTP/2-prior-knowledge" ]; then
    protocol="2-prior-knowledge"
elif [ "${protocol}" == "HTTP/2" ]; then
    protocol="2"
elif [ "${protocol}" == "HTTP/3" ]; then
    protocol="3"
else
    protocol="1.1"
    >&2 echo "Warning: Invalid protocol. Defaults to HTTP/1.1"
fi

# Execute the HTTP request based on the above parameters
response="$(curl \
    --silent --show-error \
    --http"${protocol}" \
    -X "${method}" \
    -H "Content-Type: ${contentType}" \
    ${token:+-H "Authorization: Bearer ${token}"} \
    ${data:+-d "${data}"} \
    "${host}${path}")"
responseExitCode="${?}"

# Check for a valid request
if [ -z "${response}" ]; then
    >&2 echo "Error: No response"
    exit "${responseExitCode}"
fi

# Check if formatter is a valid command
if [ -n "${formatter}" ] && ! command -v "${formatter}" > /dev/null 2>&1; then
    >&2 echo "Error: Invalid formatter \"${formatter}\""
    formatter=""
fi

# Check if pipe to formatter is valid
if [ -n "${formatter}" ]; then
    formattedResponse="$(echo "${response}" | "${formatter}")"
    formattedResponseExitCode="${?}"
    if [ "${formattedResponseExitCode}" -ne 0 ] \
            || [ -z "${formattedResponse}" ]; then
        >&2 echo "Error: Invalid formatter \"${formatter}\""
        formatter=""
    fi
fi

# Print the response
if [ "${responseExitCode}" -ne 0 ]; then
    if [ -n "${formatter}" ]; then
        echo "${response}" | >&2 "${formatter}"
    else
        >&2 echo "${response}"
    fi
    exit "${responseExitCode}"
else
    if [ -n "${formatter}" ]; then
        echo "${response}" | "${formatter}"
    else
        echo "${response}"
    fi
    exit
fi
