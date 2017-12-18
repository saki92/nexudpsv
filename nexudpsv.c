#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <stdbool.h>
#include <sys/ioctl.h>

struct nexio {
	int type;
	struct ifreq *ifr;
	int sock_rx_ioctl;
	int sock_rx_frame;
	int sock_tx;
	unsigned int securitycookie;
};

extern struct nexio *nex_init_ioctl(const char *ifname);
extern int nex_ioctl(struct nexio *nexio, int cmd, void *buf, int len, bool set);

char            *ifname = "suthu";
unsigned int    custom_cmd = 0;
signed char     custom_cmd_set = 1;
unsigned int    custom_cmd_buf_len;
void            *custom_cmd_buf;

struct nexio *nexio;

unsigned int ioctl_pass(unsigned short *custom_cmd_buf, int custom_cmd_buf_len) {
    unsigned int custom_cmd = *custom_cmd_buf;
    //unsigned int high_cmd =*(custom_cmd_buf+2);
    //unsigned int whole_cmd = (low_cmd ^ (high_cmd << 8));
    nexio = nex_init_ioctl(ifname);
    int ret = nex_ioctl(nexio, custom_cmd, custom_cmd_buf, custom_cmd_buf_len, custom_cmd_set);
    return ret;
}

//nexio = nex_init_ioctl(ifname);
//ret = nex_ioctl(nexio, custom_cmd, custom_cmd_buf, custom_cmd_buf_len, custom_cmd_set);