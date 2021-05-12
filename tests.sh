#!/bin/sh

if ! which dmd 2>/dev/null; then
  # dmd not found, try ldc2
  export DMD=ldc2
fi

for F in test*.dt
do
  echo "${F}"
  ./dmt --overwrite -run "${F}"
  echo Retun code: $?
  echo
done


echo "Executing test25.dt directly via #!"
./test25.dt
echo Retun code: $?
echo
