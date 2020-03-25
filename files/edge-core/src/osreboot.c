#include "mbed-trace/mbed_trace.h"
#include <stdlib.h>
#include <unistd.h>

#define TRACE_GROUP "serv"

void pal_plat_osApplicationReboot(void)
{
    tr_warn("Restarting edge..\n");
    
    system("dbus-send --system --print-reply --dest=org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager.Reboot boolean:true");
}
