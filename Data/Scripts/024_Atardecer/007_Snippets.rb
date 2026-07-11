=begin
# - suppressResidualBonus: temporarily set around self-inflicted HP loss
#   (recoil, Struggle, Curse/Substitute's own cost) so Ingeniera's bonus
#   doesn't apply to it.

  # Ingeniera
  INGENIERA_RESIDUAL_BONUS = 0.20  # +20% on the boosted residual damage categories (see below)
  INGENIERA_DIRECT_PENALTY = 0.30  # -30% direct move damage dealt to foes (non-crit)

class PokeBattle_Battle
  attr_accessor :suppressResidualBonus
end

#===============================================================================
# Direct move damage: -30% to foes on non-crit hits, +20% to foes on
# confusion self-hits (the only "boosted" category that goes through this
# method instead of Battler#pbReduceHP), 

class PokeBattle_Move
  alias original_pbReduceHPDamage pbReduceHPDamage
  def pbReduceHPDamage(damage,attacker,opponent)
      if PlayerClasses.current?(PlayerClasses::INGENIERA)
        if attacker!=opponent && attacker && @battle.pbOwnedByPlayer?(attacker.index) &&
           !@battle.pbOwnedByPlayer?(opponent.index) && !opponent.damagestate.critical
          before=damage
          damage=(damage*(1.0-PlayerClasses::INGENIERA_DIRECT_PENALTY)).round
          PBDebug.log("[Trabajo: Ingeniera] Daño directo: #{before} -> #{damage}")
        elsif attacker==opponent && self.is_a?(PokeBattle_Confusion) &&
              !@battle.pbOwnedByPlayer?(opponent.index)
          before=damage
          damage=(damage*(1.0+PlayerClasses::INGENIERA_RESIDUAL_BONUS)).round
          PBDebug.log("[Trabajo: Ingeniera] Daño de confusión: #{before} -> #{damage}")
        end
      end
    end
    return original_pbReduceHPDamage(damage,attacker,opponent)
  end
end


#===============================================================================
# Exclusions: recoil moves, Struggle, Curse's and Substitute's own HP cost.
# These wrap each move's own effect method just to flag "don't boost the next
# pbReduceHP call", so the bonus doesn't apply to self-inflicted HP loss that
# happens to hit an enemy battler.
#===============================================================================
module SuppressResidualBonus
  def pbSuppressResidualBonus
    @battle.suppressResidualBonus=true
    yield
  ensure
    @battle.suppressResidualBonus=false
  end
end

# Recoil moves (Take Down, Double-Edge, Flare Blitz, Wild Charge, Head Smash,
# Chloroblast/Steel Beam-style, etc.) and Struggle
[:PokeBattle_Move_0FA,:PokeBattle_Move_0FB,:PokeBattle_Move_0FC,:PokeBattle_Move_0FD,
 :PokeBattle_Move_0FE,:PokeBattle_Move_10B,:PokeBattle_Move_231,:PokeBattle_Move_278,
 :PokeBattle_Struggle].each do |classname|
  next if !Object.const_defined?(classname)
  klass=Object.const_get(classname)
  klass.class_eval do
    include SuppressResidualBonus
    alias original_pbEffectAfterHit pbEffectAfterHit
    def pbEffectAfterHit(attacker,opponent,turneffects)
      pbSuppressResidualBonus { original_pbEffectAfterHit(attacker,opponent,turneffects) }
    end
  end
end

# Curse's own HP cost when a Ghost-type uses it (the residual damage dealt to
# a cursed TARGET each turn is a separate, later call and still gets boosted)
if Object.const_defined?(:PokeBattle_Move_10D)
  class PokeBattle_Move_10D
    include SuppressResidualBonus
    alias original_pbEffect pbEffect
    def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
      pbSuppressResidualBonus { original_pbEffect(attacker,opponent,hitnum,alltargets,showanimation) }
    end
  end
end

# Substitute's own HP cost when created
if Object.const_defined?(:PokeBattle_Move_10C)
  class PokeBattle_Move_10C
    include SuppressResidualBonus
    alias original_pbEffect pbEffect
    def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
      pbSuppressResidualBonus { original_pbEffect(attacker,opponent,hitnum,alltargets,showanimation) }
    end
  end
end

#===============================================================================
# All other "boosted" categories (binding moves, status damage, weather,
# Curse/Leech Seed/Bad Dreams/Nightmare, entry hazards, Rough Skin/Rocky
# Helmet-style contact punishment) go through Battler#pbReduceHP without an
# attacker reference, so a single hook here covers every one of them: the
# bonus applies whenever the battler losing HP isn't owned by the player.
#
# Known approximation: Dry Skin's self-damage in harsh sunlight also goes
# through this same method with no way to tell it apart from, say, Stealth
# Rock damage on the same Pokemon from first principles, so it's excluded via
# a state check (ability + weather) instead of a call-site flag. This can, in
# the rare case where a Dry Skin Pokemon takes damage from something else in
# the very same instant, incorrectly skip that other instance's bonus too.
# This is a deliberate choice to keep the check self-contained in this
# script rather than editing the core weather-damage code.
#===============================================================================
class PokeBattle_Battler
  alias original_pbReduceHP pbReduceHP
  def pbReduceHP(amt,anim=false,registerDamage=true)
    if PlayerClasses.current?(PlayerClasses::INGENIERA) && @battle &&
       !@battle.suppressResidualBonus && !@battle.pbOwnedByPlayer?(self.index)
      isDrySkinSun=hasWorkingAbility(:DRYSKIN) &&
                   (@battle.pbWeather==PBWeather::SUNNYDAY || @battle.pbWeather==PBWeather::HARSHSUN)
      if !isDrySkinSun
        before=amt
        amt=(amt*(1.0+PlayerClasses::INGENIERA_RESIDUAL_BONUS)).round
      end
    end
    return original_pbReduceHP(amt,anim,registerDamage)
  end
end
=end
