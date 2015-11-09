scope HeroAI
//==========================================================================================
//  HeroAI v1.0.0
//      by pred1980
//==========================================================================================
/*
 * This library contains general hero behaviour like
 * - moving around the map
 * - attacking an enemy unit
 * - spending gold on items
 * - running to a "safe point"
 * - use teleporter
 * - register hero for ai
 */
 
	globals
		// The period in which the hero AI will do actions. A very low period can cause strain.
		public constant real DEFAULT_PERIOD = 1.7
		// Determines how the hero looks for items and units.
		public constant real SIGHT_RANGE = 1200.
		// The random amount of distance the hero will move
		public constant real MOVE_DIST = 1000.
		// The range the hero should be within the safe spot. 
		public constant real SAFETY_RANGE = 500.         
		// The state in which the hero is doing nothing in particular
		public constant integer STATE_IDLE = 0 
		// The state in which the hero is fighting an enemy
		public constant integer STATE_ENGAGED = 1 
		// The state in which the hero is running to a shop in order to buy an item
		public constant integer STATE_GO_SHOP = 2 
		// The state in which the hero is trying to run away  
        public constant integer STATE_RUN_AWAY = 3       
    endglobals
	
	struct HeroAI extends array
	
		
	
	endstruct
endscope