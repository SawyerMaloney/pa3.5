#pragma once

#include <assert.h>
#include <stdbool.h>

typedef char * string;

typedef struct UBoolList_ * UBoolList;

struct UBoolList_ {
    bool head;
    UBoolList tail;
};

void * malloc_checked(int);
string make_String(const char * const);
UBoolList make_UBoolList(bool head, UBoolList tail);

