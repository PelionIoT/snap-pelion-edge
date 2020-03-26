#include "mbed-trace/mbed_trace.h"
#include <stdlib.h>
#define TRACE_GROUP "serv"

void pal_plat_osApplicationReboot(void)
{
    tr_warn("Restarting edge..\n");
    exit(-666);
}