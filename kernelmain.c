#include "x86.h"
#include "types.h"

extern void print_str(char*);
extern void print_int(int);

int main() {
    char *str = "aaaaaaa";

    print_str(str);
    print_str("\n");
    print_int(2500);
    return 0;
}