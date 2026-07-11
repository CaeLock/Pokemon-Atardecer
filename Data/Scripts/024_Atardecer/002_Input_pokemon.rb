class Generate_Input_Pokemon

  def initialize
  end

  def speciesExist?(species)
    if species.is_a?(String) || species.is_a?(Symbol)
      @species=getID(PBSpecies,species)
      return false if @species<=0
    end
  end

  def isBaby?(pokemon)
    baby=$babySpeciesData[pokemon] ? $babySpeciesData[pokemon] :
        ($babySpeciesData[pokemon]=pbGetBabySpecies(pokemon))
    return baby == @species
  end

  def isLegendary?(pokemon)
    legendary= [
      :MEWTWO,:MEW,:ARTICUNO,:ZAPDOS,:MOLTRES,
      :SUICUNE,:RAIKOU,:ENTEI,
      :REGIGIGAS,:REGIROCK,:REGICE,:REGISTEEL,
      :TORNADUS,:THUNDURUS,:LANDORUS,
      :TAPUKOKO,:TAPULELE,:TAPUBULU,:TAPUFINI,
      :LUGIA,:HOOH,:CELEBI,
      :RAYQUAZA,:KYOGRE,:GROUDON,:LATIOS,:LATIAS,
      :KYUREM,:ZEKROM,:RESHIRAM,:KELDEO,:COBALION,:TERRAKION,:VIRIZION,
      :MANAPHY,:JIRACHI,:SHAYMIN,:MAGEARNA,:MELOETTA,:VOLCANION,
      :UXIE,:MESPRIT,:AZELF,:VICTINI,:HOOPA,:PHIONE,
      :CRESSELIA,:DARKRAI,:HEATRAN,
      :YVELTAL,:XERNEAS,:ZYGARDE,
      :GENESECT,:MARSHADOW,:DEOXYS,:DIANCIE,:ZERAORA,
      :ARCEUS,:GIRATINA,:DIALGA,:PALKIA,
      :TYPENULL,:SILVALLY,:MELTAN,:MELMETAL,
      :BUZZWOLE,:GUZZLORD,:CELESTEELA,:PHEROMOSA,:XURKITREE,:KARTANA,:BLACEPHALON,
      :NIHILEGO,:STAKATAKA,:POIPOLE,:NAGANADEL,:NECROZMA,:COSMOG,:COSMOEM,:SOLGALEO,:LUNALA,
      :ZAMAZENTA,:ZACIAN,:ETERNATUS,
      :KUBFU,:URSHIFU,:ZARUDE,:REGIELEKI,:REGIDRAGO,:GLASTRIER,:SPECTRIER,:CALYREX,:ENAMORUS,
      :GREATTUSK,:SCREAMTAIL,:BRUTEBONNET,:FLUTTERMANE,:SANDYSHOCKS,:IRONTREADS,:IRONBUNDLE,:IRONHANDS,
      :IRONJUGULIS,:IRONMOTH,:IRONTHORNS,:WOCHIEN,:TINGLU,:CHIYU,:CHIENPAO,:ROARINGMOON,:IRONVALIANT,
      :KORAIDON,:MIRAIDON,:WALKINGWAKE,:IRONLEAVES,:OKIDOGI,:MUNKIDORI,:FEZANDIPITI,:OGERPON,:GOUGINGFIRE,
      :RAGINGBOLT,:IRONBOULDER,:IRONCROWN,:TERAPAGOS,:PECHARUNT,
      ]
    return true if legendary.include?(pokemon)
  end
  
  def input_generate(level)
    loop do
      pokemon=pbEnterText("¿Quién es tu compañero Pokémon?",1,80)
      pokemon=pokemon.upcase.to_sym
      if speciesExist?(pokemon)==false || isBaby?(@species)==false || isLegendary?(pokemon)==true
        Kernel.pbMessage(_INTL("¡El Pokémon es inválido! Escoge solo primeras etapas o no legendarios."))
      else
        if Kernel.pbConfirmMessage(_INTL("¿Es {1} tu compañero?",pokemon))
          poke = PokeBattle_Pokemon.new(@species, level, $Trainer) #creates a pokemon
          stat_order = Kernel.pbOrderByBaseStats(poke)       # the 3 highest stats have guaranteed high IVs
=begin
          p stat_order.map { |id|
                  name = PBStats.constants.find { |c| PBStats.const_get(c) == id } ||
                  (PBStats.respond_to?(:getName) ? PBStats.getName(id) : id)
                  name.to_s.upcase.gsub(/\s+/, "_").to_sym
                  }
=end
          poke.iv[stat_order[0]] = rand(16..31)
          poke.iv[stat_order[1]] = rand(16..31)
          poke.iv[stat_order[2]] = rand(16..31)
          poke.calcStats
          $game_variables[26] = @species                         # starter pkmn species
          pbMarkAsStarter(poke)                                  # marks it as starter
          pbAddPokemon(poke)                                     
          break
        end
      end
    end
  end

end

#===============================================================================
# Event commands
#===============================================================================
def pbInputStarterPokemon(level=5)
  Generate_Input_Pokemon.new.input_generate(level)
end