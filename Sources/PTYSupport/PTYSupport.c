#include "PTYSupport.h"

#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>
#include <util.h>

extern char **environ;

pid_t hafthi_spawn_shell(const char *shell, const char *home,
                         int *master_fd, uint16_t columns, uint16_t rows) {
    struct winsize size = { .ws_row = rows, .ws_col = columns };
    char *const arguments[] = { (char *)shell, "-l", NULL };
    pid_t pid = forkpty(master_fd, NULL, NULL, &size);
    if (pid == 0) {
        if (home != NULL) chdir(home);
        execve(shell, arguments, environ);
        _exit(127);
    }
    return pid;
}

int hafthi_resize_pty(int master_fd, uint16_t columns, uint16_t rows) {
    struct winsize size = { .ws_row = rows, .ws_col = columns };
    return ioctl(master_fd, TIOCSWINSZ, &size);
}
