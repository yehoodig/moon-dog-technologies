@lazyglobal off.
// Program Template

local programName is "approach". //<------- put the name of the script here

// Header allowing for standalone operation.
//   If this program is to be used as part of a complete mission, run this script without parameters, and
//   then call the functions in the available_programs lexicon in the correct order of events for the mission
//   to build the MISSION_PLAN.
    // If you modify the number of parameters, be sure to fix the function call at the bottom of this file.

if not (defined kernel_ctl) runpath("0:/lib/core/kernel.ks"). 

//Add initialzer for this program sequence to the lexicon of available programs
// Could be written as available_programs:add...but that occasionally produces an error when run as a standalone script.
kernel_ctl["availablePrograms"]:add(programName, {
   //One time initialization code.
   //   Question: Why not simply have a script file with the contents of the initializer delegate?  Why the extra layers?
   //   Answer: It seems that the memory area for parameters passed to scripts is always the same.  So, when 
   //           a script defines a function to be called later, any additional script called with parameters will
   //           clobber the parameter intended for the first one.  The parameter below will be preserved and its value
   //           will remain available to the program, as long as the program is written within this scope, 
  
//======== Imports needed by the program =====
   if not (defined transfer_ctl) runpath("0:/lib/transfer_ctl.ks").
   if not (defined maneuver_ctl) runpath("0:/lib/maneuver_ctl.ks").
   
//======== Parameters used by the program ====
   // Don't forget to update the standalone system, above, if you change the number of parameters here.
   declare parameter argv.
   local engineName is "".
   local targetObject is "".
   if argv:split(" "):length > 1 {
      set engineName to argv:split(" ")[0].
      if not (maneuver_ctl["engineDef"](engineName)) return OP_FAIL.
      if argv:split(char(34)):length > 1 set targetObject to argv:split(char(34))[1]. // Quoted second parameter
      else set targetObject to argv:split(" ")[1].
      set kernel_ctl["output"] to "target: "+ targetObject.
   } else {
      set kernel_ctl["output"] to
         "Matches velocity with target vessel at closest approach."
         +char(10)+"Usage: add-program "+programName+" [ENGINE-NAME] [TARGET]".
      return.
   }

//======== Local Variables =====
   local dist is ship:position.
   local relVelocity is ship:velocity:orbit.
   local velToward is 0.  //speed toward target
   local timeOfClosest is time:seconds.

   declare function steeringVector {
      return -1*relVelocity.
   }


//=============== Begin program sequence Definition ===============================
   // The actual instructions implementing the program are in delegates, Which the initializer adds to the MISSION_PLAN.
   // In this case, the first part of the program sequence
   // is given as an anonymous function, and the second part is a function implemented in the maneuver_ctl library. 
   // If you do not like anonymous functions, you could implement a named function elsewhere and add a reference
   // to it to the MISSION_PLAN instead, like so: kernel_ctl["MissionPlanAdd"](named_function@).

   
      kernel_ctl["MissionPLanAdd"](programName, {
         if not(hastarget) {
            set target to targetObject.
         }
         // Find approximate closest approach.
         local distanceAtTime is (ship:position - target:position):mag.
         local lastDistance is distanceAtTime.
         local t is time:seconds.
         local s is distanceAtTime/100.
         
         until lastDistance < distanceAtTime {
            set lastDistance to distanceAtTime.
            set s to distanceAtTime/1000.
            set t to t + s.
            set distanceAtTime to (positionat(ship, t)-positionat(target, t)):mag.
         }
         set timeOfClosest to t.

         lock steering to steeringVector.
         return OP_FINISHED.
      }).
      kernel_ctl["MissionPLanAdd"](programName, {
         set dist        to (target:position-ship:position).
         set relVelocity to (ship:velocity:orbit - target:velocity:orbit).
         set velToward   to relVelocity:mag*cos(vang(relVelocity, dist)).  //speed toward target
         //local dist is (positionat(target, time:seconds)-positionat(ship, time:seconds)).
         print "toward: "+velToward at(0, 5).
         print "RelVelocity: "+relVelocity:mag at(0, 6).
         print "time to target: "+(timeOfClosest - time:seconds) at(0,7).

         if time:seconds < timeOfClosest - 10 {
            lock throttle to 0.
            return OP_CONTINUE.
         } else if relVelocity:mag > 5 {
            lock throttle to 1.
            return OP_CONTINUE.
         }
         lock throttle to 0.
         return OP_FINISHED.
      }).
      kernel_ctl["MissionPlanAdd"](programName, {
         set dist        to (target:position-ship:position).
         set relVelocity to (ship:velocity:orbit - target:velocity:orbit).
         set velToward   to relVelocity:mag*cos(vang(relVelocity, dist)).  //speed toward target
         
         if dist:mag < 150 { // Within relativistic frame
            if relVelocity:mag < 1 {
               lock throttle to 0.
               lock steeering to ship:prograde.
               return OP_FINISHED.
            } else if relVelocity:mag > 1 {
               lock steering to -1*relVelocity.
               // Below: Wait until ship is pointed at retrograde in reference to target.
               if vang(-1*(ship:velocity:orbit - target:velocity:orbit), ship:facing:forevector) > 1 {return OP_CONTINUE.}
               lock throttle to abs(relVelocity:mag)/100.
            }
         } else { // Not close enough
            if velToward < relVelocity:mag/2 { // drifting away
               local victor is -vxcl(target:position, relVelocity)+target:position:normalized*relVelocity:mag.
               lock steering to victor.
               if vang(victor, ship:facing:forevector) > 2.5 {
               //if vang(-1*relVelocity(), ship:facing:forevector) > 1 { // Zero out velocity by turning to target retrograde.
                  lock throttle to 0.
                  return OP_CONTINUE.
               } else {
                  local error is abs(relVelocity:mag).
                  local sigmoid is error/sqrt(1+error^2). 
                  lock throttle to sigmoid.
                  //lock throttle to max(0.01, abs(relVelocity:mag)/ship:availablethrust).
               }
               //if abs(relVelocity():mag) > 1 {return OP_CONTINUE.}
               //lock throttle to 0.
            } else lock throttle to 0.
            
            //} else if abs(velToward()) < 5 and relVelocity():mag < 6 { // Need to move a little faster
               //if vang(relVelocity(), ship:facing:forevector) > 1 {
                  //lock steering to dist().  // Point at target
                  //lock throttle to 0.
                  //return OP_CONTINUE.
               //}
               //lock throttle to 0.1.
               //if abs((ship:velocity:orbit - target:velocity:orbit):mag) < dist():mag/180 {return OP_CONTINUE.}
               //lock throttle to 0.
            //}
         }
         return OP_CONTINUE.
      }).
         
         
         
//========== End program sequence ===============================
   
}). //End of initializer delegate