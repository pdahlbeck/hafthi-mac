#ifndef HAFTHI_PTY_SUPPORT_H
#define HAFTHI_PTY_SUPPORT_H

#include <stdint.h>
#include <sys/types.h>

// Returns the shell's PID, or -1 with errno set. The caller owns master_fd.
pid_t hafthi_spawn_shell(const char *shell, const char *home,
                         int *master_fd, uint16_t columns, uint16_t rows);
int hafthi_resize_pty(int master_fd, uint16_t columns, uint16_t rows);

#endif
