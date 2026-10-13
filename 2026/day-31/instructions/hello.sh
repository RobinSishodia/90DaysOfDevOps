#!/bin/bash
echo "Hello from $(hostname)"
echo "Working directory: $(pwd)"
echo "Files here: $(ls)"
echo "Build info: $(cat build-info.txt)"
