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

# Constants
protocol="HTTP/1.1"
host="http://localhost:8008"
token="_ZavbrIdDy6nyegA4aGSc3tmpn_j38czDdbObwtQoMA"

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
# Each line should contain the function name and description separated by tab(s)
requestNames="
    register\t\tRegisters a new user and returns an access token
    login\t\tAuthenticates a user and returns an access token
    createPublicRoom\tCreates a public room and returns the room information
    createPrivateRoom\tCreates a private room and returns the room information
    getPublicRooms\tLists public rooms on the server
"

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
            echo "    If curl fails, exit code is the same as that of curl."
            exit
            ;;
        l)
            if [ -z "${requestNames}" ]; then
                echo "No request names defined"
                exit
            fi
            echo -n "Request names:"
            while IFS= read -r line; do
                if [ -n "${line}" ]; then
                    echo "${line}"
                fi
            done < <(echo -e "\n" "${requestNames}")
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

# Execute the HTTP request based on the above parameters
response="$(curl \
    -X "${method}" \
    -H "Content-Type: application/json" \
    ${token:+-H "Authorization: Bearer ${token}"} \
    ${data:+-d "${data}"} \
    "${host}${path}" \
    "${protocol}" \
    2> /dev/null)"
responseExitCode="${?}"

# Check for a valid request
if [ -z "${response}" ]; then
    >&2 echo "Error: Bad request"
    exit "${responseExitCode}"
fi

# Check if formatter is a valid command
if [ -n "${formatter}" ] && ! command -v "${formatter}" > /dev/null 2>&1; then
    >&2 echo "Error: Invalid formatter \"${formatter}\""
    exit 1
fi

# Check if pipe to formatter is valid
if [ -n "${formatter}" ]; then
    formattedResponse="$(echo "${response}" | "${formatter}")"
    formattedResponseExitCode="${?}"
    if [ "${formattedResponseExitCode}" -ne 0 ] \
            || [ -z "${formattedResponse}" ]; then
        >&2 echo "Error: Invalid formatter \"${formatter}\""
        exit 1
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
