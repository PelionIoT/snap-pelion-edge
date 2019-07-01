= Pelion Edge =

== edge-core ==

* start
    sudo snap start pelion-edge

* stop
    sudo snap stop pelion-edge

* view logs
    sudo snap logs pelion-edge

* reset storage
    Add "--reset-storage" to ${SNAP_DATA}/edge-core.conf

* startup parameters
    Modify startup parameters by editing the file ${SNAP_DATA}/edge-core.conf, which is typically /var/snap/pelion-edge/current/edge-core.conf.
