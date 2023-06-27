#!/bin/bash

# Sprawdzenie, czy komputer ma kartę graficzną
lspci | grep -i "VGA" > /dev/null

if [ $? -eq 0 ]; then
  echo "Komputer ma kartę graficzną."
  # Tutaj wpisz akcję do wykonania, jeśli komputer ma kartę graficzną
else
  echo "Komputer nie ma karty graficznej."
  # Tutaj wpisz akcję do wykonania, jeśli komputer nie ma karty graficznej
fi 