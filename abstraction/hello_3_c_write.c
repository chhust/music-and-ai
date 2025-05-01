#include <unistd.h>                 // works under Linux and macOS, but not Windows

int main() {
    const char* msg = "Hello, world!\n";
    write(1, msg, 14);
    return 0;
}
