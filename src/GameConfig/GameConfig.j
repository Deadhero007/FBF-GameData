scope GameConfig
	
	// PUBLIC GLOBALS
	globals
		constant boolean TEST_MODE = false
	endglobals
	
	private module Init
        
        static method onInit takes nothing returns nothing
			/*
			 * Module, die vor dem eigentlichen GameStart geladen werden m�ssen 
			 */
			call GetHost()
			call GoldIncome.initialize()
			
			//GAME START
			call GameStart.initialize()
        endmethod
    endmodule
    
    private struct GameConfig
        implement Init
    endstruct

endscope