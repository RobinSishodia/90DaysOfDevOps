#!/bin/bash
# local vs global variables inside functions

with_local() {
    local msg="I am LOCAL to with_local()"
    echo "inside with_local:    $msg"
}

without_local() {
    leaked="I was set inside without_local() but I leak out"
    echo "inside without_local: $leaked"
}

with_local
echo "outside after with_local:    [${msg:-<empty>}]"

without_local
echo "outside after without_local: [$leaked]"
