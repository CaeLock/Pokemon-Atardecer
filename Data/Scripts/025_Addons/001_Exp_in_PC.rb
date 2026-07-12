#===============================================================================
# PC Experience
#-------------------------------------------------------------------------------
# Based on a script by Kyu (https://newpokeliberty.blogspot.com/).
# Gives a share of the EXP earned in battle to every Pokemon sitting in the PC
# boxes, using the same formula as normal battle EXP gain, scaled down by
# EXP_RATE. Hooks into PokeBattle_Battle#pbGainEXP so it runs automatically
# after every battle, without touching any core script.
#===============================================================================
module PCExp
  # Master switch: set to false to disable PC EXP gain entirely.
  ENABLED = true

  # Whether boxed Pokemon are allowed to learn new moves when they level up
  # from this EXP gain. Set to false to level them up silently, without move
  # learning prompts/messages.
  LEARN_MOVES = true

  # Fraction of the normal EXP gain that boxed Pokemon receive.
  # 0.15 = 15% of what a party Pokemon would get for defeating the same foe.
  EXP_RATE = 0.15

  module_function

  # Called once per battle, with the list of defeated opposing battlers.
  def pbGivePCExp(defeatedBattlers)
    return if !ENABLED
    return if !defeatedBattlers || defeatedBattlers.empty?
    for x in 0...$PokemonStorage.maxBoxes
      for y in 0...$PokemonStorage.maxPokemon(x)
        pkmn=$PokemonStorage[x,y]
        next if !pkmn || pkmn.isEgg?
        for defeated in defeatedBattlers
          break if pkmn.exp>=PBExperience.pbGetMaxExperience(pkmn.growthrate)
          pbGivePCExpOne(pkmn,defeated)
        end
      end
    end
  end

  # Gives EXP to a single boxed Pokemon for a single defeated battler.
  def pbGivePCExpOne(pkmn,defeated)
    maxexp=PBExperience.pbGetMaxExperience(pkmn.growthrate)
    return if pkmn.exp>=maxexp
    oldlevel=pkmn.level
    baseexp=defeated.pokemon.baseExp
    exp=(defeated.level*baseexp).floor
    leveladjust=(2*defeated.level+10.0)/(defeated.level+pkmn.level+10.0)
    leveladjust=leveladjust**5
    leveladjust=Math.sqrt(leveladjust)
    exp=(exp*leveladjust).floor
    if $Trainer.playerClass == :ENTRENADORA #CHECK
      pkmn.exp = [pkmn.exp + exp, maxexp].min
    else
      pkmn.exp = [pkmn.exp + (exp * EXP_RATE).floor, maxexp].min
    end 
    return if pkmn.level==oldlevel
    pkmn.calcStats
    return if !LEARN_MOVES
    movelist=pkmn.getMoveList
    for z in movelist
      pkmn.pbLearnMove(z[1]) if z[0]==pkmn.level
    end
  end
end

#===============================================================================
# Hook: run PCExp.pbGivePCExp after every battle's normal EXP gain
#===============================================================================
class PokeBattle_Battle
  alias original_pbGainEXP pbGainEXP
  def pbGainEXP
    # Capture the defeated opposing battlers BEFORE calling the original
    # method, since it clears each battler's "participants" list as part of
    # its own processing.
    defeatedBattlers=[]
    if @internalbattle && !@rules["noExp"]
      for i in 0...4
        next if !@doublebattle && pbIsDoubleBattler?(i)
        next if !pbIsOpposing?(i)
        next if !@battlers[i]
        next if @battlers[i].participants.length==0
        next if !(@battlers[i].isFainted? || @battlers[i].captured)
        defeatedBattlers.push(@battlers[i])
      end
    end
    original_pbGainEXP
    PCExp.pbGivePCExp(defeatedBattlers)
  end
end