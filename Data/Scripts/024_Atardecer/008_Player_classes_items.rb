################################################################################
# Item handlers
################################################################################

# ARISTOCRATA

ItemHandlers.addUseInField(:LUXURYCATALOG, proc {
   next pbCommonEvent(3)
})

ItemHandlers.addUseFromBag(:LUXURYCATALOG, proc {
   next pbCommonEvent(3)
})

# ARQUEOLOGA

ItemHandlers.addUseInField(:MININGKIT, proc {
   next pbCommonEvent(4)
})

ItemHandlers.addUseFromBag(:MININGKIT, proc {
   next pbCommonEvent(4)
})

# MEDICO

ItemHandlers::UseFromBag.add(:POKEVIAL,proc{|item|
   if $Trainer.pokemonCount==0
     Kernel.pbMessage(_INTL("No hay Pokémon."))
     next 0
   end
   if $game_variables[31] <= 0
       Kernel.pbMessage(_INTL("No te quedan cargas del Poké Vial"))
     next 0
   end
   case $game_variables[32]
   when 0
      heal_modifier = 3
   when 1
      heal_modifier = 2
   else
      heal_modifier = 1
   end
   pbFadeOutIn(99999){
      scene=PokemonScreen_Scene.new
      screen=PokemonScreen.new(scene,$Trainer.party)
      screen.pbStartScene(_INTL("Usando el objeto..."),false)
      for i in $Trainer.party
       if i.hp<=0 && !i.isEgg?
         heal_amount = (i.totalhp / heal_modifier).floor
         i.pbRecoverHP(heal_amount, true)
         i.healStatus
         screen.pbDisplay(_INTL("Los Pokémon han recuperado los PS y estados alterados.",i.name))
       end
     end
     screen.pbEndScene
   }
})