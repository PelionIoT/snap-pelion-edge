#include "pal.h"
#include <stdlib.h>
#include <string.h>
#include "pal_plat_rtos.h"
#include "mbed.h"
#include "entropy_poll.h"

void pal_plat_osApplicationReboot(void)
{
    printf("Restarting edge..\n");
    exit(0);
}