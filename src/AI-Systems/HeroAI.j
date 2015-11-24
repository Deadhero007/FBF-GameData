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
		
		// Used to pass the shop type id of an item	
		private integer ShopTypeId

		// Used to refer to the AI hero for finding the closest safe unit
		private player TempHeroOwner			
    endglobals
	
	// The function that determines what is a safe unit, like a fountain, for the hero to run to.
	private function IsSafeUnit takes unit u, player heroOwner returns boolean
    	return GetUnitTypeId(u) == 'n006'
    endfunction
	
	private function ShopConditions takes unit u, player heroOwner returns boolean
        return true
    endfunction
	
	private function SafeUnitFilter takes nothing returns boolean
		return IsSafeUnit(GetFilterUnit(), TempHeroOwner)
	endfunction
	
	private function ShopTypeIdCheck takes nothing returns boolean
		return GetUnitTypeId(GetFilterUnit()) == ShopTypeId and ShopConditions(GetFilterUnit(), TempHeroOwner)
	endfunction
	
	//! runtextmacro HeroAILearnset()
	//! runtextmacro HeroAIItem()
	
	module HeroAI
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
		private real runX
        private real runY		
		
		// Used for creating
		private static integer stack = 1
		// Set whenever update is called
		private static thistype tempthis
		// Holds the state of the AI
		private integer state
		
		private integer itemsetIndex
		
		method operator gold takes nothing returns integer
    		return GetPlayerState(.owner, PLAYER_STATE_RESOURCE_GOLD)
    	endmethod
    	
    	method operator gold= takes integer g returns nothing
    		call SetPlayerState(.owner, PLAYER_STATE_RESOURCE_GOLD, g)
    	endmethod
    	
    	method operator lumber takes nothing returns integer
    		return GetPlayerState(.owner, PLAYER_STATE_RESOURCE_LUMBER)
    	endmethod
    	
    	method operator lumber= takes integer l returns nothing
    		call SetPlayerState(.owner, PLAYER_STATE_RESOURCE_LUMBER, l)
    	endmethod
		
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
		
		method operator isChanneling takes nothing returns boolean
            return IsUnitChanneling(.hero)
        endmethod
		
		// Item-related methods
      	method operator curItem takes nothing returns Item
      		return .itemBuild.item(.itemsetIndex)
      	endmethod
		
		private method canBuyItem takes Item it returns boolean
            static if CHECK_REFUND_ITEM_COST then
				local Item check
				if .itemCount == MAX_INVENTORY_SIZE then
					set check = Item[GetItemTypeId(UnitItemInSlot(.hero, ModuloInteger(.itemsetIndex, MAX_INVENTORY_SIZE)))]
					return it.goldCost <= .gold + check.goldCost * SELL_ITEM_REFUND_RATE and it.lumberCost <= .lumber + check.lumberCost * SELL_ITEM_REFUND_RATE
				endif
            endif
			
        	return it.goldCost <= .gold and it.lumberCost <= .lumber
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
			
        	set TempHeroOwner = .owner
        	set u = GetClosestUnit(.hx, .hy, Filter(function SafeUnitFilter))
        	
        	if u == null then
        		debug call BJDebugMsg("[HeroAI] Error: Couldn't find a safe unit for " + GetUnitName(.hero) + ", will run to (0, 0)")
        	endif
        	
        	set .runX = GetUnitX(u)
			set .runY = GetUnitY(u)
			
			set u = null
        endmethod
		
		private method refundItem takes Item it returns nothing
            if it.goldCost > 0 then
                set .gold = R2I(.gold + it.goldCost * SELL_ITEM_REFUND_RATE)
            endif
            
            if it.lumberCost > 0 then
                set .lumber = R2I(.lumber + it.lumberCost * SELL_ITEM_REFUND_RATE)
            endif
        endmethod
        
        private method buyItem takes Item it returns nothing
            local item i
            
            if .itemCount == MAX_INVENTORY_SIZE then
                set i = UnitItemInSlot(.hero, ModuloInteger(.itemsetIndex, MAX_INVENTORY_SIZE) )
                if i != null then
                    call .refundItem(Item[GetItemTypeId(i)])
                    call RemoveItem(i)
                    set i = null
                endif
            endif
            
            set .itemsetIndex = .itemsetIndex + 1
            
            // Set back to state idle now that the hero is done shopping.
            if .state == STATE_GO_SHOP then
                set .state = STATE_IDLE
            endif     
            
        	if it.goldCost > 0 then
				set .gold = .gold - it.goldCost
            endif
            
            if it.lumberCost > 0 then
            	set .lumber = .lumber - it.lumberCost
            endif   
            
            call UnitAddItemById(.hero, it.typeId)        	
        endmethod
		
		// Action methods
		private method move takes nothing returns nothing      
            call IssuePointOrder(.hero, "attack", .hx + GetRandomReal(-MOVE_DIST, MOVE_DIST), .hy + GetRandomReal(-MOVE_DIST, MOVE_DIST))
        endmethod 
        
        private method run takes nothing returns boolean
            return IssuePointOrder(.hero, "move", .runX + GetRandomReal(-SAFETY_RANGE/2, SAFETY_RANGE/2), .runY + GetRandomReal(-SAFETY_RANGE/2, SAFETY_RANGE/2) )
        endmethod
		
		private method getItems takes nothing returns boolean
        	set OnlyPowerUp = .itemCount == MAX_INVENTORY_SIZE
            return IssueTargetOrder(.hero, "smart", GetClosestItemInRange(.hx, .hy, SIGHT_RANGE, Filter(function AIItemFilter)))
        endmethod
		
		private method defaultAssaultEnemy takes nothing returns nothing
			call IssueTargetOrder(.hero, "attack", GroupPickRandomUnit(.enemies))
		endmethod
		
		// This method will be called by update periodically to check if the hero can do any shopping
        private method canShop takes nothing returns nothing
        	local Item it
			
        	loop
				set it = .curItem
				exitwhen not .canBuyItem(it) or .itemsetIndex == .itemBuild.size
				if it.shopTypeId == 0 then
                    call .buyItem(it)	                    
				else
					set ShopTypeId = it.shopTypeId
                    set TempHeroOwner = .owner
					set .shopUnit = GetClosestUnit(.hx, .hy, Filter(function ShopTypeIdCheck))
					debug if .shopUnit == null then
                        debug call BJDebugMsg("[Hero AI] Error: Null shop found for " + GetUnitName(.hero))
                    debug endif
                    if IsUnitInRange(.hero, .shopUnit, SELL_ITEM_RANGE) then
						call .buyItem(it)
					else
						set .state = STATE_GO_SHOP
						exitwhen true
					endif
				endif
			endloop
        endmethod
		
		method defaultLoopActions takes nothing returns nothing
        	if .state == STATE_RUN_AWAY then
        		// Make the hero keep running if it's not within range
				if not IsUnitInRangeXY(.hero, .runX, .runY, SAFETY_RANGE) then
					static if thistype.runActions.exists then
						// Only run if no actions were taken in runActions.
						if not .runActions() then
							call .run()
						endif
					else
						call .run()
						debug call BJDebugMsg("[HeroAI] State: The hero " + GetUnitName(.hero) + " is in STATE_RUN_AWAY.")
					endif
				else
					static if thistype.safeActions.exists then
                    	call .safeActions()
                    else
						// Default looping actions for fighting so that the AI will try to do something at the safe spot.
						if not .isChanneling then
							static if thistype.assistAlly.exists then
								if .allyNum > 0 then
									if .assistAlly() then
										return
									endif
								endif
							endif
							
							if .enemyNum > 0 then
								static if thistype.assaultEnemy.exists then
									call .assaultEnemy()
								else
									call .defaultAssaultEnemy()
								endif
							endif
						endif
					endif
				endif
			else
				if not .isChanneling then
					static if thistype.assistAlly.exists then
						if .allyNum > 0 then
							if .assistAlly() then
								return // Assisting an ally has precedence over anything else
							endif
						endif
					endif
					// Fight enemies if the hero is engaged
					if .state == STATE_ENGAGED then
						static if thistype.assaultEnemy.exists then
							call .assaultEnemy()
						else
							call .defaultAssaultEnemy()
							debug call BJDebugMsg("[HeroAI] State: The hero " + GetUnitName(.hero) + " is in STATE_ENGAGED.")
						endif
					else               
						// Makes the hero try to get any nearby item before attempting to shop
						if not .getItems() then
							if .state == STATE_GO_SHOP then
								// If the hero isn't in range of the shop, make it move there.
								if not IsUnitInRange(.hero, .shopUnit, SELL_ITEM_RANGE) then
									call IssuePointOrder(.hero, "move", GetUnitX(.shopUnit) + GetRandomReal(-SELL_ITEM_RANGE/2, SELL_ITEM_RANGE/2), GetUnitY(.shopUnit) + GetRandomReal(-SELL_ITEM_RANGE/2, SELL_ITEM_RANGE/2))
								else
									// Buys the item only if it was able to.
                                    if .canBuyItem(.curItem) then
                                        call .buyItem(.curItem)
                                    else
                                        set .state = STATE_IDLE
                                    endif
								endif
							else
								// STATE_IDLE, make the hero move around randomly
								call .move()
								debug call BJDebugMsg("[HeroAI] State: The hero " + GetUnitName(.hero) + " is in STATE_IDLE.")
							endif
						endif
					endif
				endif                      
			endif
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
				//debug call BJDebugMsg("[HeroAI] State: The current state of the hero " + GetUnitName(.hero) + " is STATE_IDLE.")
			endif
			
			// state: STATE_RUN_AWAY
			if (.badCondition) then
				set .state = STATE_RUN_AWAY
				//debug call BJDebugMsg("[HeroAI] State: The current state of the hero " + GetUnitName(.hero) + " is STATE_RUN_AWAY.")
				call .setRunSpot()
			endif
			
			// state: STATE_ENGAGED
			// NOTE: STATE_ENGAGED will only take precedence over STATE_GO_SHOP if the hero is not within 
			// 		 IGNORE_ENEMY_SHOP_RANGE of the shop
			if 	((.enemyNum > 0 and .state == STATE_IDLE) or /*
			*/	(.state == STATE_GO_SHOP and not IsUnitInRange(.hero, .shopUnit, IGNORE_ENEMY_SHOP_RANGE))) then
				set .state = STATE_ENGAGED
				//debug call BJDebugMsg("[HeroAI] State: The current state of the hero " + GetUnitName(.hero) + " is STATE_ENGAGED.")
			endif
			
			// Only check to do shopping if in the AI hasn't completed its itemset and it's in STATE_IDLE
            if (.itemsetIndex < .itemBuild.size and .state == STATE_IDLE) then
				call .canShop()
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