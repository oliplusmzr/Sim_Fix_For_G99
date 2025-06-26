ui_print "
╔═══╗────╔═══╦══╦═╗╔═╗─╔═╗─────╔═══╦═══╦═══╗
║╔═╗║────║╔══╩╣╠╩╗╚╝╔╝─║╔╝─────║╔═╗║╔═╗║╔═╗║
║╚══╦╦╗╔╗║╚══╗║║─╚╗╔╝─╔╝╚╦══╦═╗║║─╚╣╚═╝║╚═╝║
╚══╗╠╣╚╝║║╔══╝║║─╔╝╚╗─╚╗╔╣╔╗║╔╝║║╔═╬══╗╠══╗║
║╚═╝║║║║║║║──╔╣╠╦╝╔╗╚╗─║║║╚╝║║─║╚╩═╠══╝╠══╝║
╚═══╩╩╩╩╝╚╝──╚══╩═╝╚═╝─╚╝╚══╩╝─╚═══╩═══╩═══╝"
MODDIR=${0%/*}
rm -f /sdcard/simfix_log.txt
rm -f /sdcard/simfix_log_date.txt
rm -f /sdcard/simfix.log
rm -f /sdcard/Download/simfix_log.txt
rm -f /data/local/tmp/simfix
rm -f /data/local/tmp/simfix.log
rm -f /data/local/tmp/simfix_log.txt
rm -f /data/local/tmp/simfix_log_date.txt
rm -f /data/local/tmp/debug_service.log
ui_print " Version Blue"
ui_print "   Installing for $ARCH SDK $API device..."
ui_print "          ### Device Info ###"
ui_print "   Model: $(getprop ro.product.vendor.model)"
ui_print "   Brand: $(getprop ro.product.vendor.manufacturer)"
ui_print "   Android Version: $(getprop ro.build.version.release)"
ui_print "   API Level: $API"
ui_print "   Arch: $ARCH"
ui_print "   Platform: $MAGISK $KSU"
ui_print "   Platform Version: $MAGISK_VER $KSU_VER"
ui_print "   KernelSU Version: $MAGISK_VER_CODE $KSU_VER_CODE"
ui_print "   Boot Mode: $BOOTMODE"
ui_print "   Processor: $(uname -m)"
ui_print "   Hardware: $(getprop ro.hardware)"
ui_print "   Verified Boot: $(getprop ro.boot.verifiedbootstate)"
ui_print "   Bionic CPU: $(getprop ro.bionic.cpu_variant)"
ui_print "   Vendor API: $(getprop ro.product.vndk.version) & $(getprop ro.vendor.build.version.sdk)"
ui_print "   Vendor Android Version: $(getprop ro.vendor.build.version.release_or_codename)"
ui_print "   DSU SUPPORT: $(getprop ro.boot.dynamic_partitions)"
ui_print "   GSI Support: $(getprop ro.treble.enabled)"
ui_print "   EGL: $(getprop ro.hardware.egl)"
ui_print "   Zygote: $(getprop ro.zygote)"