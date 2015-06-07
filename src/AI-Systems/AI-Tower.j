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
        private TowerSystemAI TOWER_BUILD_AI
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
            set TOWER_BUILD_AI = TowerSystemAI.create()
            set ACOLYTS[0] = CreateUnit(Player(0), ACOLYTE_I_ID, R2I(GetRectCenterX(gg_rct_TowersTopLeftTop)), R2I(GetRectCenterY(gg_rct_TowersTopLeftTop)), bj_UNIT_FACING)

            //@TODO: Currently only to test must change!
            call TOWER_BUILD_AI.generateBuildPositions(gg_rct_TowersTopLeftTop, GetRectCenterX(gg_rct_TowersTopLeftTop), 3, 0, ACOLYTS[0])
//            call TOWER_BUILD_AI.buildNext(ACOLYTS[0], 0)
        endmethod

        public static method buildTowerAI takes nothing returns nothing
            call TOWER_BUILD_AI.buildNext(ACOLYTS[0], 0)
        endmethod
    endstruct

    struct TowerPositions

        private real array POS_X[10]
        private real POS_Y
        private integer maxPos = 0
        private boolean array BUILDED[10]

        public method setYPos takes real posY returns nothing
            set .POS_Y = posY
        endmethod

        public method addXPos takes real posX returns nothing
            set .POS_X[.maxPos] = posX
            set .BUILDED[.maxPos] = false
            set .maxPos = .maxPos + 1
        endmethod

        public method getYPos takes nothing returns real
            return .POS_Y
        endmethod

        public method getMaxPos takes nothing returns integer
            return .maxPos
        endmethod

        public method getXPosByPosition takes integer position returns real
            return .POS_X[position]
        endmethod

        public method getNextFreePosition takes nothing returns integer
           local integer currentPosition = 0
           loop
               exitwhen .maxPos <= currentPosition
               exitwhen .BUILDED[currentPosition] == false
               set currentPosition = currentPosition + 1
           endloop
           return currentPosition
        endmethod

        public method isFreePosition takes integer position returns boolean
           return .BUILDED[position]
        endmethod

        public method setBuilded takes integer position, boolean value returns nothing
           set .BUILDED[position] = value
        endmethod
    endstruct

    struct TowerBuildAI

    endstruct

    /**
     *
     */
    struct TowerSystemAI

        /**
         * ALL Buildable Positions
         */
        private TowerPositions array TOWER_POSITIONS[6]

        private unit array BUILDER[6]
        private real oneFieldCollision = 63

        public integer LEFT_TOP = 0
        public integer LEFT_BOTTOM = 1
        public integer BOTTOM_LEFT = 2
        public integer BOTTOM_RIGHT = 3
        public integer RIGHT_BOTTOM = 4
        public integer RIGHT_TOP = 5

        public method addBuilder takes integer buildPos, unit builder returns nothing
            set .BUILDER[buildPos] = builder
        endmethod

        public method generateBuildPositions takes rect Rectangle, real endX, integer fieldLength, integer position, unit acolyt returns nothing
            local real startX = GetRectCenterX(Rectangle)
            local real startY = GetRectCenterY(Rectangle)
            local real collision = oneFieldCollision * fieldLength
            local integer maxChangeX = 0
            local integer rectanglePositions = 0

            if ( startX > endX ) then
                set maxChangeX = R2I((startX - endX) / collision)
            else
                set maxChangeX = R2I((endX - startX) / collision)
            //    set collision = -collision
            endif
            if ( .checkPosition(position) ) then
                set .TOWER_POSITIONS[position] = TowerPositions.create()
                loop
                    call .TOWER_POSITIONS[position].addXPos(endX - ((maxChangeX - rectanglePositions) * collision))
                    call .TOWER_POSITIONS[position].setYPos(startY)
                    exitwhen maxChangeX <= rectanglePositions
                    set rectanglePositions = rectanglePositions + 1
                endloop
            endif
        endmethod

        private method checkPosition takes integer position returns boolean
           local boolean isExists = false
           if (position > -1) then
               if ( position < 6) then
                   set isExists = true
               endif
           endif
           return isExists
        endmethod

        public method buildNext takes unit acolyt, integer buildPosition returns nothing
            local real positionY = 0
            local real positionX = 0
            local integer position = 0

/*
            call BJDebugMsg(R2S(startX))
            call BJDebugMsg(R2S(startY))

            call BJDebugMsg(R2S(.TOWER_POSITIONS[0].getXPosByPosition(0)))
            call BJDebugMsg(R2S(.TOWER_POSITIONS[0].getYPos()))

                     call IssueBuildOrderById(acolyt, 'u00X', startX, startY)
                     call CreateUnit(Player(1), 'u00Q', startX, startY, bj_UNIT_FACING)
                    call PingMinimap(startX, startY, 100)
*/
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
        endmethod
    endstruct
endscope