/* Testcase1 */

/* C subset:
 * Variable declaration/initialization
 * Int
 * Simple statement
 * for loop
 * Comment /*
 */
#include <stdio.h>
#include "tyler.h"

#ifdef _DEBUG
    #define PI 3.14
#else
    #define PI M_PI
#endif

struct node_t
{
    int id;
    char *name;
};

// main function
int main(int argc, char *argv[])
{
    int n, w, x, y, z;
    int num = 1000;

    for (n = 0; n <= num; ++n)
    {
        w = n + 1;
        x = n - 2;
        y = n * 3;
        z = n / 4;
        printf("Result:\n");
        printf("w=%d\n", w);
        printf("x=%d\n", x);
        printf("y=%d\n", y);
        printf("z=%d\n", z);
    }
    return 0;
}
