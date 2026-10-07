#!/bin/bash
while true; do
  clear
  fecha=$(date "+%A %d de %B, %Y" | tr '[:lower:]' '[:upper:]')
  hora=$(date "+%H:%M:%S")
  printf "%s   %s\n" "$hora" "$fecha"
  sleep 1
done
