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
  SUPERMODELO             = :SUPERMODELO  
  MEDIUM                  = :MEDIUM  

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
    SUPERMODELO => {
      :name        => _INTL("Supermodelo"),
      :description => _INTL("")
    },
     MEDIUM => {
      :name        => _INTL("Medium"),
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
  alias campeona_changeHappiness changeHappiness
  def changeHappiness(method)
    if !PlayerClasses.current?(PlayerClasses::CAMPEONA)
      campeona_changeHappiness(method)
      return
    end
    oldHappiness=@happiness
    if method=="faint"
      # Replicate the "faint" case from the original method, but with the
      # bigger Campeona-specific loss instead of the normal flat -1.
      @happiness=[0,@happiness-PlayerClasses::CAMPEONA_FAINT_HAPPINESS_LOSS].max
    else
      campeona_changeHappiness(method)
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
  alias campeona_pbFaint pbFaint
  def pbFaint(showMessage=true)
    wasOpposing=@battle && !@battle.pbOwnedByPlayer?(self.index)
    isTrainerBattle=@battle && @battle.opponent
    ret=campeona_pbFaint(showMessage)
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
  alias campeona_pbSendOut pbSendOut
  def pbSendOut(index,pokemon)
    campeona_pbSendOut(index,pokemon)
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
      alias campeona_pbGivePCExpOne pbGivePCExpOne
      def pbGivePCExpOne(pkmn,defeated)
        oldlevel=pkmn.level
        campeona_pbGivePCExpOne(pkmn,defeated)
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
  alias campeona_pbGainExpOne pbGainExpOne
  def pbGainExpOne(index,defeated,partic,expshare,haveexpall,showmessages=true)
    thispoke=@party1[index]
    qualifies=thispoke && PlayerClasses.current?(PlayerClasses::CAMPEONA) &&
              thispoke.happiness>=PlayerClasses::AFFECTION_EXP_MIN
    beforeExp=thispoke ? thispoke.exp : 0
    ret=campeona_pbGainExpOne(index,defeated,partic,expshare,haveexpall,qualifies ? false : showmessages)
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
  alias campeona_pbEndOfRoundPhase pbEndOfRoundPhase
  def pbEndOfRoundPhase
    ret=campeona_pbEndOfRoundPhase
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
  alias campeona_pbAccuracyCheck pbAccuracyCheck
  def pbAccuracyCheck(attacker,opponent)
    ret=campeona_pbAccuracyCheck(attacker,opponent)
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

  alias campeona_pbIsCritical? pbIsCritical?
  def pbIsCritical?(attacker,opponent)
    ret=campeona_pbIsCritical?(attacker,opponent)
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
  alias campeona_pbReduceHPDamage pbReduceHPDamage
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
    return campeona_pbReduceHPDamage(damage,attacker,opponent)
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

  alias aristocrata_calcStats calcStats
  def calcStats
    aristocrata_calcStats
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
  alias protrainer_hp= hp=
  def hp=(value)
    if @hp==0 && value>0 && belongsToPlayer? &&
       PlayerClasses.current?(PlayerClasses::PRO_TRAINER)
      return
    end
    self.protrainer_hp=(value)
  end

  alias protrainer_healHP healHP
  def healHP
    if @hp==0 && belongsToPlayer? &&
       PlayerClasses.current?(PlayerClasses::PRO_TRAINER)
      return
    end
    protrainer_healHP
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
    alias protrainer_triggerUseOnPokemon triggerUseOnPokemon
    def triggerUseOnPokemon(item,pokemon,scene)
      if pbEntrenadoraBlocksRevive?(item,pokemon)
        scene.pbDisplay(_INTL("No tendrá ningún efecto."))
        return false
      end
      return protrainer_triggerUseOnPokemon(item,pokemon,scene)
    end

    alias protrainer_triggerBattleUseOnPokemon triggerBattleUseOnPokemon
    def triggerBattleUseOnPokemon(item,pokemon,battler,scene)
      if pbEntrenadoraBlocksRevive?(item,pokemon)
        scene.pbDisplay(_INTL("No tendrá ningún efecto."))
        return false
      end
      return protrainer_triggerBattleUseOnPokemon(item,pokemon,battler,scene)
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

alias protrainer_pbAfterBattle pbAfterBattle
def pbAfterBattle(decision,canlose)
  protrainer_pbAfterBattle(decision,canlose)
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

#===============================================================================
#EXP gain is skipped entirely for wild battles (party AND
# PC, since this wraps the same pbGainEXP that both party gain and
# pc_exp.rb's PC gain funnel through). Trainer battles are unaffected.
#
# Switch 39: if ON during a wild battle, EXP is granted as normal. Use this
# to flag scripted "boss" encounters that are technically wild battles but
# should still reward EXP -- turn it on right before the encounter and off
# right after.
#===============================================================================
MEDICO_NO_WILD_EXP_SWITCH = 39

class PokeBattle_Battle
  alias medico_pbGainEXP pbGainEXP
  def pbGainEXP
    if PlayerClasses.current?(PlayerClasses::MEDICO) && !@opponent &&
       !$game_switches[MEDICO_NO_WILD_EXP_SWITCH]
      return
    end
    medico_pbGainEXP
  end
end

################################################################################
################################################################################
# MONTARAZ
################################################################################
################################################################################
#===============================================================================
# The Montaraz job doesn't trust artificial medicine: it can't use consumable
# items such as potions, ethers, or vitamins, either from the field bag or the
# battle bag. Which items count is an editable blacklist below, so new ones
# can be added or removed freely.
#-------------------------------------------------------------------------------
# Implemented by aliasing ItemHandlers.triggerUseOnPokemon (field use on a
# Pokemon) and triggerBattleUseOnPokemon (battle use on a Pokemon) -- the same
# hooks Entrenadora's Revive block already uses -- so nothing in the core
# item scripts needs to be touched. A dedicated alias name is used (instead of
# reusing "original_...") to avoid clashing with Entrenadora's own aliases on
# these same methods.
#===============================================================================
module PlayerClasses
  # Items blocked for the Montaraz job (potions, ethers/elixirs, vitamins,
  # and status-healing sprays). Add or remove item ID symbols here to change
  # what's blocked.
  MONTARAZ_FORBIDDEN_ITEMS = [
    :POTION,:SUPERPOTION,:HYPERPOTION,:MAXPOTION,:FULLRESTORE,
    :ETHER,:MAXETHER,:ELIXIR,:MAXELIXIR,
    :HPUP,:PROTEIN,:IRON,:CALCIUM,:ZINC,:CARBOS,:PPUP,:PPMAX,
    :FULLHEAL,:ANTIDOTE,:PARLYZHEAL,:BURNHEAL,:ICEHEAL,:AWAKENING
  ]

  module_function

  # Resolves MONTARAZ_FORBIDDEN_ITEMS (symbols) into their actual item IDs
  # and caches the result, since PBItems has to be loaded for getID to work.
  def montarazForbiddenItemIDs
    @montarazForbiddenItemIDs ||= MONTARAZ_FORBIDDEN_ITEMS.map { |i| getID(PBItems,i) }
    return @montarazForbiddenItemIDs
  end

  def montarazForbidsItem?(itemID)
    return montarazForbiddenItemIDs.include?(itemID)
  end
end

#===============================================================================
# Shared check: does the Montaraz job block using this item on this Pokemon?
# Only blocks the current player's own job, and only on the player's own
# Pokemon (so it never affects NPC trainers).
#===============================================================================
def pbMontarazBlocksItem?(item,pokemon)
  return false if !PlayerClasses.current?(PlayerClasses::MONTARAZ)
  return false if !pokemon || !pokemon.respond_to?(:belongsToPlayer?) || !pokemon.belongsToPlayer?
  return PlayerClasses.montarazForbidsItem?(item)
end

module ItemHandlers
  class << self
    alias montaraz_triggerUseOnPokemon triggerUseOnPokemon
    def triggerUseOnPokemon(item,pokemon,scene)
      if pbMontarazBlocksItem?(item,pokemon)
        scene.pbDisplay(_INTL("¡Es mejor no usar algo tan artificial!"))
        return false
      end
      return montaraz_triggerUseOnPokemon(item,pokemon,scene)
    end

    alias montaraz_triggerBattleUseOnPokemon triggerBattleUseOnPokemon
    def triggerBattleUseOnPokemon(item,pokemon,battler,scene)
      if pbMontarazBlocksItem?(item,pokemon)
        scene.pbDisplay(_INTL("¡Es mejor no usar algo tan artificial!"))
        return false
      end
      return montaraz_triggerBattleUseOnPokemon(item,pokemon,battler,scene)
    end
  end
end

################################################################################
################################################################################
# SUPERMODELO
################################################################################
################################################################################
#===============================================================================
# The Supermodelo job tracks a shared, in-battle-only "Style Score" (a single
# counter per battle, shared by all of the player's own Pokemon -- not saved
# between battles). Various things that happen during a round add or remove
# points; at the end of the round, the net score for that round decides a
# tier of effects that stays active for the whole of the FOLLOWING round,
# then gets recalculated again from a fresh 0.
#
# Tiers are cumulative: reaching tier 3 keeps tier 1 and tier 2's effects too
# (and so on). Negative tiers scale the same way in reverse (-3 is worse
# than -1).
#
# Permanent downside (always on while this job is active, regardless of
# tier): non-critical, non-super-effective damage dealt by the player's own
# Pokemon is halved.
#-------------------------------------------------------------------------------
# Nothing in the core battle scripts is edited -- this file only reopens
# classes and aliases methods, same approach used by every other job.
#===============================================================================

module PlayerClasses
  SUPERMODELO = :SUPERMODELO
end

PlayerClasses::DATA[PlayerClasses::SUPERMODELO] = {
  :name        => _INTL("Supermodelo"),
  :description => _INTL("Gana Puntos de Estilo luciéndose en combate (OHKOs, golpes críticos, ataques superefectivos...) y piérdelos por errores. Sus efectos varían según el marcador, pero sus ataques normales pegan flojo.")
}

module SupermodelStyle
  WEATHER_MOVES = {
    PBWeather::SUNNYDAY  => [:SOLARBEAM,:SOLARBLADE,:MORNINGSUN,:SYNTHESIS,:WEATHERBALL],
    PBWeather::RAINDANCE => [:THUNDER,:HURRICANE,:WEATHERBALL],
    PBWeather::HAIL      => [:BLIZZARD,:WEATHERBALL,:AURORAVEIL],
    PBWeather::SANDSTORM => [:WEATHERBALL]
  }

  TERRAIN_MOVES = {
    PBEffects::ElectricTerrain => [:RISINGVOLTAGE,:TERRAINPULSE],
    PBEffects::GrassyTerrain   => [:GRASSYGLIDE,:TERRAINPULSE],
    PBEffects::PsychicTerrain  => [:EXPANDINGFORCE,:TERRAINPULSE],
    PBEffects::MistyTerrain    => [:MISTYEXPLOSION,:TERRAINPULSE]
  }

  SEMI_INVULNERABLE_COUNTERS = {
    :DIG  => [:EARTHQUAKE,:MAGNITUDE],
    :DIVE => [:SURF,:WHIRLPOOL],
    :FLY  => [:GUST,:TWISTER,:THUNDER,:HURRICANE,:SKYUPPERCUT,:SMACKDOWN,:THOUSANDARROWS]
  }

  DOUBLE_POWER_MOVES = [
    :HEX,:VENOSHOCK,:AVALANCHE,:REVENGE,:ASSURANCE,:BRINE,:FACADE,
    :ACROBATICS,:RETALIATE,:LASHOUT,:FISHIOUSREND,:BOLTBEAK
  ]

  module_function

  def moveID(sym)
    @moveIDCache ||= {}
    @moveIDCache[sym] ||= getID(PBMoves,sym)
    return @moveIDCache[sym]
  end

  def resolvedIDList(list)
    @resolvedIDLists ||= {}
    @resolvedIDLists[list] ||= list.map { |s| getID(PBMoves,s) }
    return @resolvedIDLists[list]
  end

  def idListIncludes?(list,id)
    return false if !list
    return resolvedIDList(list).include?(id)
  end

  def active?(battle)
    return PlayerClasses.current?(PlayerClasses::SUPERMODELO)
  end

  def gainPoint(battle,reason="")
    return if !active?(battle)
    battle.supermodelStyleScore += 1
    PBDebug.log("[Supermodelo] +1 punto de estilo (#{reason}), total: #{battle.supermodelStyleScore}")
  end

  def losePoint(battle,reason="")
    return if !active?(battle)
    battle.supermodelStyleScore -= 1
    PBDebug.log("[Supermodelo] -1 punto de estilo (#{reason}), total: #{battle.supermodelStyleScore}")
  end

  def tierForScore(score)
    p score+3
    return -3 if score <= -3
    return 5 if score >= 5
    return score+3
  end

  # Called once per end of round. Reverts the previous round's stat penalty
  # (if any) with a single combined message/animation per Pokemon, works out
  # the new tier from this round's score, applies its stat penalty (if any)
  # -- again with a single combined message/animation per Pokemon -- and
  # resets the score for the new round.
  #
  # Pending penalties are tracked per Pokemon (object identity), not per
  # battler slot/index: if the Pokemon that had the pending penalty fainted
  # or was switched out before the revert, its entry is simply dropped
  # instead of being wrongly applied to whichever different Pokemon now
  # occupies that slot.
  def pbApplyEndOfRound(battle)
    return if !active?(battle)
    pending = battle.supermodelPendingStatDelta
    if !pending.empty?
      pending.each_value do |entry|
        battler = battle.battlers[entry[:index]]
        next if !battler || battler.isFainted?
        next if !battler.pokemon || !battler.pokemon.equal?(entry[:pokemon])
        changed = false
        entry[:deltas].each do |stat,delta|
          next if delta==0
          battler.pbIncreaseStatBasic(stat,-delta,battler,true,true)
          changed = true
        end
        if changed
          battle.pbCommonAnimation("StatUp",battler,nil)
          battle.pbDisplay(_INTL("¡La mala impresión ha desaparecido! Las estadísticas de {1} han vuelto a la normalidad.",battler.pbThis))
        end
      end
      battle.supermodelPendingStatDelta = {}
    end
    tier = tierForScore(battle.supermodelStyleScore)
    battle.supermodelStyleTier = tier
    if tier<0
      amount = -tier
      newPending = {}
      statList = [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPATK,PBStats::SPDEF,PBStats::SPEED]
      msgByAmount = {
        1 => "¡Has creado una mala impresión en la ronda anterior! Las estadísticas de {1} han disminuido.",
        2 => "¡Has creado una mala impresión en la ronda anterior! Las estadísticas de {1} han disminuido bastante.",
        3 => "¡Has creado una mala impresión en la ronda anterior! Las estadísticas de {1} han disminuido drásticamente."
      }
      (0...4).each do |idx|
        battler = battle.battlers[idx]
        next if !battler || battler.isFainted? || !battle.pbOwnedByPlayer?(idx)
        deltas = {}
        changed = false
        statList.each do |stat|
          before = battler.stages[stat]
          battler.pbReduceStatBasic(stat,amount,battler,true,true)
          deltas[stat] = battler.stages[stat]-before
          changed = true if deltas[stat]!=0
        end
        newPending[idx] = {:index => idx, :pokemon => battler.pokemon, :deltas => deltas}
        if changed
          battle.pbCommonAnimation("StatDown",battler,nil)
          battle.pbDisplay(_INTL(msgByAmount[[amount,3].min],battler.pbThis))
        end
      end
      battle.supermodelPendingStatDelta = newPending
    end
    battle.supermodelStyleScore = 0
  end

  def pbConditionalDoublePowerMove?(move,user,target)
    id = move.id
    case id
    when moveID(:HEX)
      return target.status!=0
    when moveID(:VENOSHOCK)
      return target.status==PBStatuses::POISON
    when moveID(:AVALANCHE),moveID(:REVENGE)
      return user.tookDamage
    when moveID(:ASSURANCE)
      return target.tookDamage
    when moveID(:BRINE)
      return target.hp<=(target.totalhp/2.0)
    when moveID(:FACADE)
      return user.status!=0
    when moveID(:ACROBATICS)
      return user.item==0
    when moveID(:RETALIATE)
      return user.pbOwnSide.effects[PBEffects::LastRoundFainted]==user.battle.turncount-1
    when moveID(:LASHOUT)
      return user.effects[PBEffects::LashOut]
    when moveID(:FISHIOUSREND),moveID(:BOLTBEAK)
      return !target.hasMovedThisRound?
    end
    return false
  end

  # Weather/terrain move match, checked once per move use via the
  # pbUseMove hook below -- this covers self/side-target moves like Aurora
  # Veil, Synthesis or Morning Sun, which never reach
  # pbEffectsOnDealingDamage since they don't deal damage to a target.
  def pbWeatherTerrainMoveMatch?(move,battle)
    list = WEATHER_MOVES[battle.pbWeather]
    return true if idListIncludes?(list,move.id)
    TERRAIN_MOVES.each do |effect,moves|
      next if battle.field.effects[effect]<=0
      return true if idListIncludes?(moves,move.id)
    end
    return false
  end

  def pbCounterSemiInvulnerable?(move,target)
    chargedMove = target.effects[PBEffects::TwoTurnAttack]
    return false if !chargedMove || chargedMove==0
    SEMI_INVULNERABLE_COUNTERS.each do |chargingMove,counters|
      next if chargedMove!=moveID(chargingMove)
      return idListIncludes?(counters,move.id)
    end
    return false
  end

  # Called once per move use (see the pbUseMove hook below, which is the
  # only point common to every kind of move -- damaging, status, self or
  # side-target). Not gated on whether the move's own effect actually went
  # through (e.g. Aurora Veil failing for being already active): for
  # weather/terrain moves the wrong-weather case is already excluded by the
  # move/weather table itself, and rewarding "using the right move for the
  # conditions" doesn't need the hit itself to land.
  def pbCheckMoveUseTriggers(move,user)
    battle = user.battle
    return if !active?(battle)
    return if !battle.pbOwnedByPlayer?(user.index)
    gainPoint(battle,"movimiento de clima/terreno") if pbWeatherTerrainMoveMatch?(move,battle)
  end

  # Called after damage (if any) has been dealt to a target.
  def pbCheckHitTriggers(move,user,target,damage)
    battle = user.battle
    return if !active?(battle)
    return if !battle.pbOwnedByPlayer?(user.index)
    isFoe = !battle.pbOwnedByPlayer?(target.index)
    if isFoe
      gainPoint(battle,"golpe crítico") if target.damagestate.critical
      gainPoint(battle,"ataque superefectivo") if target.damagestate.typemod>8
      gainPoint(battle,"movimiento potenciado por condición") if pbConditionalDoublePowerMove?(move,user,target)
      gainPoint(battle,"golpe a través de Cava/Buceo/Vuelo") if pbCounterSemiInvulnerable?(move,target)
      if target.isFainted? && damage>0 && target.level>=user.level
        if (target.hp+damage)>=target.totalhp
          gainPoint(battle,"OHKO to adversary with more or equal level than you")
        elsif (target.level-user.level)>=5
          gainPoint(battle,"defeated with at least 5 less levels")
        end
      end
      if damage>0
        statList = [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPATK,PBStats::SPDEF,PBStats::SPEED,PBStats::EVASION,PBStats::ACCURACY]
        if statList.any? { |s| user.stages[s]>=3 }
          gainPoint(battle,"golpe con estadística potenciada")
        end
      end
      # Note: type-immunity ("ataque sin efecto") is handled in the
      # pbSuccessCheck alias below, not here -- see the comment there.
    else
      losePoint(battle,"golpeaste a tu aliado") if target.index!=user.index
    end
  end
end

class PokeBattle_Battle
  attr_writer :supermodelStyleScore
  attr_writer :supermodelStyleTier
  attr_writer :supermodelPendingStatDelta

  def supermodelStyleScore
    @supermodelStyleScore = 0 if !@supermodelStyleScore
    return @supermodelStyleScore
  end

  def supermodelStyleTier
    @supermodelStyleTier = 0 if !@supermodelStyleTier
    return @supermodelStyleTier
  end

  def supermodelPendingStatDelta
    @supermodelPendingStatDelta = {} if !@supermodelPendingStatDelta
    return @supermodelPendingStatDelta
  end

  alias supermodelo_pbEndOfRoundPhase pbEndOfRoundPhase
  def pbEndOfRoundPhase
    supermodelo_pbEndOfRoundPhase
    SupermodelStyle.pbApplyEndOfRound(self)
  end
end

class PokeBattle_Battler
  # Runs exactly once for every move use, regardless of whether it has a
  # discrete target (damaging/status moves against a Pokemon) or not
  # (self/side/field moves like Aurora Veil, which take a completely
  # different code path inside pbUseMove and never reach
  # pbProcessMoveAgainstTarget at all).
  alias supermodelo_pbUseMove pbUseMove
  def pbUseMove(choice,specialusage=false)
    ret = supermodelo_pbUseMove(choice,specialusage)
    thismove = choice[2]
    SupermodelStyle.pbCheckMoveUseTriggers(thismove,self) if thismove && thismove.id!=0
    return ret
  end

  alias supermodelo_pbEffectsOnDealingDamage pbEffectsOnDealingDamage
  def pbEffectsOnDealingDamage(move,user,target,damage)
    supermodelo_pbEffectsOnDealingDamage(move,user,target,damage)
    SupermodelStyle.pbCheckHitTriggers(move,user,target,damage)
  end

  alias supermodelo_pbFaint pbFaint
  def pbFaint(showMessage=true)
    shouldScore = SupermodelStyle.active?(@battle) && @battle.pbOwnedByPlayer?(index) &&
                  self.isFainted? && !@fainted
    SupermodelStyle.losePoint(@battle,"Pokémon debilitado") if shouldScore
    supermodelo_pbFaint(showMessage)
  end

  alias supermodelo_pbConsumeItem pbConsumeItem
  def pbConsumeItem(recycle=true,pickup=true)
    shouldScore = SupermodelStyle.active?(@battle) && @battle.pbOwnedByPlayer?(index)
    supermodelo_pbConsumeItem(recycle,pickup)
    SupermodelStyle.gainPoint(@battle,"objeto equipado activado") if shouldScore
  end

  # Tier 5 ("ignora las habilidades del rival") is implemented by treating
  # the player's own Pokemon as if it had Mold Breaker while that tier is
  # active -- the same mechanism the game already uses for that ability.
  # This only bypasses ignorable ABILITIES (what Mold Breaker has always
  # done); it does not touch stat stages, which are handled separately.
  alias supermodelo_hasMoldBreaker hasMoldBreaker
  def hasMoldBreaker
    if SupermodelStyle.active?(@battle) && @battle.pbOwnedByPlayer?(index) &&
       @battle.supermodelStyleTier>=5
      return true
    end
    return supermodelo_hasMoldBreaker
  end

  # Tier 5 also breaks through Protect/Detect and similar move-blocking
  # effects (Spiky Shield, Mat Block, King's Shield, Baneful Bunker, etc),
  # the same way the move Feint does -- by temporarily setting
  # ProtectNegation on the target for the duration of this check. It's
  # restored to its prior value afterwards.
  #
  # This is also the only reliable place to detect real type immunity
  # ("no afecta al rival"): pbSuccessCheck itself checks
  # thismove.pbTypeModifier(...)==0 and returns false right here, which
  # means pbEffect/pbEffectsOnDealingDamage never run at all for a truly
  # immune hit -- damagestate.typemod defaults to 0 on reset regardless of
  # whether the move actually got that far, so checking it from
  # pbEffectsOnDealingDamage can never distinguish a real immunity from a
  # move that simply never reached the damage step.
  alias supermodelo_pbSuccessCheck pbSuccessCheck
  def pbSuccessCheck(thismove,user,target,turneffects,accuracy=true)
    if user && SupermodelStyle.active?(@battle) && @battle.pbOwnedByPlayer?(user.index) &&
       !@battle.pbOwnedByPlayer?(target.index) && thismove.pbIsDamaging?
      type = thismove.pbType(thismove.type,user,target)
      typemod = thismove.pbTypeModifier(type,user,target)
      SupermodelStyle.losePoint(@battle,"ataque sin efecto") if typemod==0
    end
    breaksProtect = user && SupermodelStyle.active?(@battle) &&
                    @battle.pbOwnedByPlayer?(user.index) && @battle.supermodelStyleTier>=5
    if breaksProtect
      wasNegated = self.effects[PBEffects::ProtectNegation]
      self.effects[PBEffects::ProtectNegation] = true
      ret = supermodelo_pbSuccessCheck(thismove,user,target,turneffects,accuracy)
      self.effects[PBEffects::ProtectNegation] = wasNegated
      return ret
    end
    return supermodelo_pbSuccessCheck(thismove,user,target,turneffects,accuracy)
  end
end

class PokeBattle_Move
  STAGE_MUL = [10,10,10,10,10,10,10,15,20,25,30,35,40]
  STAGE_DIV = [40,35,30,25,20,15,10,10,10,10,10,10,10]

  # Applies the permanent damage penalty (non-crit, non-super-effective
  # damage halved) and tier 1+'s crit/super-effective boost.
  alias supermodelo_pbCalcDamage pbCalcDamage
  def pbCalcDamage(attacker,opponent,options=0)
    damage = supermodelo_pbCalcDamage(attacker,opponent,options)
    return damage if damage==0
    battle = attacker.battle
    return damage if !SupermodelStyle.active?(battle) || !battle.pbOwnedByPlayer?(attacker.index)
    tier = battle.supermodelStyleTier
    isCrit = opponent.damagestate.critical
    isSuperEffective = opponent.damagestate.typemod>8
    if isCrit || isSuperEffective
      damage = (damage*1.25).round if tier>=1
    else
      damage = (damage*0.5).round
    end
    damage = 1 if damage<1
    opponent.damagestate.calcdamage = damage
    return damage
  end

  # Tier 2+: +50% accuracy. Done by temporarily boosting the move's own
  # accuracy value rather than duplicating the whole accuracy formula.
  alias supermodelo_pbAccuracyCheck pbAccuracyCheck
  def pbAccuracyCheck(attacker,opponent)
    battle = attacker.battle
    if SupermodelStyle.active?(battle) && battle.pbOwnedByPlayer?(attacker.index) &&
       battle.supermodelStyleTier>=2 && @accuracy>0
      oldAccuracy = @accuracy
      @accuracy = (@accuracy*1.5).round
      ret = supermodelo_pbAccuracyCheck(attacker,opponent)
      @accuracy = oldAccuracy
      return ret
    end
    return supermodelo_pbAccuracyCheck(attacker,opponent)
  end

  # Tier 3+: +1 priority.
  alias supermodelo_pbPriority pbPriority
  def pbPriority(attacker)
    ret = supermodelo_pbPriority(attacker)
    battle = attacker.battle
    if SupermodelStyle.active?(battle) && battle.pbOwnedByPlayer?(attacker.index) &&
       battle.supermodelStyleTier>=3
      ret += 1
    end
    return ret
  end

  # Tier 4+: every attack is a critical hit (tier 5+, via hasMoldBreaker
  # above, also bypasses Battle Armor/Shell Armor; tier 4 alone still
  # respects them).
  alias supermodelo_pbIsCritical? pbIsCritical?
  def pbIsCritical?(attacker,opponent)
    battle = attacker.battle
    if SupermodelStyle.active?(battle) && battle.pbOwnedByPlayer?(attacker.index)
      tier = battle.supermodelStyleTier
      if tier>=5
        return true
      elsif tier>=4
        return false if opponent.hasWorkingAbility(:BATTLEARMOR) || opponent.hasWorkingAbility(:SHELLARMOR)
        return true
      end
    end
    return supermodelo_pbIsCritical?(attacker,opponent)
  end
end

################################################################################
################################################################################
# MEDIUM
################################################################################
################################################################################
#===============================================================================
# The Medium job channels a Pokemon's "spirit" back whenever it's revived
# with an item: each item-based revival nudges a random not-yet-maxed IV up
# by 2, at the cost of the world's "normalcy rate" ($game_variables[33]).
#
# Once that rate has bottomed out at 0 AND the Pokemon being revived already
# has perfect IVs (so there's no stat left to bump), reality slips further
# instead: the Pokemon tries to learn a move borrowed from an unrelated
# species, and the normalcy rate resets to a random 3-5.
#-------------------------------------------------------------------------------
# $game_variables[33] ("tasa de normalidad") starts at 0 via the game's
# opening event; this script only ever floors it at 0 (never lets its own
# -1 push it below that) -- it's assumed to be raised again elsewhere,
# outside this file, as things return to normal between revivals.
#
# Hooked via ItemHandlers.triggerUseOnPokemon / triggerBattleUseOnPokemon --
# the same pair Entrenadora's Revive block and Montaraz's item block already
# use -- so both field and in-battle Revive/Max Revive/Revival Herb usage
# are covered without touching core item scripts. A dedicated alias name is
# used to avoid clashing with those other jobs' aliases on these same hooks.
#===============================================================================

module MediumEffects
  NORMALCY_VARIABLE  = 33  # $game_variables[33], "tasa de normalidad"
  BST_RANGE          = 10  # +/- range used for the first donor-species pass
  NORMALCY_RESET_MIN = 3
  NORMALCY_RESET_MAX = 5

  module_function

  def active?
    return PlayerClasses.current?(PlayerClasses::MEDIUM)
  end

  def normalcy
    $game_variables[NORMALCY_VARIABLE] = 0 if !$game_variables[NORMALCY_VARIABLE]
    return $game_variables[NORMALCY_VARIABLE]
  end

  # Floors at 0 -- this is the only place this script ever lowers the
  # variable, so this is enough to guarantee it never drops below that.
  def normalcy=(value)
    $game_variables[NORMALCY_VARIABLE] = [value,0].max
  end

  #-----------------------------------------------------------------------------
  # Entry point: called after any item successfully brings a Pokemon back
  # from 0 HP (see the ItemHandlers hooks below).
  #-----------------------------------------------------------------------------
  def pbOnRevive(pokemon)
    return if !active?
    return if !pokemon || !pokemon.respond_to?(:belongsToPlayer?) || !pokemon.belongsToPlayer?
    if normalcy==0 && pbPerfectIVs?(pokemon)
      pbAttemptSpiritMove(pokemon)
      self.normalcy = NORMALCY_RESET_MIN+rand(NORMALCY_RESET_MAX-NORMALCY_RESET_MIN+1)
    else
      pbBoostRandomIV(pokemon)
      self.normalcy -= 1
    end
  end

  def pbPerfectIVs?(pokemon)
    return (0..5).all? { |i| pokemon.iv[i]==31 }
  end

  def pbBoostRandomIV(pokemon)
    candidates = (0..5).select { |i| pokemon.iv[i]<31 }
    return if candidates.empty?   # already perfect -- nothing to bump
    stat = candidates[rand(candidates.length)]
    pokemon.iv[stat] = [pokemon.iv[stat]+2,31].min
    pokemon.calcStats
  end

  #-----------------------------------------------------------------------------
  # Species dex-data lookups for the donor search below. Uses a throwaway
  # PokeBattle_Pokemon (withMoves=false, so it skips reading its own starting
  # moveset) rather than duplicating dexdata.dat's byte layout here -- a few
  # species (Rotom, Arceus, Genesect...) resolve their base stats/types/moves
  # through form handlers that expect a normally-initialized Pokemon (item,
  # ability, etc. all set), so a real (if minimal) instantiation is used
  # instead of PokeBattle_Pokemon.allocate to stay safe across the whole dex.
  # This runs the full species list only in the rare "spirit move" branch,
  # not on every ordinary revival.
  #-----------------------------------------------------------------------------
  def pbDummyFor(species)
    return PokeBattle_Pokemon.new(species,1,$Trainer,false)
  end

  def pbSpeciesTypes(species)
    dummy = pbDummyFor(species)
    return [dummy.type1,dummy.type2]
  end

  def pbSpeciesBST(species)
    return pbDummyFor(species).baseStats.inject(0) { |sum,stat| sum+stat }
  end

  def pbSpeciesMoveList(species)
    return pbDummyFor(species).getMoveList
  end

  #-----------------------------------------------------------------------------
  # Finds a donor species with none of the user's types, preferring one with
  # a similar (+/-10) BST, chosen at random among ties. Falls back to the
  # closest BST below that range, then the closest BST above it -- for
  # those two fallback passes a single closest match is used (ties broken by
  # lowest species ID) rather than a random pick among them.
  #-----------------------------------------------------------------------------
  def pbFindDonorSpecies(userTypes,userBST)
    eligible = []
    (1..PBSpecies.maxValue).each do |sp|
      t1,t2 = pbSpeciesTypes(sp)
      next if userTypes.include?(t1) || userTypes.include?(t2)
      eligible.push([sp,pbSpeciesBST(sp)])
    end
    return nil if eligible.empty?

    inRange = eligible.select { |sp,bst| (bst-userBST).abs<=BST_RANGE }
    if !inRange.empty?
    sp,_ = inRange[rand(inRange.length)]
      return sp
    end

    below = eligible.select { |sp,bst| bst<userBST-BST_RANGE }
    if !below.empty?
      maxBst = below.map { |sp,bst| bst }.max
      return below.select { |sp,bst| bst==maxBst }.map { |sp,bst| sp }.min
    end

    above = eligible.select { |sp,bst| bst>userBST+BST_RANGE }
    if !above.empty?
      minBst = above.map { |sp,bst| bst }.min
      return above.select { |sp,bst| bst==minBst }.map { |sp,bst| sp }.min
    end

    return nil   # every species in the dex shares a type with the user
  end

  #-----------------------------------------------------------------------------
  # Picks which of the donor's level-up moves to try to teach: the one it
  # learns exactly at the user's level; else the next level up that teaches
  # one; else (if the donor never learns anything at or above that level)
  # the last one it learns below it.
  #-----------------------------------------------------------------------------
  def pbPickDonorMove(donorSpecies,userLevel)
    moveList = pbSpeciesMoveList(donorSpecies)
    return nil if !moveList || moveList.empty?

    exact = moveList.select { |lvl,mv| lvl==userLevel }
    return exact.first[1] if !exact.empty?

    above = moveList.select { |lvl,mv| lvl>userLevel }.sort_by { |lvl,mv| lvl }
    return above.first[1] if !above.empty?

    below = moveList.select { |lvl,mv| lvl<userLevel }.sort_by { |lvl,mv| lvl }
    return below.last[1] if !below.empty?

    return nil
  end

  def pbAttemptSpiritMove(pokemon)
    userTypes = [pokemon.type1,pokemon.type2]
    userBST   = pokemon.baseStats.inject(0) { |sum,stat| sum+stat }
    donor = pbFindDonorSpecies(userTypes,userBST)
    return if !donor
    move = pbPickDonorMove(donor,pokemon.level)
    return if !move || move==0
    Kernel.pbMessage(_INTL("¡Un eco de {1} resuena dentro de {2}!",PBSpecies.getName(donor),pokemon.name))
    pbLearnMove(pokemon,move)
  end
end

#===============================================================================
# Hook: fires pbOnRevive whenever a bag item actually brings a Pokemon back
# from 0 HP, whether used from the field or from the battle bag. Detected
# generically (fainted before, HP>0 after a successful use) instead of
# hardcoding Revive/Max Revive/Revival Herb's item IDs, since every other
# healing item already refuses to do anything on a fainted Pokemon.
#===============================================================================
module ItemHandlers
  class << self
    alias medium_triggerUseOnPokemon triggerUseOnPokemon
    def triggerUseOnPokemon(item,pokemon,scene)
      wasFainted = pokemon && pokemon.hp==0
      ret = medium_triggerUseOnPokemon(item,pokemon,scene)
      MediumEffects.pbOnRevive(pokemon) if ret && wasFainted && pokemon.hp>0
      return ret
    end

    alias medium_triggerBattleUseOnPokemon triggerBattleUseOnPokemon
    def triggerBattleUseOnPokemon(item,pokemon,battler,scene)
      wasFainted = pokemon && pokemon.hp==0
      ret = medium_triggerBattleUseOnPokemon(item,pokemon,battler,scene)
      MediumEffects.pbOnRevive(pokemon) if ret && wasFainted && pokemon.hp>0
      return ret
    end
  end
end

#===============================================================================
# Drawback: at the Pokemon Center (or anywhere else pbHealAll gets called),
# only the starter Pokemon can be revived -- any other fainted party member
# stays fainted. Non-fainted Pokemon are still healed normally regardless of
# whether they're the starter.
#
# pbHealAll heals Pokemon directly (PokeBattle_Pokemon#heal) rather than
# going through ItemHandlers, so it never reaches the revival hook above --
# the starter reviving this way never gets Medium's IV boost or spirit
# move, exactly as intended.
#===============================================================================
alias medium_pbHealAll pbHealAll
def pbHealAll
  return if !$Trainer
  if defined?(MediumEffects) && MediumEffects.active?
    $Trainer.party.each do |p|
      next if !p
      next if p.hp==0 && !p.starter?
      p.heal
    end
  else
    medium_pbHealAll
  end
end