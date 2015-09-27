
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
            local timer tAI = CreateTimer()
            local trigger towerAITrigger = CreateTrigger()
            call TriggerAddAction( towerAITrigger, function thistype.buildTowerAI )

            call TimerStart(tAI, 3.0, false, function thistype.initTowerAI)
            set tAI = null
            set towerAITrigger = null
        endmethod

        public static method initTowerAI takes nothing returns nothing
        	local TowerBuildAI towerBuild
        	
            set towerBuildAI = TowerSystemAI.create()
            call towerBuildAI.initTowerBuildAI()
            set ACOLYTS[0] = CreateUnit(Player(0), ACOLYTE_I_ID, R2I(GetRectCenterX(gg_rct_TowersTopLeftTop)), R2I(GetRectCenterY(gg_rct_TowersTopLeftTop)), bj_UNIT_FACING)
            set ACOLYTS[1] = CreateUnit(Player(1), ACOLYTE_I_ID, R2I(GetRectCenterX(gg_rct_TowersTopLeftTop)), R2I(GetRectCenterY(gg_rct_TowersTopLeftTop)), bj_UNIT_FACING)
            set ACOLYTS[2] = CreateUnit(Player(2), ACOLYTE_I_ID, R2I(GetRectCenterX(gg_rct_TowersTopLeftTop)), R2I(GetRectCenterY(gg_rct_TowersTopLeftTop)), bj_UNIT_FACING)
            call towerBuildAI.getBuildAIByPosition(TOWER_SYSTEM_AI_TOP_LEFT).setBuilder(ACOLYTS[0])
//                        call towerBuildAI.getBuildAIByPosition(TOWER_SYSTEM_AI_TOP_RIGHT).setBuilder(ACOLYTS[1])
//                                    call towerBuildAI.getBuildAIByPosition(TOWER_SYSTEM_AI_LEFT).setBuilder(ACOLYTS[2])

            //@TODO: Currently only to test must change!
//            call towerBuildAI.generateBuildPositions(gg_rct_TowersTopLeftTop, 3, 0, ACOLYTS[0])
            call towerBuildAI.buildStart()
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
		private integer array buildings[20]
		private integer buildingPosition = 0
		
		/**
		 * add an building to the "can build"
		 * @param integer building
		 */
		public method addBuilding takes integer building returns nothing
			if .buildingPosition < 20 then
			    set .buildings[.buildingPosition] = building
			    set .buildingPosition = .buildingPosition + 1
		    endif
		endmethod
		
		/**
		 * gets an building from the config
		 * @return integer
		 */
		public method getRandomBuilding takes nothing returns integer
		    return .buildings[GetRandomInt(0, 20)]
		endmethod
		
		/**
		 * resets the buildings that can build by config
		 */
		public method resetBuildings takes nothing returns nothing
			local integer building
			loop
			    set .buildings[building] = 0
				set building = building + 1
			    exitwhen building == 20
			endloop
			set .buildingPosition = 0
		endmethod
	endstruct
	
	/**
	 * the towers
	 */
	struct Tower
	    public integer towerTypeId
	    private Tower parentTower
	    private Tower childTower
	    private boolean childTowerExists = false
		private boolean parentTowerExists = false	    
	    public integer cost

		/**
		 * set the child tower
		 * @param Towe childTower
		 */
		public method setChildTower takes Tower childTower returns nothing
			set .childTowerExists = true
			set .childTower = childTower
			if childTower.hasParentTower() == false then
				call childTower.setParentTower(this)
			endif
		endmethod

		/**
		 * set the parent tower
		 * @param Towe parentTower
		 */
		public method setParentTower takes Tower parentTower returns nothing
			set .parentTower = parentTower
			set .parentTowerExists = true
			if parentTower.hasChildTower() == false then
				call parentTower.setChildTower(this)
			endif
		endmethod
		
		/**
		 * has tower an child tower
		 * @return boolean
		 */
		public method hasChildTower takes nothing returns boolean
			return .childTowerExists
		endmethod
		
		/**
		 * has tower an parent tower
		 * @return boolean
		 */
		public method hasParentTower takes nothing returns boolean
			return .parentTowerExists
		endmethod
		
		/**
		 * gets parent tower
		 * @return Tower
		 */
		public method getParentTower takes nothing returns Tower
		    return .parentTower
		endmethod
		
		/**
		 * gets child tower
		 * @return Tower
		 */
		public method getChildTower takes nothing returns Tower
			return .childTower
		endmethod
	    /**
	     * search towerTypeId in the tower
	     * @param integer towerTypeId
	     * @return boolean
	     */
	    public method hasTowerId takes integer towerTypeId returns boolean
			local boolean childTowerHasType
			set childTowerHasType = .childTowerExists == true and .childTower.hasTowerId(towerTypeId) 
	    	return .towerTypeId == towerTypeId or childTowerHasType
	    endmethod
	endstruct

    /**
     * the AI for the tower build
     */
    struct TowerBuildAI
        private static integer MAX_REGIONS = 3
        private static integer TOWER_WIDTH = 0
        private static integer TOWER_HEIGHT = 1
        public static integer SLEEP_BEFORE_BUILD = 1
        public static integer SLEEP_BEFORE_UPGRADE = 2
        
		private rect array rectangles[3]        
        private real array positionLeft[3]
        private real array positionRight[3]
        private real array positionTop[3]
        private real array positionBottom[3]
        private TowerPosition array towerPositions[3]
        private unit array tower[60]
        private integer towerKey
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
        public unit lastUnit
        public real array lastPosition[2]
        public integer array upgradeQueue[5]
        public boolean upgradeQueueActivate = true
        public integer playerId
        public TowerSystemAI systemTower
        private static TowerBuildAI me

		/**
		 * sets the builder
		 * @param unit Builder
		 */
        public method setBuilder takes unit builder returns nothing
            set .builder = builder
            set .enabled = true
            set thistype.me = this
        endmethod
        
        /**
         * add tower to array
         * @param unit tower
         */
        public method addTower takes unit tower returns nothing
        	set .tower[.towerKey] = tower
        	set .towerKey = .towerKey + 1
        endmethod
        
        /**
         * set the tower size
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
		 * upgrade towers from the queue
		 * @return boolean
		 */
		private method upgradeFirstFromQueue takes nothing returns boolean
            local integer currentPosition = 10
            local integer towerTypeId = 0
            local integer lastTowerTypeId = 0
            local Tower towerBuild
            local boolean result = false
            local Tower lastTowerBuild
            loop
            	exitwhen currentPosition < 0
            	set towerTypeId = .upgradeQueue[currentPosition]
            	set .upgradeQueue[currentPosition] = lastTowerTypeId
            	set lastTowerTypeId = towerTypeId
            	set currentPosition = currentPosition - 1
            endloop
            if towerTypeId != 0 then
                set towerBuild = .systemTower.findTowersById(towerTypeId)
                set lastTowerBuild = towerBuild
                loop
                	if (.getTowerUnitKeyById(towerBuild.towerTypeId) < 60) then
                        set lastTowerBuild = towerBuild
                    endif
                	exitwhen towerBuild.getChildTower().towerTypeId == towerTypeId
                	set towerBuild = towerBuild.getChildTower()
                endloop
				set result = .upgrade(lastTowerBuild.getChildTower())
				if result == false or towerBuild.towerTypeId != towerTypeId then
					call .addToUpgradeQueue(towerTypeId)
				endif
			endif
			return result
		endmethod
		
		/**
		 * add an tower type id to upgrade queue
		 * @param integer towerTypeid
		 */
		private method addToUpgradeQueue takes integer towerTypeId returns nothing
            local integer currentPosition = 10
            loop
            	exitwhen currentPosition == 0 or .upgradeQueue[currentPosition - 1] != 0
            	set currentPosition = currentPosition - 1
            endloop
            if currentPosition < 10 then
            	set .upgradeQueue[currentPosition] = towerTypeId
            endif 
		endmethod
		
		/**
		 * build next unit
		 * @param Tower tower
		 * @return boolean
		 */
        public method upgrade takes Tower tower returns boolean
 			local integer key
 			set key = .getTowerUnitKeyById(tower.getParentTower().towerTypeId)
			return key < 60 and IssueImmediateOrderById(.tower[key], tower.towerTypeId)
		endmethod
		/**
		 * build next unit
		 * @param integer unitId
		 * @return boolean
		 */
        public method build takes integer unitId returns boolean
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
					
					if builded then
						set .lastPosition[0] = positionX
						set .lastPosition[1] = positionY
					endif
					exitwhen builded
					exitwhen positionX < .positionLeft[currentRegion]
					exitwhen positionX > .positionRight[currentRegion]
					exitwhen positionY > .positionTop[currentRegion]
					exitwhen positionY < .positionBottom[currentRegion]
 				endloop
 				exitwhen builded
 				set currentRegion = currentRegion + 1
 			endloop
			return builded
        endmethod
        
        /**
         * get an tower by id
         * @param integer towerTypeId
         * @return integer
         */
        private method getTowerUnitKeyById takes integer towerTypeId returns integer
        	local integer currentTowerPosition = 0
        	loop
        		exitwhen GetUnitTypeId(.tower[currentTowerPosition]) == towerTypeId
        		set currentTowerPosition = currentTowerPosition + 1
        	endloop
        	return currentTowerPosition
        endmethod
        
    	/**
    	 * build next tower
    	 */
    	public method buildNext takes nothing returns nothing
            local boolean builded = false
            local integer lumber = 0
            local integer towerTypeId
            local unit currentTower
		    local group all = CreateGroup()
		    local group closest = CreateGroup()
		    local Tower tower
            set .builded = false
            set lumber = Game.getPlayerLumber(.playerId)
            set towerTypeId = .config.getRandomBuilding()
            set tower = .systemTower.findTowersById(towerTypeId)
            if .isEnabled() then
                if .canBuild then
                	if .lumber + 0 <= lumber then
                        //configuration search
                        //add towerCosts.GetUnitCostById(unitType, GetTowerCost.COST_LUMBER)
                        if lumber >= 400 then //if user has enough lumber to build
                            set .builded = .build(tower.towerTypeId)
							if .builded then
				        		set .lumber = Game.getPlayerLumber(.playerId)
							endif
                        endif
                        if tower.towerTypeId != towerTypeId then
							call .addToUpgradeQueue(towerTypeId)
                        endif
					endif
				endif
				set .canBuild = .builded
			endif
        endmethod
        
        /**
         * build tower after sleep
         */
        private static method buildAfterSleep takes nothing returns nothing
        	call thistype.me.buildNext()
        endmethod
        
        /**
         * upgrade tower after sleep
         */
        private static method upgradeAfterSleep takes nothing returns nothing
            call thistype.me.upgradeFirstFromQueue()
        endmethod
        
        /**
         * look how many upgrades are in the queue
         */
        private method countUpgradeQueue takes nothing returns integer
        	local integer currentPosition = 0
        	local integer queueCount = 0
        	loop
        		exitwhen currentPosition >= 10
        		if .upgradeQueue[currentPosition] != 0 then 
                    set queueCount = queueCount + 1
                endif
        	endloop
        	return queueCount
        endmethod
        
        /**
         * that the builders can build after start
         */
        public method eventWithSleep takes integer eventType returns nothing
            local timer tAI = CreateTimer()
            if eventType == thistype.SLEEP_BEFORE_BUILD then
            	call TimerStart(tAI, 1.0, false, function thistype.buildAfterSleep)
            elseif eventType == thistype.SLEEP_BEFORE_UPGRADE then
                if .countUpgradeQueue > 0 then
	        		call TimerStart(tAI, 1.0, false, function thistype.upgradeAfterSleep)
	        	endif
	        endif
			set tAI = null
        endmethod
    endstruct

    /**
     * ----------------------------- STRUCT TowerSystemAI ---------------------------------
     */
    struct TowerSystemAI
		private static integer MAX_PLAYER = 6
		private static TowerBuildAI array towerBuilder[6]
		public static integer lastUnit
        private static Tower array towers[11]

		/**
		 * find the tower with child towers
		 * @paraminteger towerTypeId
		 */
		public method findTowersById takes integer towerTypeId returns Tower
			local integer currentTower = 0
			local Tower searchedTower
			loop
				exitwhen currentTower >= 11
				if .towers[currentTower].hasTowerId(towerTypeId) then
					set searchedTower = .towers[currentTower]
					set currentTower = 20
				endif
				set currentTower = currentTower + 1
			endloop
			return searchedTower
		endmethod

		/**
		 * gets the builder-ai by position
		 * @param integer position
		 * @return ToweBuildAI
		 */
		public method getBuildAIByPosition takes integer position returns TowerBuildAI
			return .towerBuilder[position]
		endmethod
		
		private method initTowers takes nothing returns nothing
	        local Tower tower
		
	        //cursed
	        set tower = Tower.create()
	        set tower.towerTypeId = 'u00X'
	        call tower.setChildTower(Tower.create())
	        set tower.getChildTower().towerTypeId = 'u011'
	        call tower.getChildTower().setChildTower(Tower.create())
	        set tower.getChildTower().getChildTower().towerTypeId = 'u012'
			set .towers[0] = tower
			
	        //Decayed
			set tower = Tower.create()
	        set tower.towerTypeId = 'u013'
	        call tower.setChildTower(Tower.create())
	        set tower.getChildTower().towerTypeId = 'u014'
	        call tower.getChildTower().setChildTower(Tower.create())
	        set tower.getChildTower().getChildTower().towerTypeId = 'u015'
			set .towers[1] = tower
			
	        //Gloom
			set tower = Tower.create()
	        set tower.towerTypeId = 'u01D'
	        call tower.setChildTower(Tower.create())
	        set tower.getChildTower().towerTypeId = 'u01E'
	        call tower.getChildTower().setChildTower(Tower.create())
	        set tower.getChildTower().getChildTower().towerTypeId = 'u01F'
			set .towers[2] = tower
			
	        //Shady
			set tower = Tower.create()
	        set tower.towerTypeId = 'u00R'
	        call tower.setChildTower(Tower.create())
	        set tower.getChildTower().towerTypeId = 'u00S'
	        call tower.getChildTower().setChildTower(Tower.create()) 
	        set tower.getChildTower().getChildTower().towerTypeId = 'u00T'
			set .towers[3] = tower
			
	        //Totem
			set tower = Tower.create()
	        set tower.towerTypeId = 'u01M'
	        call tower.setChildTower(Tower.create())
	        set tower.getChildTower().towerTypeId = 'u01R'
	        call tower.getChildTower().setChildTower(Tower.create())
	        set tower.getChildTower().getChildTower().towerTypeId = 'u01T'
			set .towers[4] = tower
			
	        //Putrid
			set tower = Tower.create()
	        set tower.towerTypeId = 'u01A'
	        call tower.setChildTower(Tower.create())
	        set tower.getChildTower().towerTypeId = 'u01B'
	        call tower.getChildTower().setChildTower(Tower.create())
	        set tower.getChildTower().getChildTower().towerTypeId = 'u01C'
			set .towers[5] = tower
			
	        //Magma
			set tower = Tower.create()
	        set tower.towerTypeId = 'u01I'
	        call tower.setChildTower(Tower.create())
	        set tower.getChildTower().towerTypeId = 'u01G'
	        call tower.getChildTower().setChildTower(Tower.create())
	        set tower.getChildTower().getChildTower().towerTypeId = 'u01H'
			set .towers[6] = tower
			
	        //Ice
			set tower = Tower.create()
	        set tower.towerTypeId = 'u016'
	        call tower.setChildTower(Tower.create())
	        set tower.getChildTower().towerTypeId = 'u017'
	        call tower.getChildTower().setChildTower(Tower.create())
	        set tower.getChildTower().getChildTower().towerTypeId = 'u018'
			set .towers[7] = tower
			
	        //Rock
			set tower = Tower.create()
	        set tower.towerTypeId = 'u00Y'
	        call tower.setChildTower(Tower.create())
	        set tower.getChildTower().towerTypeId = 'u00Z'
	        call tower.getChildTower().setChildTower(Tower.create())
	        set tower.getChildTower().getChildTower().towerTypeId = 'u010'
			set .towers[8] = tower
			
	        //Obelisk
			set tower = Tower.create()
	        set tower.towerTypeId = 'u00U'
	        call tower.setChildTower(Tower.create())
	        set tower.getChildTower().towerTypeId = 'u00V'
	        call tower.getChildTower().setChildTower(Tower.create())
	        set tower.getChildTower().getChildTower().towerTypeId = 'u00W'
			set .towers[9] = tower
			
	        //Glacier
			set tower = Tower.create()
	        set tower.towerTypeId = 'u01J'
	        call tower.setChildTower(Tower.create())
	        set tower.getChildTower().towerTypeId = 'u01K'
	        call tower.getChildTower().setChildTower(Tower.create())
	        set tower.getChildTower().getChildTower().towerTypeId = 'u01L'
			set .towers[10] = tower
		endmethod
		
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
			call buildConfig.addBuilding('u00Y')
			call buildConfig.addBuilding('u00S')
			call buildConfig.addBuilding('u00S')
			call buildConfig.addBuilding('u00Y')
			call buildConfig.addBuilding('u00Y')
			call buildConfig.addBuilding('u00S')
			call buildConfig.addBuilding('u00S')
			call buildConfig.addBuilding('u00Y')
			call buildConfig.addBuilding('u00Y')
			call buildConfig.addBuilding('u00S')
			call buildConfig.addBuilding('u00Y')
			call buildConfig.addBuilding('u00Y')
			call .towerBuilder[playerId].setConfig(buildConfig)
		endmethod
		
        /**
         * create all tower-build-AI needed objects
         */
        public method initTowerBuildAI takes nothing returns nothing
            local unit building = CreateUnit( Player(0), 'u00U', 0, 0, bj_UNIT_FACING ) 
	        local real width = GetUnitCollision(building)
	        local real height = width
	        call RemoveUnit(building)
	        
	        call .initTowers()
	        
            set .towerBuilder[TOWER_SYSTEM_AI_TOP_LEFT] = TowerBuildAI.create()
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_LEFT].addRectangle(gg_rct_TowersTopLeftTop)
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_LEFT].addRectangle(gg_rct_TowersTopLeftBottom)
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_LEFT].initPositions()
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_LEFT].setBuildFromTo(true, false)
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_LEFT].setTowerSize(width, height)
            call .initTowerConfig(TOWER_SYSTEM_AI_TOP_LEFT)
            set .towerBuilder[TOWER_SYSTEM_AI_TOP_LEFT].playerId = TOWER_SYSTEM_AI_TOP_LEFT
            set .towerBuilder[TOWER_SYSTEM_AI_TOP_LEFT].systemTower = this
            
            set .towerBuilder[TOWER_SYSTEM_AI_TOP_RIGHT] = TowerBuildAI.create()
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_RIGHT].addRectangle(gg_rct_TowersTopRightTop)
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_RIGHT].addRectangle(gg_rct_TowersTopRightBottom)
			call .towerBuilder[TOWER_SYSTEM_AI_TOP_RIGHT].initPositions()
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_RIGHT].setBuildFromTo(false, false)
            call .towerBuilder[TOWER_SYSTEM_AI_TOP_RIGHT].setTowerSize(width, height)
            set .towerBuilder[TOWER_SYSTEM_AI_TOP_RIGHT].playerId = TOWER_SYSTEM_AI_TOP_RIGHT
            set .towerBuilder[TOWER_SYSTEM_AI_TOP_RIGHT].systemTower = this
            
            set .towerBuilder[TOWER_SYSTEM_AI_LEFT] = TowerBuildAI.create()
            call .towerBuilder[TOWER_SYSTEM_AI_LEFT].addRectangle(gg_rct_TowersLeftTop)
            call .towerBuilder[TOWER_SYSTEM_AI_LEFT].addRectangle(gg_rct_TowersLeftBottom)
            call .towerBuilder[TOWER_SYSTEM_AI_LEFT].initPositions()
            call .towerBuilder[TOWER_SYSTEM_AI_LEFT].setBuildFromTo(true, false)
            call .towerBuilder[TOWER_SYSTEM_AI_LEFT].setTowerSize(width, height)
            set .towerBuilder[TOWER_SYSTEM_AI_LEFT].playerId = TOWER_SYSTEM_AI_LEFT
            set .towerBuilder[TOWER_SYSTEM_AI_LEFT].systemTower = this
            
            set .towerBuilder[TOWER_SYSTEM_AI_RIGHT] = TowerBuildAI.create()
            call .towerBuilder[TOWER_SYSTEM_AI_RIGHT].addRectangle(gg_rct_TowersRightTop)
            call .towerBuilder[TOWER_SYSTEM_AI_RIGHT].addRectangle(gg_rct_TowersRightBottom)
            call .towerBuilder[TOWER_SYSTEM_AI_RIGHT].initPositions()
            call .towerBuilder[TOWER_SYSTEM_AI_RIGHT].setBuildFromTo(false, false)
            call .towerBuilder[TOWER_SYSTEM_AI_RIGHT].setTowerSize(width, height)
            set .towerBuilder[TOWER_SYSTEM_AI_RIGHT].playerId = TOWER_SYSTEM_AI_RIGHT
            set .towerBuilder[TOWER_SYSTEM_AI_RIGHT].systemTower = this
            
            set .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_LEFT] = TowerBuildAI.create()
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_LEFT].addRectangle(gg_rct_TowersBottomLeftLeft)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_LEFT].addRectangle(gg_rct_TowersBottomLeftTop)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_LEFT].addRectangle(gg_rct_TowersBottomLeftRight)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_LEFT].initPositions()
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_LEFT].setBuildFromTo(true, false)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_LEFT].setTowerSize(width, height)
            set .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_LEFT].playerId = TOWER_SYSTEM_AI_BOTTOM_LEFT
            set .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_LEFT].systemTower = this
            
            set .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_RIGHT] = TowerBuildAI.create()
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_RIGHT].addRectangle(gg_rct_TowersBottomRightLeft)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_RIGHT].addRectangle(gg_rct_TowersBottomRightTop)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_RIGHT].addRectangle(gg_rct_TowersBottomRightRight)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_RIGHT].initPositions()
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_RIGHT].setBuildFromTo(false, false)
            call .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_RIGHT].setTowerSize(width, height)
            set .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_RIGHT].playerId = TOWER_SYSTEM_AI_BOTTOM_RIGHT
            set .towerBuilder[TOWER_SYSTEM_AI_BOTTOM_RIGHT].systemTower = this
            
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
			local code c1 = function thistype.onConstructFinish
			local code c2 = function thistype.onConstructStart
            
            //Register Tower Events for Player 1-6
            loop
                exitwhen i > 5
                if Game.isPlayerInGame(i) then
					call TriggerRegisterPlayerUnitEvent(t1, Player(i), EVENT_PLAYER_UNIT_UPGRADE_FINISH, null)
                    call TriggerRegisterPlayerUnitEvent(t2, Player(i), EVENT_PLAYER_UNIT_CONSTRUCT_FINISH, null)
                    call TriggerRegisterPlayerUnitEvent(t3, Player(i), EVENT_PLAYER_UNIT_CONSTRUCT_START, null)
                endif
                set i = i + 1
            endloop
            call TriggerAddCondition(t1, Filter(c1))
            call TriggerAddCondition(t2, Filter(c1))
            call TriggerAddCondition(t3, Filter(c2))
            set t1 = null
            set t2 = null
            set t3 = null
            set c1 = null
            set c2 = null
        endmethod
        
        /**
         * tower build or upgrade is finished
         */
        public static method onConstructFinish takes nothing returns nothing
			local unit triggerUnit = GetTriggerUnit() //Tower
            local integer playerId = GetPlayerId(GetOwningPlayer(triggerUnit))
            set .towerBuilder[playerId].lastUnit = triggerUnit
    		call .towerBuilder[playerId].addTower(triggerUnit)
    		if .towerBuilder[playerId].isEnabled() then
            	call .towerBuilder[playerId].eventWithSleep(.towerBuilder[playerId].SLEEP_BEFORE_UPGRADE)
            endif
            set triggerUnit = null
    	endmethod
        
        /**
         * tower build is started
         */
        public static method onConstructStart takes nothing returns nothing
            local integer playerId = GetPlayerId(GetOwningPlayer(GetTriggerUnit()))
            if .towerBuilder[playerId].isEnabled() then
            	call .towerBuilder[playerId].eventWithSleep(.towerBuilder[playerId].SLEEP_BEFORE_BUILD)
            endif
    	endmethod

		/**
		 * build start
		 */
        public static method buildStart takes nothing returns nothing
            local integer playerId = 0
            loop
            	exitwhen playerId >= .MAX_PLAYER
        		set .towerBuilder[playerId].canBuild = true
            	call .towerBuilder[playerId].buildNext()
                set playerId = playerId + 1
            endloop
        endmethod
        
    endstruct
endscope
