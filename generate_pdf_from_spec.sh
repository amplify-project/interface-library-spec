#!/bin/bash

pandoc -V papersize:a4 -V geometry:margin=30mm -o amplify_interface_spec.pdf README.md
