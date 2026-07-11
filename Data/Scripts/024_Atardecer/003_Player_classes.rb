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
  CAMPEONA    = :CAMPEONA

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
      :description => _INTL("Tus Pokémon ganan amistad al ganar combates y salir al campo, y desbloquean beneficios según su amistad, pero pierden más al debilitarse o subir de nivel en el PC."),
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

#Campeona's survive-a-fatal-hit
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