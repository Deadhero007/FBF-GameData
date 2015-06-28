scope AITower
    globals
        private constant integer ACOLYTE_I_ID = 'u00Q'
        private constant integer ACOLYTE_II_ID = 'u008'
        private constant integer ACOLYTE_III_ID = 'u006'
        private constant integer SELL = 'n005'
        private constant integer MAX_TOWERS = 33

        private hashtable TOWER_DATA = InitHashtable()
        private unit array ACOLYTS
        private real array START_POS_X
        private real array START_POS_Y
        
        // It is the periodic time (seconds) which the group will be refreshed (ghost units are removed)
        private constant real TIME_OUT = 30.0
        private group BEING_BUILT_UNITS
        private group BEING_UPGRADE_UNITS

        private constant integer MAX_NON_TOWER_AREAS = 10 //Anzahl der Gebiete wo keine T?rme gebaut werden d?rfen
        private rect array NON_TOWER_RECTS
        private TowerSystemAI towerBuildAI

        private constant integer TOWER_SYSTEM_AI_TOP_LEFT = 0
        private constant integer TOWER_SYSTEM_AI_TOP_RIGHT = 1
        private constant integer TOWER_SYSTEM_AI_LEFT = 2
        private constant integer TOWER_SYSTEM_AI_RIGHT = 3
        private constant integer TOWER_SYSTEM_AI_BOTTOM_LEFT = 4
        private constant integer TOWER_SYSTEM_AI_BOTTOM_RIGHT = 5
    endglobals

    struct Builder
        static method onInit takes nothing returns nothing
            local integer i = 0
            local timer t = CreateTimer()
            local timer tAI = CreateTimer()
            local trigger t1 = CreateTrigger()
            local trigger t2 = CreateTrigger()
            local trigger t3 = CreateTrigger()
            local trigger t4 = CreateTrigger()
            local trigger t5 = CreateTrigger()
            local trigger t6 = CreateTrigger()

            local trigger towerAITrigger = CreateTrigger()
            
            
            call TriggerRegisterPlayerChatEvent( towerAITrigger, Player(0), "stop", true )
            call TriggerAddAction( towerAITrigger, function thistype.buildTowerAI )

            call TimerStart(tAI, 10.0, false, function thistype.initTowerAI)
            //Register Tower Events for Player 1-6
            loop
                exitwhen i > 5
                
                call TriggerRegisterPlayerUnitEvent(t1, Player(i), EVENT_PLAYER_UNIT_CONSTRUCT_START, null)
                call TriggerRegisterPlayerUnitEvent(t2, Player(i), EVENT_PLAYER_UNIT_CONSTRUCT_FINISH, null)
                call TriggerRegisterPlayerUnitEvent(t3, Player(i), EVENT_PLAYER_UNIT_UPGRADE_START, null)
                call TriggerRegisterPlayerUnitEvent(t4, Player(i), EVENT_PLAYER_UNIT_UPGRADE_FINISH, null)
                call TriggerRegisterPlayerUnitEvent(t5, Player(i), EVENT_PLAYER_UNIT_UPGRADE_CANCEL, null)
                call TriggerRegisterPlayerUnitEvent(t6, Player(i), EVENT_PLAYER_UNIT_TRAIN_FINISH, null)
                call Game.setPlayerLumber(i, 500)
                call Game.getPlayerLumber(i)
                set i = i + 1
            endloop
            /*
            call TriggerAddCondition(t1, Filter(c1))
            call TriggerAddCondition(t2, Filter(c2))
            call TriggerAddCondition(t3, Filter(c3))
            call TriggerAddCondition(t4, Filter(c4))
            call TriggerAddCondition(t5, Filter(c5))
            call TriggerAddCondition(t6, Filter(c6))
            */
            set t1 = null
            set t2 = null
            set t3 = null
            set t4 = null
            set t5 = null
            set t6 = null
            /*
            set c1 = null
            set c2 = null
            set c3 = null
            set c4 = null
            set c5 = null
            set c6 = null
            */
            set t = null
            set tAI = null
            set towerAITrigger = null
        endmethod

        public static method initTowerAI takes nothing returns nothing
        	local TowerBuildAI towerBuild
//        	local integer position = 0
//        	local rect array rectangle
        	
            set towerBuildAI = TowerSystemAI.create()
            call towerBuildAI.initTowerBuildAI()
/*            loop
            	exitwhen position == 6
            	set position = position + 1
            endloop
            
            	set position = 0
            loop
            
                exitwhen position == 11
                    call Game.setPlayerLumber(position, 500)
                call BJDebugMsg(I2S(Game.getPlayerLumber(position)))
                	set position = position + 1
            
            endloop
*/          
            set ACOLYTS[0] = CreateUnit(Player(0), ACOLYTE_I_ID, R2I(GetRectCenterX(gg_rct_TowersTopLeftTop)), R2I(GetRectCenterY(gg_rct_TowersTopLeftTop)), bj_UNIT_FACING)
            call towerBuildAI.getBuildAIByPosition(TOWER_SYSTEM_AI_TOP_LEFT).setBuilder(ACOLYTS[0])

            //@TODO: Currently only to test must change!
//            call towerBuildAI.generateBuildPositions(gg_rct_TowersTopLeftTop, 3, 0, ACOLYTS[0])
            call towerBuildAI.buildNext(TOWER_SYSTEM_AI_TOP_LEFT, Game.getPlayerLumber(0))
        endmethod

        public static method buildTowerAI takes nothing returns nothing
        endmethod
    endstruct
    
    struct TowerPosition
        private real array posX[20]
        private real array posY[20]
        private unit array tower[20]
        private integer maxPos = 0
        
        public method setTower takes integer position, real positionY, real positionX, unit towerBuilding returns nothing
        	set .posY[position] = positionY
        	set .posX[position] = positionX
        	set .tower[position] = towerBuilding
        	if position >= .maxPos then
                set .maxPos = position
            endif
        endmethod

        public method getMaxPos takes nothing returns integer
            return .maxPos
        endmethod

        public method getPosXByPosition takes integer position returns real
            return .posX[position]
        endmethod

        public method getNextFreePosition takes nothing returns integer
           local integer currentPosition = 0
           loop
               exitwhen .maxPos <= currentPosition
               exitwhen .tower[currentPosition] == null
               set currentPosition = currentPosition + 1
               
           endloop
           return currentPosition
        endmethod

        public method isFreePosition takes integer position returns unit
           return .tower[position]
        endmethod

        public method setBuilded takes integer position, unit building returns nothing
           set .tower[position] = building
        endmethod
    endstruct

	/**
	 * the config for the tower build
	 */
	struct TowerBuildConfig
		private integer array buildings[60]
		public method addBuilding takes integer building returns nothing
		    
		endmethod
		
		public method getRandomBuilding takes nothing returns integer
		    local integer random = 0
		    set random = GetRandomInt(0, 60)
		    return .buildings[random]
		endmethod
		
		public method resetBuildings takes nothing returns nothing
			local integer building
			loop
			    exitwhen building == 60
			    set .buildings[building] = 0
				set building = building + 1
			endloop
		endmethod
	endstruct

    /**
     * the AI for the tower build
     */
    struct TowerBuildAI
        private static integer MAX_REGIONS = 3
        private static integer TOWER_WIDTH = 0
        private static integer TOWER_HEIGHT = 1
        
		private rect array rectangles[3]        
        private real array positionLeft[3]
        private real array positionRight[3]
        private real array positionTop[3]
        private real array positionBottom[3]
        private TowerPosition array towerPositions[3]
        private unit array tower[60]
        private TowerBuildConfig config

        private real array towerSize[2]
        private unit builder
        
        private integer currentRegion = 0
        private boolean enabled = false

        public method setBuilder takes unit builder returns nothing
            set .builder = builder
            set .enabled = true
        endmethod
        
        /**
         * @param real height
         * @param real width
         */
        public method setTowerSize takes real height, real width returns nothing
        	set .towerSize[.TOWER_WIDTH] = width
        	set .towerSize[.TOWER_HEIGHT] = height
        endmethod
        
        public method isEnabled takes nothing returns boolean
        	return .enabled
        endmethod
        
        public method addRectangle takes rect rectangle returns nothing
			if (.MAX_REGIONS > .currentRegion) then
            	set .rectangles[.currentRegion] = rectangle
            	set .currentRegion = .currentRegion + 1
        	endif
        endmethod
        
        public method initPositions takes nothing returns nothing
/*
			local real maxSizeX = GetRectMaxX(Rectangle) //right
			local real maxSizeY = GetRectMaxY(Rectangle) //top
			local real minSizeX = GetRectMinX(Rectangle) //left
			local real minSizeY = GetRectMinY(Rectangle) //bottom
*/
			local integer currentRegion = 0
			loop
				exitwhen currentRegion <= .currentRegion
				
	        	set .positionLeft[currentRegion] = GetRectMinX(.rectangles[currentRegion])
	        	set .positionRight[currentRegion] = GetRectMaxX(.rectangles[currentRegion])
	        	
	        	set .positionTop[currentRegion] = GetRectMaxY(.rectangles[currentRegion])
	        	set .positionTop[currentRegion] = GetRectMinY(.rectangles[currentRegion])
	        	
	        	set currentRegion = currentRegion + 1
        	endloop
        endmethod

		public method setConfig takes TowerBuildConfig towerConfig returns nothing
			set .config = towerConfig
		endmethod
		        
        public method build takes integer lumber returns nothing
        	
                    call Game.setPlayerLumber(0, 500)
                    call Game.getPlayerLumber(0)
                    call Game.setPlayerLumber(1, 500)
                    call Game.getPlayerLumber(1)
        endmethod
    endstruct

    /**
     * ----------------------------- STRUCT TowerSystemAI ---------------------------------
     */
    struct TowerSystemAI

		private TowerBuildAI array towerBuilder[6]

		public method getBuildAIByPosition takes integer position returns TowerBuildAI
			return .towerBuilder[position]
		endmethod
		
        /**
         * create all tower-build-AI needed objects
         */
        public method initTowerBuildAI takes nothing returns nothing
            set .towerBuilder[TOWER_SYSTEM_AI_TOP_LEFT] = TowerBuildAI.create()
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_LEFT].addRectangle(gg_rct_TowersTopLeftTop)
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_LEFT].addRectangle(gg_rct_TowersTopLeftBottom)
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_LEFT].initPositions()
            
            set .towerBuilder[TOWER_SYSTEM_AI_TOP_RIGHT] = TowerBuildAI.create()
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_RIGHT].addRectangle(gg_rct_TowersTopRightTop)
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_RIGHT].addRectangle(gg_rct_TowersTopRightBottom)
			call .towerBuilder[TOWER_SYSTEM_AI_TOP_RIGHT].initPositions()
            
            set .towerBuilder[TOWER_SYSTEM_AI_LEFT] = TowerBuildAI.create()
            call .towerBuilder[TOWER_SYSTEM_AI_LEFT].addRectangle(gg_rct_TowersLeftTop)
            call .towerBuilder[TOWER_SYSTEM_AI_LEFT].addRectangle(gg_rct_TowersLeftBottom)
            call .towerBuilder[TOWER_SYSTEM_AI_LEFT].initPositions()
            
            set .towerBuilder[TOWER_SYSTEM_AI_RIGHT] = TowerBuildAI.create()
            call .towerBuilder[TOWER_SYSTEM_AI_RIGHT].addRectangle(gg_rct_TowersRightTop)
            call .towerBuilder[TOWER_SYSTEM_AI_RIGHT].addRectangle(gg_rct_TowersRightBottom)
            call .towerBuilder[TOWER_SYSTEM_AI_RIGHT].initPositions()
            
            set .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_LEFT] = TowerBuildAI.create()
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_LEFT].addRectangle(gg_rct_TowersBottomLeftLeft)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_LEFT].addRectangle(gg_rct_TowersBottomLeftTop)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_LEFT].addRectangle(gg_rct_TowersBottomLeftRight)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_LEFT].initPositions()
            
            set .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_RIGHT] = TowerBuildAI.create()
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_RIGHT].addRectangle(gg_rct_TowersBottomRightLeft)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_RIGHT].addRectangle(gg_rct_TowersBottomRightTop)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_RIGHT].addRectangle(gg_rct_TowersBottomRightRight)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_RIGHT].initPositions()
        endmethod

        public method buildNext takes integer towerAIPosition, integer lumber returns nothing
			call .towerBuilder[towerAIPosition].build(lumber)
                    
/*
            call BJDebugMsg(R2S(startX))
            call BJDebugMsg(R2S(startY))

            call BJDebugMsg(R2S(.TOWER_POSITIONS[0].getXPosByPosition(0)))
            call BJDebugMsg(R2S(.TOWER_POSITIONS[0].getYPos()))

                     call IssueBuildOrderById(acolyt, 'u00X', startX, startY)
                     call CreateUnit(Player(1), 'u00Q', startX, startY, bj_UNIT_FACING)
                    call PingMinimap(startX, startY, 100)
            if ( .checkPosition(buildPosition) ) then
                 set position = .TOWER_POSITIONS[buildPosition].getNextFreePosition()
                 if ( .TOWER_POSITIONS[buildPosition].getMaxPos() > position ) then
                     set positionY = .TOWER_POSITIONS[buildPosition].getYPos()
                     set positionX = .TOWER_POSITIONS[buildPosition].getXPosByPosition(position)
                     if (IssueBuildOrderById(acolyt, 'u00U', positionX, positionY)) then
                         call .TOWER_POSITIONS[buildPosition].setBuilded(position, true)
                     endif
                 endif
            endif
*/
        endmethod
    endstruct
endscope
