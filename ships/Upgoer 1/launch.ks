@lazyglobal off.
//Libraries that do not need to be copied to the ship
runpath("0:/lib/rangeControl.ks").

//Libraries that DO need to be copied to the ship
copypath("0:/lib/core/kernel.ks", "").
runpath("kernel.ks").

copypath("0:/lib/ascent/stagingControl.ks", "").
runpath("stagingControl.ks").

copypath("0:/lib/ascent/steeringControl.ks", "").
runpath("steeringControl.ks").

copypath("0:/lib/general.ks", "").
runpath("general.ks").

copypath("0:/lib/ascent/throttleControl.ks", "").
runpath("throttleControl.ks").

copypath("0:/lib/guidanceControl.ks", "").
runpath("guidanceControl.ks").

{
   range_ctl["init"](10).
   ascent_ctl["init_steering"](
      lexicon( //Orbit parameters
         "altitude", 80000, 
         "inclination", 0 
      ), 
      lexicon( //Ascent Parameters
         "hemisphere", "north",
         "pOverDeg", 4.25, 
         "pOverV0", 40, 
         "pOverVf", 130
      )).
  ascent_ctl["init_throttle"]( "tableAPO", list(
     40000, 1,
     60000, 0.5,
     70000, 0.25,
     80000, 0.1

// ascent_ctl["init_throttle"]( "tableMET", list(
//     60, 1,
//     120, 0.5,
//     240, 0.25,
//     320, 0.1
     
  //ascent_ctl["init_throttle"]( "etaApo", list(
     //20000, 80000, 45

   )).
   set ship:control:pilotmainthrottle to 0.

   lock throttle to ascent_ctl["throttleProgram"]().
   lock steering to ascent_ctl["steeringProgram"]().

   local MISSION_PLAN is list().
   MISSION_PLAN:add(range_ctl["countdown"]).
   MISSION_PLAN:add(ascent_ctl["launch"]).
   MISSION_PLAN:add({
     ascent_ctl["staging"]().
     return ascent_ctl["throttle_monitor"]().
   }).
   MISSION_PLAN:add({
      if ship:altitude > 70000 {
         guidance_ctl["add_burn"]("ap", "circularize", 345, 17.73419501).
         return OP_FINISHED.
      } else return OP_CONTINUE.
   }).
   MISSION_PLAN:add(guidance_ctl["burn_monitor"]).
   kernel_ctl["start"](MISSION_PLAN).
}

