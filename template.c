#include <stdio.h>



    int sum_int(int *xs, size_t len) {
        int sum = 0;
        for(size_t i = 0; i < len; i++) {
            sum += xs[i];
        }
        return sum;
    }

int main() {
    int x = sum_int({strlen("foo"), strlen("bar")});
    printf("%i\n", x)
    return 0;
}
    
