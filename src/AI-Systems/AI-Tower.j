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

            call TimerStart(tAI, 3.0, false, function thistype.initTowerAI)
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
            call towerBuildAI.buildNext()
        endmethod

        public static method buildTowerAI takes nothing returns nothing
        endmethod
    endstruct






    /**
     * the tower positions
     */
    struct TowerPosition
        private real array posX[20]
        private real array posY[20]
        private unit array tower[20]
        private integer maxPos = 0
        
        /**
         * sets an new tower
         * @param integer position
		 * @param real positionY
 		 * @param real positionX
 		 * @param unit towerBuilding
         */
        public method setTower takes integer position, real positionY, real positionX, unit towerBuilding returns nothing
        	set .posY[position] = positionY
        	set .posX[position] = positionX
        	set .tower[position] = towerBuilding
        	if position >= .maxPos then
                set .maxPos = position
            endif
        endmethod

		/**
		 * get the max position
		 */
        public method getMaxPos takes nothing returns integer
            return .maxPos
        endmethod

		/**
		 * gets the x-coord by position
		 * @param integer position
		 * @return real
		 */
        public method getPosXByPosition takes integer position returns real
            return .posX[position]
        endmethod

		/**
		 * gets the y-coord by position
		 * @param integer position
		 * @return real
		 */
        public method getPosYByPosition takes integer position returns real
            return .posY[position]
        endmethod

		/**
		 * sets that an position was builded
		 * @param integer position
		 * @param unit building
		 */
        public method setBuilded takes integer position, unit building returns nothing
           set .tower[position] = building
        endmethod
    endstruct

	/**
	 * the config for the tower build
	 */
	struct TowerBuildConfig
		/**
		 * the buildings that can build by cpu. more unique tower is the chance higher that build at next
		 * @var integer
		 */
		private integer array buildings[60]
		private integer buildingPosition
		
		/**
		 * add an building to the "can build"
		 * @param integer building
		 */
		public method addBuilding takes integer building returns nothing
			if .buildingPosition < 60 then
			    set .buildings[.buildingPosition] = building
			    set .buildingPosition = .buildingPosition + 1
		    endif
		endmethod
		
		/**
		 * gets an building from the config
		 * @return integer
		 */
		public method getRandomBuilding takes nothing returns integer
		    local integer random = 0
		    set random = GetRandomInt(0, 60)
		    return .buildings[random]
		endmethod
		
		/**
		 * resets the buildings that can build by config
		 */
		public method resetBuildings takes nothing returns nothing
			local integer building
			loop
			    exitwhen building == 60
			    set .buildings[building] = 0
				set building = building + 1
			endloop
			set .buildingPosition = 0
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
        
        private boolean leftToRight = false
        private boolean topToBottom = false

        private real array towerSize[2]
        private unit builder
        
        private integer currentRegion = 0
        private boolean enabled = false
        public integer lumber = 0
        public boolean builded = false
        public boolean canBuild = false

		/**
		 * sets the builder
		 * @param unit Builder
		 */
        public method setBuilder takes unit builder returns nothing
            set .builder = builder
            set .enabled = true
        endmethod
        
        /**
         * @param real height
         * @param real width
         */
        public method setTowerSize takes real height, real width returns nothing
        	set .towerSize[.TOWER_WIDTH] = width / 3
        	set .towerSize[.TOWER_HEIGHT] = height / 3
        endmethod
        
        /**
         * is the builder enabled as cpu
         */
        public method isEnabled takes nothing returns boolean
        	return .enabled
        endmethod
        
        /**
         * add rectangle to build tower
         * @param rect rectangle
         */
        public method addRectangle takes rect rectangle returns nothing
			if (.MAX_REGIONS > .currentRegion) then
            	set .rectangles[.currentRegion] = rectangle
            	set .currentRegion = .currentRegion + 1
        	endif
        endmethod
        
        /**
         * sets that the builder builds from left to right and top to bottom or other
         * @param boolean leftToRight
         * @param boolean topToBottom
         */
        public method setBuildFromTo takes boolean leftToRight, boolean topToBottom returns nothing
        	set .leftToRight = leftToRight
        	set .topToBottom = topToBottom
        endmethod
        
        /**
         * initialize the positions by settet regions
         */
        public method initPositions takes nothing returns nothing
/*
			local real maxSizeX = GetRectMaxX(Rectangle) //right
			local real maxSizeY = GetRectMaxY(Rectangle) //top
			local real minSizeX = GetRectMinX(Rectangle) //left
			local real minSizeY = GetRectMinY(Rectangle) //bottom
*/
			local integer currentRegion = 0
			loop
				exitwhen currentRegion >= .currentRegion
				
	        	set .positionLeft[currentRegion] = GetRectMinX(.rectangles[currentRegion])
	        	set .positionRight[currentRegion] = GetRectMaxX(.rectangles[currentRegion])
	        	
	        	set .positionTop[currentRegion] = GetRectMaxY(.rectangles[currentRegion])
	        	set .positionBottom[currentRegion] = GetRectMinY(.rectangles[currentRegion])
	        	
	        	set currentRegion = currentRegion + 1
        	endloop
        endmethod

		/**
		 * sets the config
		 * @param TowerBuildConfig towerConfig
		 */
		public method setConfig takes TowerBuildConfig towerConfig returns nothing
			set .config = towerConfig
		endmethod
		
		/**
		 * build next unit
		 * @param integer unitId
		 */
        public method build takes integer unitId returns nothing
 			local real positionY = 0
 			local real positionX = 0
 			local integer currentRegion = 0
 			local integer checkPosition = 0
 			local real width = .towerSize[.TOWER_WIDTH]
			local real height = .towerSize[.TOWER_HEIGHT]
			local boolean builded = false
			local boolean buildX = false
			
 			if .topToBottom == false then
                set height = height * -1
            endif
 			if .leftToRight == false then
                set width = width * -1
            endif

 			loop 
				exitwhen currentRegion >= .currentRegion
	 			if .topToBottom then
	                set positionY = .positionTop[currentRegion] + (height / 2)
                else
	                set positionY = .positionBottom[currentRegion] - (height / 2)
	            endif
	 			if .leftToRight then
	                set positionX = .positionLeft[currentRegion] + (width / 2)
				else
	                set positionX = .positionRight[currentRegion] - (width / 2)
	            endif
 				set checkPosition = 0
 				set buildX = .positionTop[currentRegion] - .positionBottom[currentRegion] > .positionLeft[currentRegion] - .positionRight[currentRegion]
 				
 				loop 
 					exitwhen checkPosition >= 3
					if buildX then
						set positionX = positionX + width
					else
						set positionY = positionY + height
					endif
					set builded = IssueBuildOrderById(.builder, unitId, positionX, positionY)
					
/*
call BJDebugMsg(R2S(positionX))
call BJDebugMsg(R2S(positionY))
					
call BJDebugMsg(I2S(count))
*/
					exitwhen builded
/*
call BJDebugMsg("y")
call BJDebugMsg(R2S( .positionLeft[currentRegion]))
call BJDebugMsg(R2S(positionX))
call BJDebugMsg(R2S(.positionRight[currentRegion]))
*/
					exitwhen positionX < .positionLeft[currentRegion]
					exitwhen positionX > .positionRight[currentRegion]
/*
call BJDebugMsg("x")
call BJDebugMsg(R2S( .positionTop[currentRegion]))
call BJDebugMsg(R2S(positionY))
call BJDebugMsg(R2S(.positionBottom[currentRegion]))
call BJDebugMsg(I2S(count))
*/
					exitwhen positionY > .positionTop[currentRegion]
//call BJDebugMsg("end2")
					exitwhen positionY < .positionBottom[currentRegion]
//call BJDebugMsg("end")
 				endloop
 				exitwhen builded
 				set currentRegion = currentRegion + 1
 			endloop
 			set .builded = builded
 			if builded then
                call BJDebugMsg("Has Builded")
            endif
        endmethod
    endstruct

    /**
     * ----------------------------- STRUCT TowerSystemAI ---------------------------------
     */
    struct TowerSystemAI
		private static integer MAX_PLAYER = 6
		private static TowerBuildAI array towerBuilder[6]

		/**
		 * gets the builder-ai by position
		 * @param integer position
		 * @return ToweBuildAI
		 */
		public method getBuildAIByPosition takes integer position returns TowerBuildAI
			return .towerBuilder[position]
		endmethod
		
        /**
         * create all tower-build-AI needed objects
         */
        public method initTowerBuildAI takes nothing returns nothing
            local unit building = CreateUnit( Player(0), 'u00U', 0, 0, bj_UNIT_FACING ) 
	        local real width = GetUnitCollision(building)
	        local real height = width
	        call RemoveUnit(building)
	        
            set .towerBuilder[TOWER_SYSTEM_AI_TOP_LEFT] = TowerBuildAI.create()
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_LEFT].addRectangle(gg_rct_TowersTopLeftTop)
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_LEFT].addRectangle(gg_rct_TowersTopLeftBottom)
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_LEFT].initPositions()
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_LEFT].setBuildFromTo(true, false)
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_LEFT].setTowerSize(width, height)
            
            set .towerBuilder[TOWER_SYSTEM_AI_TOP_RIGHT] = TowerBuildAI.create()
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_RIGHT].addRectangle(gg_rct_TowersTopRightTop)
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_RIGHT].addRectangle(gg_rct_TowersTopRightBottom)
			call .towerBuilder[TOWER_SYSTEM_AI_TOP_RIGHT].initPositions()
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_RIGHT].setBuildFromTo(false, false)
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_RIGHT].setTowerSize(width, height)
            
            set .towerBuilder[TOWER_SYSTEM_AI_LEFT] = TowerBuildAI.create()
            call .towerBuilder[TOWER_SYSTEM_AI_LEFT].addRectangle(gg_rct_TowersLeftTop)
            call .towerBuilder[TOWER_SYSTEM_AI_LEFT].addRectangle(gg_rct_TowersLeftBottom)
            call .towerBuilder[TOWER_SYSTEM_AI_LEFT].initPositions()
            call .towerBuilder[TOWER_SYSTEM_AI_LEFT].setBuildFromTo(true, false)
            call .towerBuilder[TOWER_SYSTEM_AI_LEFT].setTowerSize(width, height)
            
            set .towerBuilder[TOWER_SYSTEM_AI_RIGHT] = TowerBuildAI.create()
            call .towerBuilder[TOWER_SYSTEM_AI_RIGHT].addRectangle(gg_rct_TowersRightTop)
            call .towerBuilder[TOWER_SYSTEM_AI_RIGHT].addRectangle(gg_rct_TowersRightBottom)
            call .towerBuilder[TOWER_SYSTEM_AI_RIGHT].initPositions()
            call .towerBuilder[TOWER_SYSTEM_AI_RIGHT].setBuildFromTo(false, false)
            call .towerBuilder[TOWER_SYSTEM_AI_RIGHT].setTowerSize(width, height)
            
            set .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_LEFT] = TowerBuildAI.create()
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_LEFT].addRectangle(gg_rct_TowersBottomLeftLeft)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_LEFT].addRectangle(gg_rct_TowersBottomLeftTop)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_LEFT].addRectangle(gg_rct_TowersBottomLeftRight)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_LEFT].initPositions()
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_LEFT].setBuildFromTo(true, false)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_LEFT].setTowerSize(width, height)
            
            set .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_RIGHT] = TowerBuildAI.create()
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_RIGHT].addRectangle(gg_rct_TowersBottomRightLeft)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_RIGHT].addRectangle(gg_rct_TowersBottomRightTop)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_RIGHT].addRectangle(gg_rct_TowersBottomRightRight)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_RIGHT].initPositions()
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_RIGHT].setBuildFromTo(false, false)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_RIGHT].setTowerSize(width, height)
        endmethod

		/**
		 * begin the build loop
		 */
        public static method buildNext takes nothing returns nothing
            local integer playerId = 0
            loop
            	exitwhen playerId >= .MAX_PLAYER
        		set .towerBuilder[playerId].canBuild = true
                set playerId = playerId + 1
            endloop
            call .buildLoop()
        endmethod
        
		/**
		 * build the next tower
		 * @param integer towerAIPosition
		 * @param integer lumber
		 */
        private static method buildLoop takes nothing returns nothing
            local timer tAI = CreateTimer()
            local integer playerId = 0
            local boolean builded = false
            local integer lumber = 0
            loop
            	exitwhen playerId >= .MAX_PLAYER
                set lumber = Game.getPlayerLumber(playerId)
                if .towerBuilder[playerId].isEnabled() then
                    if .towerBuilder[playerId].canBuild then
                    	if .towerBuilder[playerId].lumber <= lumber then
                            //configuration search
                            
                            if lumber >= 100 then //if user has enough lumber to build
								call .towerBuilder[playerId].build('u00U')
					        	set .towerBuilder[playerId].lumber = Game.getPlayerLumber(playerId)
                            else
                                set .towerBuilder[playerId].builded = false
                            endif
						endif
					endif
                    if .towerBuilder[playerId].builded then
                        set builded = true
                        call BJDebugMsg("builded")
                    else
                        set .towerBuilder[playerId].canBuild = false
                    endif
				endif
                set playerId = playerId + 1
            endloop
            set playerId = 0
            if builded then
	            call TimerStart(tAI, 1.0, false, function thistype.buildLoop)
	            call BJDebugMsg("STartTimer")
            endif
            set tAI = null
        endmethod

    endstruct
endscope
