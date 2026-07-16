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

ItemHandlers::UseFromBag.add(:FIRSTAIDKIT,proc{|item|
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

# MONTARAZ

################################################################################
################################################################################
# FORAGING BAG
################################################################################
################################################################################
#===============================================================================
# While walking, every so many steps an item silently drops into the
# foraging bag -- a virtual container, separate from the player's actual
# Bag. Each step threshold below has its own table of possible items and
# its own independent counter, so several thresholds can trigger on the
# same step (e.g. every 1000 steps also counts as every 250, 500 and 800
# steps).
#
# The collected items only reach the player's real Bag when the foraging
# bag is emptied. That's meant to happen at camps: call
# ForagingBag.pbEmptyForagingBag (e.g. from a "Call Script" event command,
# or from wherever the camp feature is triggered from) whenever the player
# sets up camp.
#-------------------------------------------------------------------------------
# Tracks steps the same way the Soot Sack does (an Events.onStepTaken
# hook in PField_Field), but registered from this separate script instead
# of editing that file, and stores its data in dedicated
# PokemonGlobalMetadata fields, following this project's usual pattern for
# persisted feature data (see :sootsack, :dependentEvents, etc).
#===============================================================================
module ForagingBag
  # Item tables per step threshold. Add or remove item ID symbols here to
  # change what can drop at each threshold. A symbol that doesn't match a
  # defined item yet (i.e. hasn't been added to the PBS) is safely
  # ignored until it exists, so placeholders can be listed ahead of time.
  TABLES = {
    250 => [
      :ORANBERRY,:CHERIBERRY,:CHESTOBERRY,:PECHABERRY,:RAWSTBERRY,
      :ASPEARBERRY,:PERSIMBERRY,:HEALPOWDER
    ],
    500 => [
      :TINYMUSHROOM,:POMEGBERRY,:KELPSYBERRY,:QUALOTBERRY,:HONDEWBERRY,
      :GREPABERRY,:TAMATOBERRY,:LEPPABERRY,:SITRUSBERRY,:ENERGYPOWDER,:HONEY
    ],
    800 => [
      :ROSELIBERRY,:CHILANBERRY,:BABIRIBERRY,:COLBURBERRY,:HABANBERRY,
      :KASIBBERRY,:CHARTIBERRY,:PAYAPABERRY,:COBABERRY,:SHUCABERRY,
      :KEBIABERRY,:CHOPLEBERRY,:YACHEBERRY,:RINDOBERRY,:WACANBERRY,
      :PASSHOBERRY,:OCCABERRY,:PRETTYWING
    ],
    1000 => [
      :LUMBERRY,:ENIGMABERRY,:MICLEBERRY,:LANSATBERRY,:PETAYABERRY,
      :SALACBERRY,:GANLONBERRY,:LIECHIBERRY,:ENERGYROOT,:BIGMUSHROOM
    ],
    2000 => [
      :STARFBERRY,:CUSTAPBERRY,:REVIVALHERB,:HEALTHWING,:MUSCLEWING,
      :RESISTWING,:GENIUSWING,:CLEVERWING,:SWIFTWING
    ],
    # Unfinished table -- add more items as they get defined.
    5000 => [
      :JABOCABERRY,:ROWAPBERRY,:TWILIGHTHERB,:BALMMUSHROOM
    ],
    # Unfinished table -- add more items as they get defined.
    8000 => [
      :SILVERBERRY,:GOLDBERRY,:KEEBERRY,:MARANGABERRY
    ]
  }

  module_function

  # Resolves a table's item symbols into real item IDs, dropping any that
  # aren't defined yet, and caches the result per threshold.
  def resolvedTable(threshold)
    @resolvedTables ||= {}
    if !@resolvedTables[threshold]
      @resolvedTables[threshold] = (TABLES[threshold] || []).map { |i| getID(PBItems,i) }.select { |id| id && id>0 }
    end
    return @resolvedTables[threshold]
  end

  def stepCounters
    return $PokemonGlobal.foragingBagSteps
  end

  # Contents of the foraging bag (itemID => quantity), waiting to be
  # emptied into the player's actual Bag.
  def contents
    return $PokemonGlobal.foragingBagContents
  end

  # Whether the foraging bag is currently active: the player has to be a
  # Montaraz and actually own the Foraging Bag item.
  def active?
    return false if !PlayerClasses.current?(PlayerClasses::MONTARAZ)
    return false if !hasConst?(PBItems,:FORAGINGBAG)
    return $PokemonBag.pbHasItem?(:FORAGINGBAG)
  end

  # Call once per step taken. Advances every threshold's counter, and
  # drops a random item from its table into the foraging bag whenever a
  # counter reaches its threshold. Does nothing unless the foraging bag
  # is active (see active? above).
  def pbAdvanceStep
    return if !active?
    counters = stepCounters
    TABLES.each_key do |threshold|
      counters[threshold] = 0 if !counters[threshold]
      counters[threshold] += 1
      next if counters[threshold] < threshold
      counters[threshold] = 0
      pbAddRandomItem(threshold)
    end
  end

  def pbAddRandomItem(threshold)
    table = resolvedTable(threshold)
    return if table.empty?
    itemID = table[rand(table.length)]
    bag = contents
    bag[itemID] = 0 if !bag[itemID]
    bag[itemID] += 1
  end

  # Empties the foraging bag into the player's actual Bag. Meant to be
  # called whenever the player sets up camp. Anything that doesn't fit
  # (Bag full) is kept in the foraging bag for next time instead of being
  # lost. Returns true if there was anything to empty out.
  def pbEmptyForagingBag
    bag = contents
    return false if bag.empty?
    leftover = {}
    bagWasFull = false
    bag.each do |itemID,qty|
      next if qty<=0
      if !Kernel.pbReceiveItem(itemID,qty)
        leftover[itemID] = qty
        bagWasFull = true
      end
    end
    $PokemonGlobal.foragingBagContents = leftover
    if bagWasFull
      Kernel.pbMessage(_INTL("La mochila está demasiado llena para guardar el resto de lo recolectado."))
    end
    return true
  end
end

class PokemonGlobalMetadata
  attr_writer :foragingBagSteps
  attr_writer :foragingBagContents

  def foragingBagSteps
    @foragingBagSteps = {} if !@foragingBagSteps
    return @foragingBagSteps
  end

  def foragingBagContents
    @foragingBagContents = {} if !@foragingBagContents
    return @foragingBagContents
  end
end

Events.onStepTaken += proc { ForagingBag.pbAdvanceStep }