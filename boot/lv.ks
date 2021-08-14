@lazyglobal off.

//If this ship is on the launch pad... 
if ship:status = "PRELAUNCH" {
   if scriptpath():split(".")[1] = ".ksm" { 
      
   } 
   runpath(usingVol+":/lib/launch/boot_common"+usingExt).
   kernel_ctl["start"]().
   //Wait until program is finished, and then wait 5 seconds.
   //The following attempts to pass off control of the craft, from the KOS Processor on the Booster, 
   //to the KOS Processor on the payload.
   //For more info, see payload_boot.ks
   wait 5.
   for payloadCore in processors {
      if payloadCore:bootfilename = "payload.ks" {
         print "Handing off...".
         payloadCore:connection:sendmessage("handoff").
      }
      shutdown.
   }
}
