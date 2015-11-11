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
		public constant real DEFAULT_PERIOD = 2.0
		// Determines how the hero looks for items and units.
		public constant real SIGHT_RANGE = 1500.
		// The random amount of distance the hero will move
		public constant real MOVE_DIST = 1500.
		// The range the hero should be within the safe spot. 
		public constant real SAFETY_RANGE = 500.         
		
		/*
		 * HERO STATES
		 */
		// The state in which the hero is doing nothing in particular
		public constant integer STATE_IDLE = 0 
		// The state in which the hero is fighting an enemy
		public constant integer STATE_ENGAGED = 1 
		// The state in which the hero is running to a shop in order to buy an item
		public constant integer STATE_GO_SHOP = 2 
		// The state in which the hero is trying to run away  
        public constant integer STATE_RUN_AWAY = 3

		// Tracks the AI struct a hero has
		private Table heroesAI  				
    endglobals
	
	//! runtextmacro HeroAILearnset()
	//! runtextmacro HeroAIItem()
	
	private module HeroAI
		private unit hero
    	private player owner
        private integer hId
		private real life
        private real maxLife
        private real mana           
        private real hx            
        private real hy
		private timer t
		private Itemset itemBuild        
        private integer itemCount
		private group units
		private group allies        
        private group enemies       
        private integer allyNum   
        private integer enemyNum
		// Shop unit used internally
		private unit shopUnit					
		
		// Used for creating
		private static integer stack = 1
		// Set whenever update is called
		private static thistype tempthis
		// Holds the state of the AI
		private integer state
		
		method operator percentLife takes nothing returns real
            return .life / .maxLife
        endmethod
		
		// The condition in which the hero will return to its normal activities
		method operator goodCondition takes nothing returns boolean
        	return 	.percentLife >= .85 and /*
			*/		.mana / GetUnitState(.hero, UNIT_STATE_MAX_MANA) >= .65      
        endmethod
		
		// The condition in which the hero will try to run away to a safe spot. 
		// Optionally complemented by the threat library
		method operator badCondition takes nothing returns boolean
        	return 	.percentLife <= .35 or /*
			*/	   	(.percentLife <= .55 and .mana / GetUnitState(.hero, UNIT_STATE_MAX_MANA) <= .3) or /*
			*/		(.maxLife < 700 and .life <= 250.)      
        endmethod
		
		private static method filtUnits takes nothing returns boolean
            local unit u = GetFilterUnit()
			
            // Filter out dead units, the hero itself, and neutral units
            if not SpellHelper.isUnitDead(u) and u != tempthis.hero then
                // Filter unit is an ally
                if SpellHelper.isValidEnemy(u, tempthis.hero) then
                    call GroupAddUnit(tempthis.allies, u)
                    set tempthis.allyNum = tempthis.allyNum + 1
                // Filter unit is an enemy, only enum it if it's visible
                elseif IsUnitVisible(u, tempthis.owner) then
                    call GroupAddUnit(tempthis.enemies, u)
                    set tempthis.enemyNum = tempthis.enemyNum + 1
                endif
				
                set u = null
                return true
            endif
            set u = null
            return false
        endmethod
		
		private method setRunSpot takes nothing returns nothing
        	local unit u 
			
        	/*set TempHeroOwner = .owner
        	set u = GetClosestUnit(.hx, .hy, Filter(function SafeUnitFilter))
        	
        	if u == null then
        		debug call BJDebugMsg("[HeroAI] Error: Couldn't find a safe unit for " + GetUnitName(.hero) + ", will run to (0, 0)")
        	endif
        	
        	set .runX = GetUnitX(u)
			set .runY = GetUnitY(u)
			*/
			set u = null
        endmethod
		
		method defaultLoopActions takes nothing returns nothing
			
		endmethod
		
		// Updates information about the hero and its surroundings
        method update takes nothing returns nothing
			// Information about self
			set .hx = GetUnitX(.hero)
			set .hy = GetUnitY(.hero)
			set .life = GetWidgetLife(.hero)
			set .mana = GetUnitState(.hero, UNIT_STATE_MANA)
			set .maxLife = GetUnitState(.hero, UNIT_STATE_MAX_LIFE)
			set .itemCount = UnitInventoryCount(.hero)
			set tempthis = this
			
			// Group enumeration					
			call GroupClear(.enemies)
			call GroupClear(.allies)
			set .enemyNum = 0
			set .allyNum = 0			
			call GroupEnumUnitsInRange(.units, .hx, .hy, SIGHT_RANGE, Filter(function thistype.filtUnits))
			
			//Set the state of the hero
			// state: IDLE
			if (.goodCondition) then
				set .state = STATE_IDLE
				debug call BJDebugMsg("[HeroAI] State: The current state of the hero " + GetUnitName(.hero) + " is STATE_IDLE.")
			endif
			
			// state: STATE_RUN_AWAY
			if (.badCondition) then
				set .state = STATE_RUN_AWAY
				debug call BJDebugMsg("[HeroAI] State: The current state of the hero " + GetUnitName(.hero) + " is STATE_RUN_AWAY.")
				//call .setRunSpot()
			endif
			
			// state: STATE_ENGAGED
			// NOTE: STATE_ENGAGED will only take precedence over STATE_GO_SHOP if the hero is not within 
			// 		 IGNORE_ENEMY_SHOP_RANGE of the shop
			if 	((.enemyNum > 0 and .state == STATE_IDLE) or /*
			*/	(.state == STATE_GO_SHOP and not IsUnitInRange(.hero, .shopUnit, IGNORE_ENEMY_SHOP_RANGE))) then
				set .state = STATE_ENGAGED
				debug call BJDebugMsg("[HeroAI] State: The current state of the hero " + GetUnitName(.hero) + " is STATE_ENGAGED.")
			endif
		endmethod

		private static method defaultLoop takes nothing returns nothing
        	local thistype this = GetTimerData(GetExpiredTimer())
        	
			if not (SpellHelper.isUnitDead(.hero)) then
				call .update()
				static if thistype.loopActions.exists then
					call .loopActions()
				else
					call .defaultLoopActions()
				endif
			endif
        endmethod
		
		static method create takes unit hero returns thistype
    		local thistype this = stack
    		local integer lvl = 1	
            local integer typeId = GetUnitTypeId(hero)
			
			set .hero = hero
            set .owner = GetOwningPlayer(.hero)
            set .hId = GetHandleId(.hero)
			
			set .units = CreateGroup()
			set .enemies = CreateGroup()
            set .allies = CreateGroup()
			
			set .t = NewTimerEx(this)
            call TimerStart(.t, DEFAULT_PERIOD, true, function thistype.defaultLoop)
			
			if (GetHeroSkillPoints(.hero) > 0) then
				loop
					exitwhen lvl > GetUnitLevel(.hero)
					call SelectHeroSkill(.hero, learnsetInfo[lvl][typeId])
					set lvl = lvl + 1
				endloop
			endif

			static if thistype.onCreate.exists then
				call .onCreate()
			endif

			set stack = stack + 1
			set heroesAI[.hId] = this
			
			debug call BJDebugMsg("[HeroAI] Info: The hero " + GetUnitName(.hero) + " is registered to the Hero AI System.")
    		return this
		endmethod
	endmodule
	
	private struct DefaultHeroAI extends array
    	implement HeroAI
    endstruct
	
	function RunHeroAI takes unit hero returns nothing
		if heroesAI.has(GetHandleId(hero)) then
            debug call BJDebugMsg("[Hero AI] Error: Attempt to run an AI for a unit that already has one, aborted.")
            return
        endif
	
		call DefaultHeroAI.create(hero)
	endfunction
	
	private module I 
        static method onInit takes nothing returns nothing
            set heroesAI = Table.create()            
        endmethod
    endmodule
    
    private struct A extends array
        implement I
    endstruct
endscope