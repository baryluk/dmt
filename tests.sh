#!/bin/sh

BASEDIR="$(pwd)"

cd tests/

if ! which dmd 2>/dev/null; then
  # dmd not found, try ldc2
  export DMD=ldc2
fi

DMT="${BASEDIR}/dmt"

for F in test*.dt
do
  echo "${F}"
  "${DMT}" --overwrite -run "${F}"
  echo Retun code: $?
  echo
done

export PATH="${BASEDIR}:${PATH}"

echo "Executing test25.dt directly via #!"
./test25.dt
echo Retun code: $?
echo
