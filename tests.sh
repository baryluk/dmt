#!/bin/sh

BASEDIR="$(pwd)"

cd tests/

if ! which dmd 2>/dev/null; then
  # dmd not found, try ldc2
  export DMD=ldc2
fi

DMT="${BASEDIR}/dmt"

if ! [ -x "${DMT}" ]; then
  echo "${DMT} not found"
  echo "Compile dmt first" >&2
  exit 1
fi

for F in test*.dt
do
  echo "${F}"
  # Feed empty file, because some programs expect inputs.
  echo | "${DMT}" --overwrite -run "${F}"
  echo Retun code: $?
  echo
done

export PATH="${BASEDIR}:${PATH}"

echo "Executing test25.dt directly via #!"
./test25.dt
echo Retun code: $?
echo
