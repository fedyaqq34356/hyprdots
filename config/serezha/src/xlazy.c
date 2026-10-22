#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <unistd.h>

static int die(const char *what)
{
    fprintf(stderr, "serezha-xlazy: %s: %s\n", what, strerror(errno));
    return 1;
}

static int listen_on(const char *path, int abstract)
{
    struct sockaddr_un a = { .sun_family = AF_UNIX };
    socklen_t len;
    int fd = socket(AF_UNIX, SOCK_STREAM, 0);

    if (fd < 0)
        return -1;

    if (abstract) {
        a.sun_path[0] = '\0';
        strncpy(a.sun_path + 1, path, sizeof a.sun_path - 2);
        len = offsetof(struct sockaddr_un, sun_path) + 1 + strlen(path);
    } else {
        unlink(path);
        strncpy(a.sun_path, path, sizeof a.sun_path - 1);
        len = sizeof a;
    }

    if (bind(fd, (struct sockaddr *)&a, len) < 0 || listen(fd, 16) < 0) {
        close(fd);
        return -1;
    }
    return fd;
}

int main(int argc, char **argv)
{
    char lock[64], path[64], fd0[16], fd1[16];
    int n, lfd, s0, s1;

    if (argc != 2 || argv[1][0] != ':' || (n = atoi(argv[1] + 1)) <= 0) {
        fprintf(stderr, "usage: serezha-xlazy :N\n");
        return 2;
    }

    snprintf(lock, sizeof lock, "/tmp/.X%d-lock", n);
    snprintf(path, sizeof path, "/tmp/.X11-unix/X%d", n);

    lfd = open(lock, O_WRONLY | O_CREAT | O_EXCL, 0444);
    if (lfd < 0)
        return die(lock);
    dprintf(lfd, "%10d\n", getpid());
    close(lfd);

    mkdir("/tmp/.X11-unix", 01777);
    s0 = listen_on(path, 0);
    s1 = listen_on(path, 1);
    if (s0 < 0 || s1 < 0) {
        unlink(lock);
        return die(path);
    }

    struct pollfd p[2] = { { s0, POLLIN, 0 }, { s1, POLLIN, 0 } };
    while (poll(p, 2, -1) < 0)
        if (errno != EINTR) {
            unlink(lock);
            unlink(path);
            return die("poll");
        }

    snprintf(fd0, sizeof fd0, "%d", s0);
    snprintf(fd1, sizeof fd1, "%d", s1);
    execlp("xwayland-satellite", "xwayland-satellite", argv[1],
           "-listenfd", fd0, "-listenfd", fd1, (char *)NULL);

    unlink(lock);
    unlink(path);
    return die("xwayland-satellite");
}
