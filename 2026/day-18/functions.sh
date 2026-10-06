#!/bin/bash
# Basic functions with arguments

greet() {
    echo "Hello, $1!"
}

add() {
    local sum=$(( $1 + $2 ))
    echo "$1 + $2 = $sum"
}

greet "Robin"
greet "DevOps"
add 10 25
