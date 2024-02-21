#!/bin/sh
# Author: Amittai Aviram - aviram@bc.edu

PROG=parsetest
INPUT_DIR=testcases
EXPECTED=expected_pa3.txt

echo Building $PROG ...
make clean && make
if [ $? != 0 ]
then
    echo "\n ***** BUILD FAILURE ***** \n"
    exit 1
fi

echo Building complete.

ERRORS=0
echo Running ...
for FILE in ${INPUT_DIR}/*.tig
do
    RESULT=$(./${PROG} ${FILE} 2>&1 | grep "syntax error" | grep -v test49.tig)
    if [[ -n ${RESULT} ]]
    then
        ERRORS=1
        printf "\n${RESULT}\n\n"
    fi
done
echo Running complete.
if [ $ERRORS -eq 0 ]
then
    printf "\n======== CORRECT ========\n\n"
else
    printf "\n See parse failures listed above.\n\n"
fi

make clean

