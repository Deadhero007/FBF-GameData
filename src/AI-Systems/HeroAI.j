library HeroAI requires Table, TimerUtils, RegisterPlayerUnitEvent, GroupUtils, SpellHelper, /*
					*/	optional IsUnitChanneling
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
		private constant player NEUTRAL_PLAYER = Player(15)    

		// The state in which the hero is doing nothing in particular
		public constant integer STATE_IDLE = 0 
		// The state in which the hero is fighting an enemy
		public constant integer STATE_ENGAGED = 1 
		// The state in which the hero is running to a shop in order to buy an item
		public constant integer STATE_GO_SHOP = 2 
		// The state in which the hero is trying to run away  
        public constant integer STATE_RUN_AWAY = 3       
        		
		// Tracks custom AI structs defined for specific unit-type ids 
		private Table customAI
		// Tracks the AI struct a hero has		
        private Table heroesAI
		// For registering an AI for a unit
		public unit RegisterUnit
		// Used to refer to the AI hero for finding the closest safe unit
		private player TempHeroOwner	 		

		private trigger fireTrigger
		
		
	endglobals

	private keyword INITS
	
	//! runtextmacro HeroAIItem()
	
	// The function that determines what is a safe unit, like a fountain, for the hero to run to.
    // Typically, you should check if the unit, u, matches the safe unit-type id in your map.
    // The test-map makes a simple unit-type check since it assumes fountain units cannot be killed and will heal any hero
    private function IsSafeUnit takes unit u, player heroOwner returns boolean
    	return GetUnitTypeId(u) == 'n006'
    endfunction
	
	// The condition in which the hero will try to run away to a safe spot. Optionally complemented by the threat library
	//! textmacro HeroAI_Default_badCondition
		return .percentLife <= .35 or (.percentLife <= .55 and .mana / GetUnitState(.hero, UNIT_STATE_MAX_MANA) <= .3) or (.maxLife < 700 and .life <= 250.)
	//! endtextmacro
	
	// The condition in which the hero will return to its normal activities
	//! textmacro HeroAI_Default_goodCondition
		return .percentLife >= .85 and .mana / GetUnitState(.hero, UNIT_STATE_MAX_MANA) >= .65
	//! endtextmacro
	
	// Disregard this completely if you include IsUnitChanneling in your map
		//! textmacro HeroAI_isChanneling 
			return o == 852652 or /* Cluster Rockets
                */ o == 852488 or /* Flamestrike
                */ o == 852089 or /* Blizzard
                */ o == 852238 or /* Rain of Fire
                */ o == 852664 or /* Healing spray
			 	*/ o == 852183 or /* Starfall
			 	*/ o == 852593    // Stampeded
		//! endtextmacro
	
	private function SafeUnitFilter takes nothing returns boolean
		return IsSafeUnit(GetFilterUnit(), TempHeroOwner)
	endfunction
	
	private function getState takes integer state returns string
		if (state == 0) then
			return "STATE_IDLE"
		elseif (state == 1) then
			return "STATE_ENGAGED"
		elseif (state == 2) then
			return "STATE_GO_SHOP"
		else
			return "STATE_RUN_AWAY"
		endif
	endfunction
	
	module HeroAI
		private static integer index = 1
		unit hero
		player owner
		integer hid
		group units
        group allies        
        group enemies
		integer itemCount             
        real life
        real maxLife
        real mana           
        real hx            
        real hy
		integer allyNum  
        integer enemyNum
		private timer tim
		// Set whenever update is called
		static thistype temp 
		// Holds the state of the AI
		private integer st 
		private real runX
        private real runY
		// Shop unit used internally
		private unit shUnit					
		
		method operator percentLife takes nothing returns real
            return .life / .maxLife
        endmethod

		method operator badCondition takes nothing returns boolean
            //! runtextmacro HeroAI_Default_badCondition()
        endmethod
        
        method operator goodCondition takes nothing returns boolean
        	//! runtextmacro HeroAI_Default_goodCondition()            
        endmethod
		
		method operator isChanneling takes nothing returns boolean
            static if LIBRARY_IsUnitChanneling then
                return IsUnitChanneling(.hero)
            else
				local integer o = GetUnitCurrentOrder(.hero)
				//! runtextmacro HeroAI_isChanneling()
            endif
        endmethod
		
		//Actions
		method move takes nothing returns nothing
			call BJDebugMsg("Move around")
            call IssuePointOrder(.hero, "attack", .hx + GetRandomReal(-MOVE_DIST, MOVE_DIST), .hy + GetRandomReal(-MOVE_DIST, MOVE_DIST))
        endmethod
		
		method run takes nothing returns boolean
            return IssuePointOrder(.hero, "move", .runX + GetRandomReal(-SAFETY_RANGE/2, SAFETY_RANGE/2), .runY + GetRandomReal(-SAFETY_RANGE/2, SAFETY_RANGE/2) )
        endmethod
		
		private static method filtUnits takes nothing returns boolean
			local unit u = GetFilterUnit()
			
            // Filter out dead units, the hero itself, and neutral units
            if not SpellHelper.isUnitDead(u) and u != temp.hero and GetOwningPlayer(u) != NEUTRAL_PLAYER then
                // Filter unit is an ally
                if IsUnitAlly(u, temp.owner) then
                    call GroupAddUnit(temp.allies, u)
                    set temp.allyNum = temp.allyNum + 1
                // Filter unit is an enemy, only enum it if it's visible
                elseif IsUnitVisible(u, temp.owner) then
                    call GroupAddUnit(temp.enemies, u)
					set temp.enemyNum = temp.enemyNum + 1
                endif
                set u = null
                return true
            endif
			
            set u = null
			
            return false
		endmethod
		
		// This method will be called by update periodically to check if the hero can do any shopping
        method canShop takes nothing returns nothing
        	/*local Item it
        	loop
				set it = .curItem
				exitwhen not .canBuyItem(it) or .itemsetIndex == .itemBuild.size
				if it.shopTypeId == 0 then
                    call .buyItem(it)	                    
				else
					set ShopTypeId = it.shopTypeId
                    set TempHeroOwner = .owner
					set .shUnit = GetClosestUnit(.hx, .hy, Filter(function ShopTypeIdCheck))
					debug if .shUnit == null then
                        debug call BJDebugMsg("[Hero AI] Error: Null shop found for " + GetUnitName(.hero))
                    debug endif
                    if IsUnitInRange(.hero, .shUnit, SELL_ITEM_RANGE) then
						call .buyItem(it)
					else
						set .st = STATE_GO_SHOP
						exitwhen true
					endif
				endif
			endloop*/
        endmethod   
		
		private method setRunSpot takes nothing returns nothing
        	local unit u = GetClosestUnit(.hx, .hy, Filter(function SafeUnitFilter))  	
        	set TempHeroOwner = .owner
        	
			if u == null then
        		call BJDebugMsg("[HeroAI] Error: Couldn't find a safe unit for " + GetUnitName(.hero) + ", will run to (0, 0)")
        	endif

        	set .runX = GetUnitX(u)
			set .runY = GetUnitY(u)
			set u = null
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
			
			// Group enumeration
			set temp = this
			call GroupRefresh(.enemies)
			call GroupRefresh(.allies)
			set .enemyNum = 0
			set .allyNum = 0
			call GroupEnumUnitsInArea(.units, .hx, .hy, SIGHT_RANGE, Filter(function thistype.filtUnits))
			
			// Good Condition?
			if (.st == STATE_RUN_AWAY and .goodCondition) then
				set .st = STATE_IDLE
			endif
			
			//Bad Condition?
			if (.st != STATE_RUN_AWAY and .badCondition) then
				set .st = STATE_RUN_AWAY
				call .setRunSpot()
			endif
			
			//Any Enemies around?
			//Check first if the hero is not running away
			if (.st != STATE_RUN_AWAY) then
				if (.enemyNum > 0 and .st == STATE_IDLE) then
					set .st = STATE_ENGAGED
				endif
				
				if (.enemyNum == 0) then
					set .st = STATE_IDLE
				endif
			endif
			
			// Only check to do shopping if in the AI hasn't completed its itemset and it's in STATE_IDLE
			/*if (.itemsetIndex < .itemBuild.size and .st == STATE_IDLE) then
				call .canShop()
			endif*/
		endmethod
		
		method defaultAssaultEnemy takes nothing returns nothing
            static if thistype.setPriorityEnemy.exists then
                call .setPriorityEnemy(.enemies)
                call IssueTargetOrder(.hero, "attack", .priorityEnemy)
            else
                static if LIBRARY_FitnessFunc then                
                	static if LIBRARY_GroupUtils then
                		call GroupClear(ENUM_GROUP)
						call GroupAddGroup(.enemies, ENUM_GROUP)
						call PruneGroup(ENUM_GROUP, FitnessFunc_LowLife, 1, NO_FITNESS_LIMIT)
						call IssueTargetOrder(.hero, "attack", FirstOfGroup(ENUM_GROUP))  
                    else
						call GroupClear(bj_lastCreatedGroup)
						call GroupAddGroup(.enemies, bj_lastCreatedGroup)
						call PruneGroup(bj_lastCreatedGroup, FitnessFunc_LowLife, 1, NO_FITNESS_LIMIT)
						call IssueTargetOrder(.hero, "attack", FirstOfGroup(bj_lastCreatedGroup))  
                    endif
                 else // A lazy way to make the hero attack a random unit if none of the special targetting libraries are there
                    call IssueTargetOrder(.hero, "attack", GroupPickRandomUnit(.enemies)) 
                endif
            endif
        endmethod
		
		method defaultLoopActions takes nothing returns nothing
			call BJDebugMsg("State: " + getState(.st))
		
			if (.st == STATE_RUN_AWAY) then
				// Make the hero keep running if it's not within range of the safeUnit
				if not IsUnitInRangeXY(.hero, .runX, .runY, SAFETY_RANGE) then
					static if thistype.runActions.exists then
						// Only run if no actions were taken in runActions.
						if not .runActions() then
							call .run()
						endif
					else
						call .run()
					endif
				else
					static if thistype.safeActions.exists then
						call .safeActions()
                    endif
				endif
			endif
			
			// Fight enemies if the hero is engaged
			if (.st == STATE_ENGAGED) then
				static if thistype.assaultEnemy.exists then
					call .assaultEnemy()
				else
					call .defaultAssaultEnemy()
				endif
			endif
			
			// STATE_IDLE, make the hero move around randomly
			if (.st == STATE_IDLE) then
				call .move()
			endif
			
			if (.st == STATE_GO_SHOP) then
				
			endif
		endmethod
		
		private static method defaultLoop takes nothing returns nothing
        	local thistype this = GetTimerData(GetExpiredTimer())
        	if not(SpellHelper.isUnitDead(.hero)) then
				call .update()
				static if thistype.loopActions.exists then
					call .loopActions()
				else
					call .defaultLoopActions()
				endif
			endif
        endmethod
	
		static method create takes unit h returns thistype
			local thistype this = index
			local integer typeId = GetUnitTypeId(h)
			
			set .hero = h
            set .owner = GetOwningPlayer(.hero)
            set .hid = GetHandleId(h)
            
            set .units = NewGroup()
            set .enemies = NewGroup()
            set .allies = NewGroup()
			
			set .tim = NewTimerEx(this)
            call TimerStart(.tim, DEFAULT_PERIOD, true, function thistype.defaultLoop)
			
			set index = index + 1
			set heroesAI[.hid] = this
			
			return this
		endmethod
		
	endmodule
	
	private struct DefaultHeroAI extends array
    	implement HeroAI
    endstruct
	
	private function FireCondition takes boolexpr b returns nothing
        call TriggerClearConditions(fireTrigger)
        call TriggerAddCondition(fireTrigger, b)
        call TriggerEvaluate(fireTrigger)
    endfunction
	
	function RunHeroAI takes unit hero returns nothing
        if heroesAI.has(GetHandleId(hero)) then
            call BJDebugMsg("[Hero AI] Error: Attempt to run an AI for a unit that already has one, aborted.")
            return
        endif
        
        if customAI.boolexpr[GetUnitTypeId(hero)] != null then
        	set RegisterUnit = hero
            call FireCondition(customAI.boolexpr[GetUnitTypeId(hero)])
        else
            call DefaultHeroAI.create(hero)        
        endif
    endfunction
	
	function RegisterHeroAI takes integer unitTypeId, code register returns nothing
        if customAI.boolexpr[unitTypeId] != null then
            call BJDebugMsg("[Hero AI] Error: Attempt to register an AI struct for a unit-type id again, aborted")
            return
        endif
        set customAI.boolexpr[unitTypeId] = Filter(register)
    endfunction
	
	//! textmacro HeroAI_Register takes HERO_UNIT_TYPEID
    private function RegisterAI takes nothing returns nothing          
        call AI.create(HeroAI_RegisterUnit)
    endfunction
    
    private module ModuleHack
     	static method onInit takes nothing returns nothing
     		call RegisterHeroAI($HERO_UNIT_TYPEID$, function RegisterAI)
     	endmethod
    endmodule    
    
    private struct StructHack extends array
    	implement ModuleHack
    endstruct
    //! endtextmacro
	
	//INITIALIZATION
	private struct I extends array
		implement INITS
	endstruct
	
	private module INITS
		private static method onInit takes nothing returns nothing
			set customAI = Table.create()
            set heroesAI = Table.create()
			set fireTrigger = CreateTrigger()
		endmethod
	endmodule
endlibrary