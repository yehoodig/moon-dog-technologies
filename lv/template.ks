@lazyglobal off.
//This is a standard Launch Vehicle parameter file.
//This holds the information necessary to customize the flight profile for your lifter.

declare parameter inclination is 0
declare parameter lan is "none".
declare parameter launchToAlt is 80000.

{
   //Load the launch system into memory
   runpath("0:/lib/launch/launch_ctl.ks").

   /////////////////////////// Keplerian Orbital Parameters ////////////////////////
   //The default 0 is equatorial
   launch_param:add("inclination",          inclination).
   
   //If orbital parameters are not specified, the LAN does not need to be passed. 
   if lan="none" {             
      launch_param:add("launchTime",        "now"). 
   } else {
      launch_param:add("launchTime",        "window"). 
      launch_param:add("lan",               lan).
   }

   ////////////////////////// Launch Options /////////////////////////////////////
   //Any inclination can be achieved twice a day.
   // If "north" is specified, rocket will be launched at the Ascending Node.
   // Launch azimuth will be on a northerly heading.
   // If "south" is specified, rocket will be launched at the Descending Node.
   // Launch azimuth will be on a southerly heading.
   // If "all" or "any" is specified, rocket will be launched at the nearest Node.
   // Launch azimuth will be which ever is necessary.
   launch_param:add("azimuthHemisphere",   "all").

   //Fudge factor  
   // Why this is needed: This script is capable of launching into inclined orbits, 
   // however the inclination is not achieved instantly upon launch, which means 
   // the Longitude of the Ascending node will be off slightly (in the direction of rotation).
   // To compensate this factor will activate the launch sequence this number of seconds prior to the 
   // calculated launch time. It is called Time of Flight, because the launch window lead time 
   // should be the same as the amount of time it takes to achieve the proper inclination, which 
   // will also be about the same as the amount of time needed to achieve orbital velocity.  
   // For the record, this will vary with the inclination.
   launch_param:add("timeOfFlight",         180).

   //Gravity turn parameters
   launch_param:add("pOverDeg",             4).  // Pitchover magnitude in degrees
   launch_param:add("pOverV0",              50). // Vertical speed at which to start pitchover                        
   launch_param:add("pOverVf",              150).// Vertical speed at which to handoff steering to prograde follower.

   //Throttle program parameters
   // There are several throttle program types available.
   // This one maintains a set time to Apoapsis.
   //TODO Document available programs.
   // Other "throttleProgramType"s available: "tableMET", "tableAPO", "vOV", and the default ("etaApo")
   
   launch_param:add("throttleProgramType", "etaApo").
   launch_param:add("throttleProfile", list( 
                                            20000, //Apo to Activate function, max prior
                                            launchToAlt, //Apo to Deactivate function 
                                            50)).  //Setpoint

   //Upper stage
   // This tells the system which upper stage is installed.
   // This information is used primarily by the circularization burn.
   launch_param:add("upperstage", "wolfhound").

   //The system will display a countdown of this length before any launch.
   launch_param:add("countDownLength",      20).

   
   //Initialize the launch system.
   // Parameter 1: Activate AG1 at 60km
   // Parameter 2: Activate AG2 at 65km
   launch_ctl["init"](TRUE, TRUE).

   //Add a launch to LKO routine to the MISSIONPLAN
   launch_ctl["addLaunchToMissionPlan"]().
}

