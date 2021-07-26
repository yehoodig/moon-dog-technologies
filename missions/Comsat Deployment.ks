@lazyglobal off.
//A mission template
//Objectives and routines will be run in the order they are added here.
//When writing your own, avoid loops and wait statements.
//If a routine in the MISSION_PLAN list returns OP_CONTINUE, it will be run again,
// if it returns OP_FINISHED, the system will advance to the next routine in the MISSION_PLAN.

//Load up pluggable objectives.
runpath("0:/programs/std/change-ap.ks").
available_programs["change-ap"]("terrier", 774400).
MISSION_PLAN:add({
   local procs is list().
   list processors in procs.
   if procs:length = 1{
      return OP_FINISHED.
   } else {
      stage.
      wait ship:orbit:period.
      return OP_CONTINUE.
   }
}).
