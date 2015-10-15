
scope AITower
    globals
        private constant integer TOWER_SYSTEM_AI_TOP_LEFT = 0
        private constant integer TOWER_SYSTEM_AI_TOP_RIGHT = 1
        private constant integer TOWER_SYSTEM_AI_LEFT = 2
        private constant integer TOWER_SYSTEM_AI_RIGHT = 3
        private constant integer TOWER_SYSTEM_AI_BOTTOM_LEFT = 4
        private constant integer TOWER_SYSTEM_AI_BOTTOM_RIGHT = 5
    endglobals

//****************************************************
//*               only needed for test               *
//****************************************************
    struct Builder
        static method onInit takes nothing returns nothing
            local timer tAI = CreateTimer()
            local trigger towerAITrigger = CreateTrigger()
            call TriggerAddAction( towerAITrigger, function thistype.buildTowerAI )

            call TimerStart(tAI, 3.0, false, function thistype.initTowerAI)
            set tAI = null
            set towerAITrigger = null
        endmethod

        public static method initTowerAI takes nothing returns nothing
        	local TowerSystemAI towerBuildAI
        	
            set towerBuildAI = TowerSystemAI.create()
            call towerBuildAI.initTowerBuildAI()
call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_TOP_LEFT).setBuilder(CreateUnit(Player(0), 'u00Q', R2I(GetRectCenterX(gg_rct_TowersTopLeftTop)), R2I(GetRectCenterY(gg_rct_TowersTopLeftTop)), bj_UNIT_FACING))
call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_TOP_RIGHT).setBuilder( CreateUnit(Player(1), 'u00Q', R2I(GetRectCenterX(gg_rct_TowersTopLeftBottom)), R2I(GetRectCenterY(gg_rct_TowersTopLeftTop)), bj_UNIT_FACING))
call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_LEFT).setBuilder(CreateUnit(Player(2), 'u00Q', R2I(GetRectCenterX(gg_rct_TowersTopRightTop)), R2I(GetRectCenterY(gg_rct_TowersTopLeftTop)), bj_UNIT_FACING))

            call towerBuildAI.buildStart()
        endmethod

        public static method buildTowerAI takes nothing returns nothing
        endmethod
    endstruct






	
    /**
     * ----------------------------- STRUCT TowerSystemAI ---------------------------------
     */
    struct TowerSystemAI
		private static integer EVENT_TYPE_UPGRADE = 1
		private static integer EVENT_TYPE_BUILD = 2
        private static TowerAIEventListener towerListener
        
		private static integer MAX_PLAYER = 6
        private static integer eventsCounter = 0
		
		/**
		 * init the tower config for given player
		 */
		private method initTowerConfig takes integer playerId returns nothing
			local TowerBuildConfig buildConfig = TowerBuildConfig.create()
			call buildConfig.addBuilding('u00V')
			call buildConfig.addBuilding('u00S')
			call buildConfig.addBuilding('u00S')
			call buildConfig.addBuilding('u00V')
			call buildConfig.addBuilding('u00S')
			call buildConfig.addBuilding('u00V')
			call buildConfig.addBuilding('u00S')
			call buildConfig.addBuilding('u00V')
			call buildConfig.addBuilding('u00Z')
			call buildConfig.addBuilding('u00S')
			call buildConfig.addBuilding('u00S')
			call buildConfig.addBuilding('u00Z')
			call buildConfig.addBuilding('u00Z')
			call buildConfig.addBuilding('u00S')
			call buildConfig.addBuilding('u00S')
			call buildConfig.addBuilding('u00Z')
			call buildConfig.addBuilding('u00Z')
			call buildConfig.addBuilding('u00S')
			call buildConfig.addBuilding('u00Z')
			call buildConfig.addBuilding('u00Z')
			call TowerAIEventListener.getTowerBuildAI(playerId).setConfig(buildConfig)
		endmethod
		
        /**
         * create all tower-build-AI needed objects
         */
        public method initTowerBuildAI takes nothing returns nothing
            local unit building = CreateUnit( Player(0), 'u00U', 0, 0, bj_UNIT_FACING ) 
	        local real width = GetUnitCollision(building)
	        local real height = width
	        local integer counter = 0
	        local TowerBuildAI towerBuildAI
	        local TowerSystem ts = TowerSystem.create()
	        local TowerHelper towersHelper = TowerHelper.create()
	        call ts.initialize()
	        call RemoveUnit(building)
	        call towersHelper.setTowers(ts.getTowerData())
	        set towersHelper.columnUnitId = 0
	        set towersHelper.columnDamage = 1
	        set towersHelper.columnLevel = 3
	        set towersHelper.columnWoodCost = 4
	        set towersHelper.columnChildTower = 5
	        
	        call TowerAIEventListener.setTowerBuildAI(TOWER_SYSTEM_AI_TOP_LEFT, TowerBuildAI.create())
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_TOP_LEFT).addRectangle(gg_rct_TowersTopLeftTop)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_TOP_LEFT).addRectangle(gg_rct_TowersTopLeftBottom)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_TOP_LEFT).setBuildFromTo(true, false)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_TOP_LEFT).setTowerSize(width, height)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_TOP_LEFT).setTowers(towersHelper)
            call .initTowerConfig(TOWER_SYSTEM_AI_TOP_LEFT)
            
            call TowerAIEventListener.setTowerBuildAI(TOWER_SYSTEM_AI_TOP_RIGHT, TowerBuildAI.create())
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_TOP_RIGHT).addRectangle(gg_rct_TowersTopLeftTop)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_TOP_RIGHT).addRectangle(gg_rct_TowersTopLeftBottom)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_TOP_RIGHT).setBuildFromTo(false, false)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_TOP_RIGHT).setTowerSize(width, height)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_TOP_RIGHT).setTowers(towersHelper)
            call .initTowerConfig(TOWER_SYSTEM_AI_TOP_RIGHT)
            
            call TowerAIEventListener.setTowerBuildAI(TOWER_SYSTEM_AI_LEFT, TowerBuildAI.create())
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_LEFT).addRectangle(gg_rct_TowersLeftTop)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_LEFT).addRectangle(gg_rct_TowersLeftBottom)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_LEFT).setBuildFromTo(true, false)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_LEFT).setTowerSize(width, height)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_LEFT).setTowers(towersHelper)
            call .initTowerConfig(TOWER_SYSTEM_AI_LEFT)
            
            call TowerAIEventListener.setTowerBuildAI(TOWER_SYSTEM_AI_RIGHT, TowerBuildAI.create())
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_RIGHT).addRectangle(gg_rct_TowersRightTop)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_RIGHT).addRectangle(gg_rct_TowersRightBottom)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_RIGHT).setBuildFromTo(false, false)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_RIGHT).setTowerSize(width, height)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_RIGHT).setTowers(towersHelper)
            call .initTowerConfig(TOWER_SYSTEM_AI_RIGHT)
            
            call TowerAIEventListener.setTowerBuildAI(TOWER_SYSTEM_AI_BOTTOM_LEFT, TowerBuildAI.create())
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_BOTTOM_LEFT).addRectangle(gg_rct_TowersBottomLeftLeft)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_BOTTOM_LEFT).addRectangle(gg_rct_TowersBottomLeftTop)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_BOTTOM_LEFT).addRectangle(gg_rct_TowersBottomLeftRight)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_BOTTOM_LEFT).setBuildFromTo(true, false)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_BOTTOM_LEFT).setTowerSize(width, height)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_BOTTOM_LEFT).setTowers(towersHelper)
            call .initTowerConfig(TOWER_SYSTEM_AI_BOTTOM_LEFT)
            
            call TowerAIEventListener.setTowerBuildAI(TOWER_SYSTEM_AI_BOTTOM_RIGHT, TowerBuildAI.create())
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_BOTTOM_RIGHT).addRectangle(gg_rct_TowersBottomRightLeft)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_BOTTOM_RIGHT).addRectangle(gg_rct_TowersBottomRightTop)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_BOTTOM_RIGHT).addRectangle(gg_rct_TowersBottomRightRight)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_BOTTOM_RIGHT).setBuildFromTo(false, false)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_BOTTOM_RIGHT).setTowerSize(width, height)
            call TowerAIEventListener.getTowerBuildAI(TOWER_SYSTEM_AI_BOTTOM_RIGHT).setTowers(towersHelper)
            call .initTowerConfig(TOWER_SYSTEM_AI_BOTTOM_RIGHT)
            
            call .initializeEvents()
	        
        endmethod

        /**
         * initialize the events
         */
        public method initializeEvents takes nothing returns nothing
            local integer i = 0
            local trigger t1 = CreateTrigger()
            local trigger t2 = CreateTrigger()
            local trigger t3 = CreateTrigger()
            local trigger t4 = CreateTrigger()
			local code c1 = function thistype.onConstructFinish
			local code c2 = function thistype.onConstructStart
            
            //Register Tower Events for Player 1-6
            loop
                exitwhen i > 5
                if Game.isPlayerInGame(i) then
					call TriggerRegisterPlayerUnitEvent(t1, Player(i), EVENT_PLAYER_UNIT_UPGRADE_FINISH, null)
                    call TriggerRegisterPlayerUnitEvent(t2, Player(i), EVENT_PLAYER_UNIT_CONSTRUCT_FINISH, null)
                    call TriggerRegisterPlayerUnitEvent(t3, Player(i), EVENT_PLAYER_UNIT_CONSTRUCT_CANCEL, null)
                    call TriggerRegisterPlayerUnitEvent(t4, Player(i), EVENT_PLAYER_UNIT_CONSTRUCT_START, null)
                endif
                set i = i + 1
            endloop
            call TriggerAddCondition(t1, Filter(c1))
            call TriggerAddCondition(t2, Filter(c1))
            call TriggerAddCondition(t3, Filter(c1))
            call TriggerAddCondition(t4, Filter(c2))
            set t1 = null
            set t2 = null
            set t3 = null
            set t4 = null
            set c1 = null
            set c2 = null
        endmethod

        /**
         * tower build or upgrade is finished
         */
        public static method onConstructFinish takes nothing returns nothing
			local unit triggerUnit = GetTriggerUnit() //Tower
            local integer playerId = GetPlayerId(GetOwningPlayer(triggerUnit))
    		call TowerAIEventListener.getTowerBuildAI(playerId).addTower(triggerUnit)
    		if (TowerAIEventListener.getTowerBuildAI(playerId).isEnabled() and TowerAIEventListener.getTowerBuildAI(playerId).countUpgradeQueue() > 0) then
            	call TowerAIEventListener.addUpgradeEvent(triggerUnit)
            endif
            set triggerUnit = null
    	endmethod

        /**
         * tower build is started
         */
        public static method onConstructStart takes nothing returns nothing
			local unit triggerUnit = GetTriggerUnit() //Tower
            local integer playerId = GetPlayerId(GetOwningPlayer(triggerUnit))
            if TowerAIEventListener.getTowerBuildAI(playerId).isEnabled() then
            	call TowerAIEventListener.addBuildEvent(GetTriggerUnit())
            endif
    	endmethod

		/**
		 * build start
		 */
        public static method buildStart takes nothing returns nothing
            local integer playerId = 0
            loop
            	exitwhen playerId >= .MAX_PLAYER
        		set TowerAIEventListener.getTowerBuildAI(playerId).canBuild = true
            	call TowerAIEventListener.getTowerBuildAI(playerId).buildNext()
                set playerId = playerId + 1
            endloop
        endmethod      
    endstruct
//****************************************************
//*               end only needed in test            *
//****************************************************
endscope
