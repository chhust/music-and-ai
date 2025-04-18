#include <unistd.h>

int main() {
    const char *msg = "Hello, world!\n";
    write(1, msg, 14);
    return 0;
}
