scope SpiritArrows initializer init
    /*
     * Description: The Farseer sends out arrows of his spirit homing towards a target location and 
                    dealing damage enemy units on collision.The Arrows last for up to 7 seconds and will fly 
                    around near the target location until death.
     * Last Update: 09.01.2014
     * Changelog: 
     *     09.01.2014: Abgleich mit OE und der Exceltabelle
     */
    globals
        private constant integer SPELL_ID = 'A09J'
        private constant integer ARROWS = 5
        private constant integer ARROWSGAIN = 3 // per Level
        private constant real SPEEDSTART = 450.00
        private constant real SCALE = 1.2
        private constant real ACCELERATION = 250.00
        private constant real ANGLESPEED = 150.00 * bj_DEGTORAD
        private constant real SPEEDMAX = 900.00
        private constant real EXPIRATIONTIME = 7.00
        private constant string MODEL_PATH = "Models\\SpiritArrow_ByEpsilon.mdx"
        
        //Stun Effect
        private constant string STUN_EFFECT = ""
        private constant string STUN_ATT_POINT = ""
        private constant real STUN_DURATION = 1.0
        
        private xedamage damageOptions
    endglobals
    
    private constant function Damage takes integer level returns real
        return 100.0 
    endfunction

    private function setupDamageOptions takes xedamage d returns nothing
       set d.dtype = DAMAGE_TYPE_LIGHTNING
       set d.atype = ATTACK_TYPE_NORMAL

       set d.exception = UNIT_TYPE_STRUCTURE
       set d.damageEnemies = true 
       set d.damageAllies  = false
       set d.damageNeutral = false
       set d.damageSelf    = false
    endfunction

    private struct SpiritArrows extends xecollider
        unit caster
        integer level
        
        method onUnitHit takes unit target returns nothing
            if (damageOptions.allowedTarget( this.caster  , target ) ) then
                call damageOptions.damageTarget(this.caster, target, Damage(this.level))
                call Stun_UnitEx(target, STUN_DURATION, true, STUN_EFFECT, STUN_ATT_POINT)
                call this.terminate()
            endif
        endmethod
    endstruct

    private function Conditions takes nothing returns boolean
        local SpiritArrows arrow = 0
        local integer i = 0
        local integer max = 0
        local integer spelllevel = 0
        local unit caster = null
        local real tx = 0.00
        local real ty = 0.00
        local real cx = 0.00
        local real cy = 0.00
        local real angle = 0.00
        local real anglefan = 0.00
        local real anglediff = 0.00
        
        if( GetSpellAbilityId() == SPELL_ID ) then
            set caster = GetTriggerUnit()
            set tx = GetSpellTargetX()
            set ty = GetSpellTargetY()
            set cx = GetUnitX( caster )
            set cy = GetUnitY( caster )
            set spelllevel = GetUnitAbilityLevel( caster, SPELL_ID )
            set max = ARROWS + ARROWSGAIN * spelllevel
            set angle = Atan2( cy - ty, cx - tx )
            
            loop
                exitwhen i >= max
                set anglefan = bj_PI/GetRandomInt(1,10)
                set anglediff = (bj_PI/GetRandomInt(2,6)/max)
                set arrow = SpiritArrows.create( cx, cy, angle-anglefan+i*anglediff )
                set arrow.speed = SPEEDSTART
                set arrow.scale = SCALE
                set arrow.acceleration = ACCELERATION - GetRandomReal(5.0, 85.0)
                set arrow.maxSpeed = SPEEDMAX
                set arrow.z = 80
                set arrow.angleSpeed = ANGLESPEED
                set arrow.expirationTime = EXPIRATIONTIME
                set arrow.fxpath = MODEL_PATH
                call arrow.setTargetPoint( tx, ty )
                
                set arrow.caster = caster
                set arrow.level = spelllevel
                set i = i + 1
            endloop
            
            set caster = null
        endif
        
        return false
    endfunction

    private function init takes nothing returns nothing
        local trigger t = CreateTrigger()
        
        // Initializing the damage options:
        set damageOptions = xedamage.create()
        call setupDamageOptions(damageOptions)
        
        call XE_PreloadAbility(SPELL_ID)
        call Preload(MODEL_PATH)
        
        call TriggerRegisterAnyUnitEventBJ( t, EVENT_PLAYER_UNIT_SPELL_EFFECT )
        call TriggerAddCondition( t, function Conditions )
        set t = null
    endfunction

endscope