#include <sys/types.h>
#include <unistd.h>

int main(int argc, char **argv) {
    if (argc < 2) return 2;
    pid_t child = fork();
    if (child < 0) return 1;
    if (child > 0) return 0;
    if (setsid() < 0) _exit(1);
    execvp(argv[1], argv + 1);
    _exit(127);
}
