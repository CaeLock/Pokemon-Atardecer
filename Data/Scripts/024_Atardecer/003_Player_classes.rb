#===============================================================================
# Player Classes ("Trabajos") system
#-------------------------------------------------------------------------------
# Lets the player pick a "job" at the start of the game, granting benefits and
# drawbacks. The job can later be changed via an NPC (call PlayerClasses.set
# or pbChoosePlayerClass). Nothing here edits core BES scripts directly;
# everything is added via class reopening and method aliasing.
#===============================================================================
module PlayerClasses
  # Job identifiers
  CAMPEONA                = :CAMPEONA
  ARISTOCRATA             = :ARISTOCRATA
  INDECISA                = :INDECISA
  ARQUEOLOGA              = :ARQUEOLOGA
  PRO_TRAINER             = :ENTRENADORA
  MEDICO                  = :MEDICO  
  MONTARAZ                = :MONTARAZ  

  # --- Tunable balance constants ---------------------------------------------

  # Campeona - happiness gains/losses
  CAMPEONA_FIELD_HAPPINESS_GAIN = 1  # gained on defeating a trainer's Pokemon, and on switching in
  CAMPEONA_FAINT_HAPPINESS_LOSS = 3  # lost on fainting (replaces the normal -1)
  CAMPEONA_PC_LEVELUP_LOSS      = 1  # lost per level gained while boxed (see pc_exp.rb)

  # Campeona - affection table thresholds, in ascending order. Cumulative:
  # a Pokemon meeting a higher threshold also keeps every lower tier's effect.
  # Survive and self-cure can each only trigger once per battle (per Pokemon);
  # EXP, evasion, and crit are always on once the threshold is met.
  AFFECTION_EXP_MIN      = 180 # more EXP in battle
  AFFECTION_SURVIVE_MIN  = 200 # survive a fatal hit
  AFFECTION_EVADE_MIN    = 215 # evade avoidable attacks
  AFFECTION_SELFCURE_MIN = 230 # self-cure a status condition at <=20% HP
  AFFECTION_MAX          = 255 # increased crit chance; also the happiness cap

  # Campeona - affection table odds, one per tier above
  AFFECTION_EXP_BONUS       = 0.20  # extra EXP gained in battle
  AFFECTION_SURVIVE_CHANCE  = 0.25  # chance to survive a hit that would otherwise faint it
  AFFECTION_EVADE_CHANCE    = 0.05  # chance to avoid an avoidable attack outright
  AFFECTION_SELFCURE_CHANCE = 0.25  # chance per end-of-round to shake off a status condition
  AFFECTION_SELFCURE_HP_THRESHOLD = 0.30   # Self-cure additionally requires being at or below this HP
  AFFECTION_CRIT_CHANCE     = 0.125 # extra crit chance, equivalent to Super Luck's +1 stage (1/8)


  DATA = {
    CAMPEONA => {
      :name        => _INTL("Campeona"),
      :description => _INTL(""),
    },
    ARISTOCRATA => {
      :name        => _INTL("Aristócrata"),
      :description => _INTL("")
    },
    INDECISA => {
      :name        => _INTL("Indecisa"),
      :description => _INTL("")
    },
     ARQUEOLOGA => {
      :name        => _INTL("Arqueologa"),
      :description => _INTL("")
    },
    PRO_TRAINER => {
      :name        => _INTL("Entrenadora Profesional"),
      :description => _INTL("")
    },
    MEDICO => {
      :name        => _INTL("Médico"),
      :description => _INTL("")
    },
    MONTARAZ => {
      :name        => _INTL("Montaraz"),
      :description => _INTL("")
    },
  }

  module_function

  def all
    return DATA.keys
  end

  def name(job)
    return DATA[job] ? DATA[job][:name] : nil
  end

  def description(job)
    return DATA[job] ? DATA[job][:description] : nil
  end

  # Gets the player's current job (nil if none set yet)
  def current
    return nil if !$Trainer
    return $Trainer.playerClass
  end

  def current?(job)
    return current == job
  end

  # Sets the player's job. Pass nil to clear it.
  # Use this from the job-choosing event and from the job-changing NPC.
  def set(job)
    return false if job && !DATA[job]
    $Trainer.playerClass = job if $Trainer
    return true
  end
end

#===============================================================================
# Persistence: store the job on the Trainer object so it's saved with the game
#===============================================================================
class PokeBattle_Trainer
  attr_accessor :playerClass
end

#===============================================================================
# Per-battle state, stored directly on the battle/battler objects (both are
# recreated at the start of every battle, so nothing needs manual resetting):
#
# - survivedThisBattle / selfCuredThisBattle: so Campeona's affection-table
#   survive and self-cure effects can each only trigger once per battle.
#===============================================================================

class PokeBattle_Battler
  attr_accessor :survivedThisBattle, :selfCuredThisBattle
end

#===============================================================================
# Event commands
#===============================================================================
# Shows a list of jobs with their description and sets the chosen one.
# Use this both for the initial choice at the start of the game and from the
# job-changing NPC. Returns the chosen job symbol, or nil if cancelled.
def pbChoosePlayerClass
  jobs=PlayerClasses.all
  commands=jobs.map { |j| PlayerClasses.name(j) }
  commands.push(_INTL("Cancelar"))
  loop do
    chosen=Kernel.pbMessage(_INTL("¿Qué trabajo quieres elegir?"),commands,commands.length-1)
    return nil if chosen<0 || chosen==commands.length-1
    job=jobs[chosen]
    if Kernel.pbConfirmMessage(_INTL("{1}\1{2}\1¿Elegir este trabajo?",PlayerClasses.name(job),PlayerClasses.description(job)))
      PlayerClasses.set(job)
      return job
    end
  end
end

################################################################################
################################################################################
# CAMPEONA
################################################################################
################################################################################

#===============================================================================
# Happiness changes: -3 instead of -1 on fainting, and starter/max-happiness
# Pokemon can't lose happiness at all. Only affects Campeona; every other job
# (or no job) keeps BES's normal behaviour untouched.
#===============================================================================
class PokeBattle_Pokemon
  alias original_changeHappiness changeHappiness
  def changeHappiness(method)
    if !PlayerClasses.current?(PlayerClasses::CAMPEONA)
      original_changeHappiness(method)
      return
    end
    oldHappiness=@happiness
    if method=="faint"
      # Replicate the "faint" case from the original method, but with the
      # bigger Campeona-specific loss instead of the normal flat -1.
      @happiness=[0,@happiness-PlayerClasses::CAMPEONA_FAINT_HAPPINESS_LOSS].max
    else
      original_changeHappiness(method)
    end
    if @happiness<oldHappiness && (starter? || oldHappiness>=PlayerClasses::AFFECTION_MAX)
      @happiness=oldHappiness # starters and maxed-out Pokemon never lose happiness
    end
  end

  # Direct, un-cased happiness gain, used for the new Campeona-only triggers
  # below (defeating a trainer's Pokemon, switching in) which aren't part of
  # BES's own changeHappiness case list.
  def pbGainHappiness(amount)
    @happiness=[@happiness+amount,PlayerClasses::AFFECTION_MAX].min
  end
end

#===============================================================================
# +1 happiness to every player-owned battler on the field when they defeat a
# TRAINER's Pokemon (not a wild one)
#===============================================================================
class PokeBattle_Battler
  alias original_pbFaint pbFaint
  def pbFaint(showMessage=true)
    wasOpposing=@battle && !@battle.pbOwnedByPlayer?(self.index)
    isTrainerBattle=@battle && @battle.opponent
    ret=original_pbFaint(showMessage)
    if wasOpposing && isTrainerBattle && PlayerClasses.current?(PlayerClasses::CAMPEONA)
      for b in @battle.battlers
        next if !b || b.isFainted? || !@battle.pbOwnedByPlayer?(b.index)
        next if !b.pokemon
        b.pokemon.pbGainHappiness(PlayerClasses::CAMPEONA_FIELD_HAPPINESS_GAIN)
      end
    end
    return ret
  end
end

#===============================================================================
# +1 happiness when sent out to battle (covers both the initial send-out and
# mid-battle switches, since both go through pbSendOut)
#===============================================================================
class PokeBattle_Battle
  alias original_pbSendOut pbSendOut
  def pbSendOut(index,pokemon)
    original_pbSendOut(index,pokemon)
    if pbOwnedByPlayer?(index) && PlayerClasses.current?(PlayerClasses::CAMPEONA)
      pokemon.pbGainHappiness(PlayerClasses::CAMPEONA_FIELD_HAPPINESS_GAIN)
    end
  end
end

#===============================================================================
# -1 happiness per level gained in the PC (hooks into pc_exp.rb's per-Pokemon
# EXP method; works whether or not pc_exp.rb happens to be loaded)
#===============================================================================
if defined?(PCExp)
  module PCExp
    class << self
      alias original_pbGivePCExpOne pbGivePCExpOne
      def pbGivePCExpOne(pkmn,defeated)
        oldlevel=pkmn.level
        original_pbGivePCExpOne(pkmn,defeated)
        if pkmn.level>oldlevel && PlayerClasses.current?(PlayerClasses::CAMPEONA)
          levelsGained=pkmn.level-oldlevel
          pkmn.happiness=[0,pkmn.happiness-(PlayerClasses::CAMPEONA_PC_LEVELUP_LOSS*levelsGained)].max
        end
      end
    end
  end
end

#===============================================================================
# +20% EXP gained in battle (230+ happiness). Implemented by comparing this
# Pokemon's exp before/after the normal gain and topping it up afterwards,
# rather than editing the EV/Exp Share/Lucky Egg formula in pbGainExpOne
# directly. The core method's own "gained X points" message is suppressed
# for qualifying Pokemon and replaced with one showing the final total
# (base + bonus) instead of two separate messages.
#===============================================================================
class PokeBattle_Battle
  alias original_pbGainExpOne pbGainExpOne
  def pbGainExpOne(index,defeated,partic,expshare,haveexpall,showmessages=true)
    thispoke=@party1[index]
    qualifies=thispoke && PlayerClasses.current?(PlayerClasses::CAMPEONA) &&
              thispoke.happiness>=PlayerClasses::AFFECTION_EXP_MIN
    beforeExp=thispoke ? thispoke.exp : 0
    ret=original_pbGainExpOne(index,defeated,partic,expshare,haveexpall,qualifies ? false : showmessages)
    if qualifies
      gained=thispoke.exp-beforeExp
      if gained>0
        maxexp=PBExperience.pbGetMaxExperience(thispoke.growthrate)
        bonus=(gained*PlayerClasses::AFFECTION_EXP_BONUS).floor
        oldlevel=thispoke.level
        thispoke.exp=[thispoke.exp+bonus,maxexp].min if bonus>0
        total=thispoke.exp-beforeExp
        if showmessages
          isOutsider=(thispoke.trainerID!=self.pbPlayer.id ||
                     (thispoke.language!=0 && thispoke.language!=self.pbPlayer.language))
          if isOutsider
            @battle.pbDisplayPaused(_INTL("¡{1} ha ganado un total de {2} Puntos de Experiencia!",thispoke.name,total))
          else
            @battle.pbDisplayPaused(_INTL("¡{1} ha ganado {2} Puntos de Experiencia!",thispoke.name,total))
          end
        end
        if thispoke.level>oldlevel
          thispoke.calcStats
          movelist=thispoke.getMoveList
          for z in movelist
            thispoke.pbLearnMove(z[1]) if z[0]==thispoke.level
          end
        end
      end
    end
    return ret
  end
end

#===============================================================================
# Status self-cure (230+ happiness, once per battle per Pokemon). Runs as an
# extra pass right after BES's own end-of-round phase (which is where Shed
# Skin/Hydration do the same thing), so it doesn't touch that method's
# internals.
#===============================================================================
class PokeBattle_Battle
  alias original_pbEndOfRoundPhase pbEndOfRoundPhase
  def pbEndOfRoundPhase
    ret=original_pbEndOfRoundPhase
    if PlayerClasses.current?(PlayerClasses::CAMPEONA)
      for b in @battlers
        next if !b || b.isFainted? || !pbOwnedByPlayer?(b.index)
        next if !b.pokemon || b.status==0 || b.selfCuredThisBattle
        next if b.pokemon.happiness<PlayerClasses::AFFECTION_SELFCURE_MIN
        next if b.hp>(b.totalhp*PlayerClasses::AFFECTION_SELFCURE_HP_THRESHOLD)
        next if pbRandom(100)>=(PlayerClasses::AFFECTION_SELFCURE_CHANCE*100).round
        s=b.status
        b.pbCureStatus(false)
        b.selfCuredThisBattle=true
        case s
        when PBStatuses::SLEEP
          pbDisplay(_INTL("¡{1} se sobrepuso al sueño gracias a su vínculo contigo!",b.pbThis))
        when PBStatuses::POISON
          pbDisplay(_INTL("¡{1} se sobrepuso al veneno gracias a su vínculo contigo!",b.pbThis))
        when PBStatuses::BURN
          pbDisplay(_INTL("¡{1} se sobrepuso a las quemaduras gracias a su vínculo contigo!",b.pbThis))
        when PBStatuses::PARALYSIS
          pbDisplay(_INTL("¡{1} se sobrepuso a la parálisis gracias a su vínculo contigo!",b.pbThis))
        when PBStatuses::FROZEN
          pbDisplay(_INTL("¡{1} se sobrepuso al helor gracias a su vínculo contigo!",b.pbThis))
        end
      end
    end
    return ret
  end
end

#===============================================================================
# Evasion (215+ happiness, avoidable attacks only) + crit rate bonus (255)
#===============================================================================
class PokeBattle_Move
  alias original_pbAccuracyCheck pbAccuracyCheck
  def pbAccuracyCheck(attacker,opponent)
    ret=original_pbAccuracyCheck(attacker,opponent)
    if ret && accuracy>0 && PlayerClasses.current?(PlayerClasses::CAMPEONA) && opponent.pokemon &&
       @battle.pbOwnedByPlayer?(opponent.index) &&
       opponent.pokemon.happiness>=PlayerClasses::AFFECTION_EVADE_MIN
      if @battle.pbRandom(100)<(PlayerClasses::AFFECTION_EVADE_CHANCE*100).round
        @battle.pbDisplay(_INTL("¡{1} vio venir el ataque gracias a su vínculo contigo!",opponent.pokemon.name))
        return false
      end
    end
    return ret
  end

  alias original_pbIsCritical? pbIsCritical?
  def pbIsCritical?(attacker,opponent)
    ret=original_pbIsCritical?(attacker,opponent)
    if !ret && PlayerClasses.current?(PlayerClasses::CAMPEONA) && attacker.pokemon &&
       @battle.pbOwnedByPlayer?(attacker.index) &&
       attacker.pokemon.happiness>=PlayerClasses::AFFECTION_MAX
      if @battle.pbRandom(100)<(PlayerClasses::AFFECTION_CRIT_CHANCE*100).round
        @battle.pbDisplay(_INTL("¡{1} puso todo su empeño en el ataque gracias a su vínculo contigo!",attacker.pokemon.name))
        return true 
      end
    end
    return ret
  end
end

#===============================================================================
#  Survive-a-fatal-hit
# affection effect (kept here since this is where "would this hit faint the
# target" is known before the hit actually lands).
#===============================================================================
class PokeBattle_Move
  alias original_pbReduceHPDamage pbReduceHPDamage
  def pbReduceHPDamage(damage,attacker,opponent)
    if opponent
      # --- Campeona: survive a fatal hit (200+ happiness, once per battle) -----
      if PlayerClasses.current?(PlayerClasses::CAMPEONA) && attacker!=opponent &&
         @battle.pbOwnedByPlayer?(opponent.index) && opponent.pokemon &&
         !opponent.survivedThisBattle && damage>=opponent.hp
        hap=opponent.pokemon.happiness
        if hap>=PlayerClasses::AFFECTION_SURVIVE_MIN &&
           opponent.hp>1 && @battle.pbRandom(100)<(PlayerClasses::AFFECTION_SURVIVE_CHANCE*100).round
          damage=opponent.hp-1
          opponent.survivedThisBattle=true
          @battle.pbDisplay(_INTL("¡{1} sobrevivió gracias a su vínculo contigo!",opponent.pokemon.name)) #sucede antes de mostrar el daño
          PBDebug.log("[Trabajo: Campeona] #{opponent.pbThis} sobrevivió gracias a la amistad")
        end
      end
    end
    return original_pbReduceHPDamage(damage,attacker,opponent)
  end
end


################################################################################
################################################################################
# ARISTOCRATA
################################################################################
################################################################################

# Exchange money for EXP

def distribute_EXP_for_money
  #moneyString=_INTL("{1}ES",$Trainer.money) #muestra esencia actual
  #goldwindow.text=_INTL("Esencia:\n{1}",moneyString)
  
  params=ChooseNumberParams.new
  params.setRange(0,9999999)
  params.setDefaultValue(0)

  if $game_variables[30] == nil ||  $game_variables[30] == 0
    quantity_to_exchange = Kernel.pbMessageChooseNumber(_INTL("\\g¿Cuánto dinero vas a gastar para el entrenamiento?"),params)
    updated_money = $Trainer.money - quantity_to_exchange

    if $Trainer.money < quantity_to_exchange
      Kernel.pbMessage("\\gNo tienes suficiente dinero.")
      return false
    end

    if quantity_to_exchange <=0 || Input.trigger?(Input::B)
      return false 
    end

    if Kernel.pbConfirmMessage(_INTL("\\g¿Quieres gastar ${1}?\nTe quedarás con ${2}.",quantity_to_exchange, updated_money))
      exchange_money_for_exp(quantity_to_exchange)
    else
      return false
    end

  else
   exchange_money_for_exp($Trainer.money)
  end
end

def exchange_money_for_exp(quantity_to_exchange)
  $Trainer.money -= quantity_to_exchange
  exp = quantity_to_exchange
  for i in 0...$Trainer.party.length
    pokemon = $Trainer.party[i]
    maxexp=PBExperience.pbGetMaxExperience(pokemon.growthrate)
        if pokemon.exp<maxexp
          oldlevel=pokemon.level
          pokemon.exp+=exp
          if pokemon.level!=oldlevel
           ##########
           attackdiff=pokemon.attack
           defensediff=pokemon.defense
           speeddiff=pokemon.speed
           spatkdiff=pokemon.spatk
           spdefdiff=pokemon.spdef
           totalhpdiff=pokemon.totalhp
           newlevel=pokemon.level
           pokemon.changeHappiness("level up")
           pokemon.calcStats
           Kernel.pbMessage(_INTL("¡{1} ha subido al nivel {2}!",pokemon.name,pokemon.level))
           attackdiff=pokemon.attack-attackdiff
           defensediff=pokemon.defense-defensediff
           speeddiff=pokemon.speed-speeddiff
           spatkdiff=pokemon.spatk-spatkdiff
           spdefdiff=pokemon.spdef-spdefdiff
           totalhpdiff=pokemon.totalhp-totalhpdiff
           pbTopRightWindow(_INTL("PS Máx.<r>+{1}\r\nAtaque<r>+{2}\r\nDefensa<r>+{3}\r\nAt. Esp.<r>+{4}\r\nDef. Esp.<r>+{5}\r\nVelocidad<r>+{6}",
             totalhpdiff,attackdiff,defensediff,spatkdiff,spdefdiff,speeddiff))
           pbTopRightWindow(_INTL("PS Máx.<r>{1}\r\nAtaque<r>{2}\r\nDefensa<r>{3}\r\nAt. Esp.<r>{4}\r\nDef. Esp.<r>{5}\r\nVelocidad<r>{6}",
             pokemon.totalhp,pokemon.attack,pokemon.defense,pokemon.spatk,pokemon.spdef,pokemon.speed))
           movelist=pokemon.getMoveList
           for i in movelist
             if i[0]==pokemon.level          # Aprendió un movimiento nuevo
               pbLearnMove(pokemon,i[1],true)
             end
           end
           newspecies=pbCheckEvolution(pokemon)
           if newspecies>0
             pbFadeOutInWithMusic(99999){
               evo=PokemonEvolutionScene.new
               evo.pbStartScreen(pokemon,newspecies)
               evo.pbEvolution
               evo.pbEndScreen
             }
           end
           ##########
          end
       end
  end
  for x in 0...$PokemonStorage.maxBoxes
    for y in 0...$PokemonStorage.maxPokemon(x)
         next if $PokemonStorage[x,y]==nil
         next if $PokemonStorage[x,y].isEgg?
           maxexp=PBExperience.pbGetMaxExperience($PokemonStorage[x,y].growthrate)
          if $PokemonStorage[x,y].exp<maxexp
             oldlevel=$PokemonStorage[x,y].level
               exp=esencia
               $PokemonStorage[x,y].exp+=(exp*0.3).floor #cambiar número para modificar
              if $PokemonStorage[x,y].level!=oldlevel
                 $PokemonStorage[x,y].calcStats
                   movelist= $PokemonStorage[x,y].getMoveList
                 for z in movelist
                   $PokemonStorage[x,y].pbLearnMove(z[1]) if z[0]==$PokemonStorage[x,y].level       # Learned a new move
                 end
              end
          end
    end
  end
   $game_map.update
   Kernel.pbMessage("¡El entrenamiento ha dado sus frutos!") 
end

#===============================================================================
# Money Stats
#-------------------------------------------------------------------------------
# The player's own Pokemon (party and PC boxes) get a stat multiplier based
# on how much money the player is carrying. Doesn't affect HP.
# Capped at a maximum multiplier of x2.5
# (reached at 2.500.000 money and beyond).
#===============================================================================
module MoneyStats
  MONEY_PER_STEP  = 10000 # money needed for each +BONUS_PER_STEP
  BONUS_PER_STEP  = 0.01
  MAX_MULTIPLIER  = 2.5

  module_function

  def multiplier
    return 1.0 if !$Trainer
    steps=($Trainer.money/MONEY_PER_STEP).floor
    mult=1.0+(steps*BONUS_PER_STEP)
    return [mult,MAX_MULTIPLIER].min
  end
end

#===============================================================================
# Ownership check: is this exact Pokemon object one of the player's own team
# members (party or PC box)? Deliberately not based on trainerID, since that
# would wrongly exclude traded-in Pokemon (foreign OT) and could wrongly
# include a freshly-generated wild Pokemon if it already carries the
# player's ID before being caught.
#===============================================================================
class PokeBattle_Pokemon
  def belongsToPlayer?
    return false if !$Trainer
    return true if $Trainer.party.any? { |p| p.equal?(self) }
    if $PokemonStorage
      for box in 0...$PokemonStorage.maxBoxes
        for slot in 0...$PokemonStorage.maxPokemon(box)
          return true if $PokemonStorage[box,slot].equal?(self)
        end
      end
    end
    return false
  end

  alias original_calcStats calcStats
  def calcStats
    original_calcStats
    return if !belongsToPlayer?
    mult=MoneyStats.multiplier
    return if mult==1.0
    @attack =(@attack*mult).round
    @defense=(@defense*mult).round
    @spatk  =(@spatk*mult).round
    @spdef  =(@spdef*mult).round
    @speed  =(@speed*mult).round
  end
end

################################################################################
################################################################################
# ARQUEOLOGA
################################################################################
################################################################################

class Archaeologist
  ARCHAEOLOGY_ITEM = {
    :RELICCOPPER => :RELICCOPPER_ARCHAEOLOGY,
    :RELICSILVER => :RELICSILVER_ARCHAEOLOGY,
    :RELICGOLD   => :RELICGOLD_ARCHAEOLOGY,
    :RELICCROWN  => :RELICCROWN_ARCHAEOLOGY,
    :RELICVASE   => :RELICVASE_ARCHAEOLOGY,
    :RELICSTATUE => :RELICSTATUE_ARCHAEOLOGY,
    :RELICBAND   => :RELICBAND_ARCHAEOLOGY
  }

  ARCHAEOLOGY_POCKETSIZE = {
     1   => 5, # "Objetos"
     2   => 5, # "Medicinas"
     3   => 5, # "Poké Balls" 
     4   => 5, # "MTs / MOs" 
     5   => 5, # "Bayas"       
     6   => 5, #"Cristales Z"
     7   => 5, # "Obj. Batallas" 
     8   => 5  #"Obj. Claves"
  }


  def self.archaeology_item(item)
    if item.is_a?(Integer) #in the case of being an ID, transforms to sym
      item = getConstantName(PBItems, item).to_sym
    end
    ARCHAEOLOGY_ITEM.fetch(item, item)
  end

  def self.return_archaeology_size(pocket)
    return ARCHAEOLOGY_POCKETSIZE[pocket]
  end
  
end

def archaeology_exchange(item)
  Archaeologist.archaeology_item(item)
end


################################################################################
################################################################################
# PRO TRAINER
################################################################################
################################################################################

#===============================================================================
# Can't revive a fainted Pokemon
#===============================================================================
class PokeBattle_Pokemon
  alias original_hp= hp=
  def hp=(value)
    if @hp==0 && value>0 && belongsToPlayer? &&
       PlayerClasses.current?(PlayerClasses::PRO_TRAINER)
      return
    end
    self.original_hp=(value)
  end

  alias original_healHP healHP
  def healHP
    if @hp==0 && belongsToPlayer? &&
       PlayerClasses.current?(PlayerClasses::PRO_TRAINER)
      return
    end
    original_healHP
  end
end

#===============================================================================
# Don't let Revive/Max Revive get consumed (or show a misleading "recovered
# HP" message) on a Pokemon that's permanently fainted for this job
#===============================================================================
def pbEntrenadoraBlocksRevive?(item,pokemon)
  return false if !PlayerClasses.current?(PlayerClasses::PRO_TRAINER)
  return false if !pokemon || pokemon.hp>0
  return false if !pokemon.respond_to?(:belongsToPlayer?) || !pokemon.belongsToPlayer?
  reviveIDs=[getID(PBItems,:REVIVE),getID(PBItems,:MAXREVIVE),getID(PBItems,:REVIVALHERB)]
  return reviveIDs.include?(item)
end

module ItemHandlers
  class << self
    alias original_triggerUseOnPokemon triggerUseOnPokemon
    def triggerUseOnPokemon(item,pokemon,scene)
      if pbEntrenadoraBlocksRevive?(item,pokemon)
        scene.pbDisplay(_INTL("No tendrá ningún efecto."))
        return false
      end
      return original_triggerUseOnPokemon(item,pokemon,scene)
    end

    alias original_triggerBattleUseOnPokemon triggerBattleUseOnPokemon
    def triggerBattleUseOnPokemon(item,pokemon,battler,scene)
      if pbEntrenadoraBlocksRevive?(item,pokemon)
        scene.pbDisplay(_INTL("No tendrá ningún efecto."))
        return false
      end
      return original_triggerBattleUseOnPokemon(item,pokemon,battler,scene)
    end
  end
end

#===============================================================================
# Starter fainting forces an immediate loss
#-------------------------------------------------------------------------------
# Reuses the battle's own @decision flag (0=undecided,1=win,2=loss,3=escaped,
# 4=caught) instead of duplicating any end-of-battle logic. Setting it here
# lets the battle's existing turn loop notice and wrap up normally, the same
# way it already does for a full party wipe.
#===============================================================================
class PokeBattle_Battler
  alias entrenadora_hardcore_pbFaint pbFaint
  def pbFaint(showMessage=true)
    alreadyFainted=@fainted
    ret=entrenadora_hardcore_pbFaint(showMessage)
    if !alreadyFainted && @battle && @pokemon && @battle.decision==0 &&
       @battle.pbOwnedByPlayer?(self.index) &&
       @pokemon.respond_to?(:starter?) && @pokemon.starter? &&
       PlayerClasses.current?(PlayerClasses::PRO_TRAINER)
      @battle.decision=2
    end
    return ret
  end
end

#===============================================================================
# Game Over sequence, triggered once control is back in the field
#-------------------------------------------------------------------------------
# Uses $game_temp.gameover, the same flag RPG Maker XP's own "Game Over"
# event command sets -- it shows the engine's native Game Over screen/jingle
# (configured in the Database) and returns to the title screen on its own.
# If you'd rather route this through a common event instead (for a custom
# screen), swap the line below for: pbCommonEvent(N)
#===============================================================================
module EntrenadoraGameOver
  module_function

  def trigger
    $game_temp.gameover=true if $game_temp
  end
end

alias original_pbAfterBattle pbAfterBattle
def pbAfterBattle(decision,canlose)
  original_pbAfterBattle(decision,canlose)
  if decision==2 && PlayerClasses.current?(PlayerClasses::PRO_TRAINER)
    EntrenadoraGameOver.trigger
  end
end

################################################################################
################################################################################
# MEDICO
################################################################################
################################################################################
#===============================================================================
# The Medico job follows a Hippocratic Oath: it refuses to use any move that
# requires sacrificing (fainting) its own Pokemon. Which moves count is an
# editable blacklist below, so new ones can be added or removed freely.
#-------------------------------------------------------------------------------
# Implemented by aliasing pbCanChooseMove? (the same hook BES itself uses for
# Taunt/Torment/Disable/Imprison/etc), so nothing in the core battle scripts
# needs to be touched and every other reason to block a move keeps working.
#===============================================================================
module PlayerClasses
  # Moves blocked by the Medico's Hippocratic Oath (self-destruct moves,
  # Memento-style moves, Healing Wish-style moves, etc). Add or remove move
  # ID symbols here to change what's blocked.
  MEDICO_FORBIDDEN_MOVES = [
    :SELFDESTRUCT,
    :EXPLOSION,
    :MISTYEXPLOSION,
    :MEMENTO,
    :FINALGAMBIT,
    :HEALINGWISH,
    :LUNARDANCE,
    :MINDBLOWN,
    :STEELBEAM,
    :CHLOROBLAST
  ]

  module_function

  # Resolves MEDICO_FORBIDDEN_MOVES (symbols) into their actual move IDs and
  # caches the result, since PBMoves has to be loaded for getID to work.
  def medicoForbiddenMoveIDs
    @medicoForbiddenMoveIDs ||= MEDICO_FORBIDDEN_MOVES.map { |m| getID(PBMoves,m) }
    return @medicoForbiddenMoveIDs
  end

  def medicoForbidsMove?(moveID)
    return medicoForbiddenMoveIDs.include?(moveID)
  end
end

class PokeBattle_Battle
  alias medico_pbCanChooseMove pbCanChooseMove?
  def pbCanChooseMove?(idxPokemon,idxMove,showMessages,sleeptalk=false)
    ret=medico_pbCanChooseMove(idxPokemon,idxMove,showMessages,sleeptalk)
    return ret if !ret
    thispkmn=@battlers[idxPokemon]
    thismove=thispkmn.moves[idxMove]
    if thismove && pbOwnedByPlayer?(idxPokemon) &&
       PlayerClasses.current?(PlayerClasses::MEDICO) &&
       PlayerClasses.medicoForbidsMove?(thismove.id)
      if showMessages
        pbDisplayPaused(_INTL("¡No puedes usar ese movimiento! ¡Va contra el juramento hipocrático!"))
      end
      return false
    end
    return ret
  end
end