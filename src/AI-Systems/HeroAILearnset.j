scope HeroAILearnset initializer Init

	globals
		// The level at which the hero learns all of its skills
		private constant integer MAX_SKILL_LVL = 19 	
	
	
		private Learnset learnsetInfo
	endglobals

	struct Learnset extends array
		private static TableArray info
        
        method operator [] takes integer lvl returns Table
            return info[lvl - 1]
        endmethod
		
		static method create takes nothing returns thistype
			set info = TableArray[MAX_SKILL_LVL]
			
			return 1
		endmethod
	endstruct
	
	private function Init takes nothing returns nothing
		// Learnset Syntax:
    	// set learnsetInfo[LEVEL OF HERO][HERO UNIT-TYPE ID] = SKILL ID
    	
    	//Abomination
		// Cleave
		set learnsetInfo[1]['H00G'] = 'H06M' 
    	set learnsetInfo[4]['H00G'] = 'H06M'
    	set learnsetInfo[8]['H00G'] = 'H06M'
		set learnsetInfo[11]['H00G'] = 'H06M'
		set learnsetInfo[15]['H00G'] = 'H06M'
    	// Consume Himself
        set learnsetInfo[2]['H00G'] = 'A06K' 
    	set learnsetInfo[5]['H00G'] = 'A06K'
    	set learnsetInfo[9]['H00G'] = 'A06K'
		set learnsetInfo[13]['H00G'] = 'A06K'
		set learnsetInfo[16]['H00G'] = 'A06K'
    	// Plague Cloud
        set learnsetInfo[3]['H00G'] = 'A06G' 
    	set learnsetInfo[7]['H00G'] = 'A06G'
    	set learnsetInfo[10]['H00G'] = 'A06G'
		set learnsetInfo[14]['H00G'] = 'A06G'
		set learnsetInfo[17]['H00G'] = 'A06G'
    	// Snack
        set learnsetInfo[6]['H00G'] = 'A021' 
		set learnsetInfo[12]['H00G'] = 'A021'
		set learnsetInfo[18]['H00G'] = 'A021' 
	endfunction

endscope