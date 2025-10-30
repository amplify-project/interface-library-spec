#!/bin/bash

if [ $# -ne 1 ]; then
  echo "USAGE: $0 output_file"
  exit 1
fi

output_file=$1

pandoc -V papersize:a4 -V geometry:margin=30mm -o $output_file README.md
