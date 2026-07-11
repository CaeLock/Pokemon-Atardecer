# Plugin independiente: duraciones para aumentos de estadísticas
# Hace que cada aumento de estadística expire tras N turnos desde la última vez que se aumentó.
# Coloca este script al final de la carpeta de scripts de batalla (para que los alias se apliquen).

module PokeBattle_StatDurations
  # Configuración: número de turnos que dura un aumento después del último aumento (por defecto)
  STAT_DURATION_DEFAULT = 7    # Duración estándar en turnos
  ACCURACY_DURATION      = 7   # Duración para PRECISIÓN (si deseas otra duración)
  EVASION_DURATION       = 7   # Duración para EVASIÓN (puedes cambiar)
  # Mapa por estadística (usa constantes PBStats)
  STAT_DURATION_MAP = {
    PBStats::ATTACK   => STAT_DURATION_DEFAULT,
    PBStats::DEFENSE  => STAT_DURATION_DEFAULT,
    PBStats::SPATK    => STAT_DURATION_DEFAULT,
    PBStats::SPDEF    => STAT_DURATION_DEFAULT,
    PBStats::SPEED    => STAT_DURATION_DEFAULT,
    PBStats::ACCURACY => ACCURACY_DURATION,
    PBStats::EVASION  => EVASION_DURATION
  }

  # Mensajes por estadística cuando expira el efecto (español)
  # NOTA: aquí se guardan las plantillas; se llaman con _INTL(msg, nombre)
  STAT_EXPIRE_MESSAGES = {
    PBStats::ATTACK   => "¡El ataque de {1} volvió a la normalidad!",
    PBStats::DEFENSE  => "¡La defensa de {1} volvió a la normalidad!",
    PBStats::SPATK    => "¡El ataque especial de {1} volvió a la normalidad!",
    PBStats::SPDEF    => "¡La defensa especial de {1} volvió a la normalidad!",
    PBStats::SPEED    => "¡La velocidad de {1} volvió a la normalidad!",
    PBStats::ACCURACY => "¡La precisión de {1} volvió a la normalidad!",
    PBStats::EVASION  => "¡La evasión de {1} volvió a la normalidad!"
  }
end

# ------------------------------
# Aliases & behavior
# ------------------------------
class PokeBattle_Battler
  # Baton Pass: NO transferir timers (se reinician en el receptor).
  alias __statdur_pbInitEffects pbInitEffects
  def pbInitEffects(batonpass)
    __statdur_pbInitEffects(batonpass)
    # Si entra por Baton Pass, NO transfieres los timers: se reinician.
    if batonpass
      @stat_timers = {}
    else
      @stat_timers ||= {}
    end
  end

  # Helper: establece un timer de duración para una estadística positiva
  def set_stat_timer(stat,turns)
    @stat_timers ||= {}
    @stat_timers[stat] = turns
  end

  # Helper: borra el timer (por ejemplo si la estadística se reduce)
  def clear_stat_timer(stat)
    @stat_timers ||= {}
    @stat_timers.delete(stat)
  end

  # Helper: borra todos los timers del battler
  def clear_all_stat_timers
    @stat_timers ||= {}
    if @stat_timers.any?
      @stat_timers.clear
      PBDebug.log("[StatDuration] #{pbThis} cleared all stat timers")
    end
  end

  # Helper: obtiene el timer actual (0 si no existe)
  def get_stat_timer(stat)
    @stat_timers ||= {}
    return @stat_timers[stat] || 0
  end

  # Helper: forzar valor de stages (equivalente a setstats del parche original)
  def set_stage_to(stat,n=0)
    @stages[stat] = n
  end
end

class PokeBattle_Battler
  # Aliasing pbIncreaseStatBasic para resetear/establecer el timer cuando se aumente estadística
  
  alias __statdur_pbIncreaseStatBasic pbIncreaseStatBasic
  def pbIncreaseStatBasic(*args)
    # args[0] => stat, args[1] => increment, el resto puede variar según llamadas
    increment_result = __statdur_pbIncreaseStatBasic(*args)
    stat = args[0] rescue nil
    if increment_result && increment_result > 0 && stat
      duration = PokeBattle_StatDurations::STAT_DURATION_MAP[stat] ||
                PokeBattle_StatDurations::STAT_DURATION_DEFAULT
      set_stat_timer(stat, duration) if respond_to?(:set_stat_timer)
      PBDebug.log("[StatDuration] #{pbThis} set timer for #{PBStats.getName(stat)} = #{duration}")
    end
    return increment_result
  end

  alias __statdur_pbReduceStatBasic pbReduceStatBasic
  def pbReduceStatBasic(*args)
    # args[0] => stat, args[1] => increment, etc.
    res = __statdur_pbReduceStatBasic(*args)
    stat = args[0] rescue nil
    if res && res > 0 && stat
      clear_stat_timer(stat) if respond_to?(:clear_stat_timer)
      PBDebug.log("[StatDuration] #{pbThis} cleared timer for #{PBStats.getName(stat)} due to reduction")
    end
    return res
  end
end

class PokeBattle_Battle
  # Al final de la fase de ronda, descontar timers y curar subidas que expiren.
  alias __statdur_pbEndOfRoundPhase pbEndOfRoundPhase
  def pbEndOfRoundPhase
    __statdur_pbEndOfRoundPhase()

    # Después de la lógica original de fin de ronda, procesamos las expiraciones:
    for i in 0...@battlers.length
      b = @battlers[i]
      next if !b || b.isFainted?
      next if !b.instance_variable_defined?(:@stat_timers) || b.instance_variable_get(:@stat_timers).empty?
      timers = b.instance_variable_get(:@stat_timers)
      # Iterar sobre una copia de las claves porque podemos eliminar durante el recorrido
      timers.keys.clone.each do |stat|
        next if !timers[stat] || timers[stat] <= 0
        timers[stat] -= 1
        if timers[stat] <= 0
          # Expiró: poner el stage de esa estadística a 0 y notificar
          b.set_stage_to(stat, 0)
          timers.delete(stat)
          msg = PokeBattle_StatDurations::STAT_EXPIRE_MESSAGES[stat]
          if msg
            begin
              pbDisplay(_INTL(msg, b.pbThis))
            rescue
              # no bloquear si pbDisplay da error
            end
          else
            begin
              pbDisplay(_INTL("{1}'s {2} returned to normal.", b.pbThis, PBStats.getName(stat)))
            rescue
            end
          end
          PBDebug.log("[StatDuration] #{b.pbThis} #{PBStats.getName(stat)} timer expired - stage reset")
        end
      end
    end
  end
end

# ------------------------------
# Limpieza en HAZE / CLEARSMOG y uso de White Herb
# ------------------------------
class PokeBattle_Move
  alias __statdur_pbEffect pbEffect
  # pbEffect(attacker,opponent,...) is the common signature in the move base class
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret = __statdur_pbEffect(attacker,opponent,hitnum,alltargets,showanimation)
    # Limpieza tras HAZE: afecta a todos los battlers (restaura stages a 0 normalmente)
    begin
      if isConst?(@id,PBMoves,:HAZE)
        for i in 0...@battle.battlers.length
          b=@battle.battlers[i] rescue nil
          next if !b
          begin
            b.clear_all_stat_timers if b.respond_to?(:clear_all_stat_timers)
          rescue
          end
        end
        PBDebug.log("[StatDuration] HAZE used - cleared all stat timers for all battlers")
      elsif isConst?(@id,PBMoves,:CLEARSMOG)
        # Clear Smog afecta al objetivo
        if opponent && opponent.respond_to?(:clear_all_stat_timers)
          begin
            opponent.clear_all_stat_timers
            PBDebug.log("[StatDuration] CLEARSMOG used - cleared stat timers for #{opponent.pbThis}")
          rescue
          end
        end
      end
    rescue
      # evitar errores si alguna constante no existe (compatibilidad)
    end
    return ret
  end
end

# Hook para limpiar timers cuando se activa la Hierba Blanca (WHITEHERB).
# White Herb normalmente se maneja en PokeBattle_Battler (bloque que restaura stages negativos).
# No sabemos exactamente qué método consume el item en todas las rutas, pero pbConsumeItem
# se invoca cuando el objeto es usado. Por seguridad, aliasamos pbConsumeItem si existe.
if PokeBattle_Battler.method_defined?(:pbConsumeItem)
  class PokeBattle_Battler
    alias __statdur_pbConsumeItem pbConsumeItem
    def pbConsumeItem(*args)
      # Antes de consumir, detectar si el item es WHITEHERB y si se van a restaurar stats.
      item = self.item rescue 0
      res = __statdur_pbConsumeItem(*args)
      begin
        if item && isConst?(item,PBItems,:WHITEHERB)
          # Si la hierba blanca se consumió para restaurar stages, limpiar timers
          self.clear_all_stat_timers if self.respond_to?(:clear_all_stat_timers)
          PBDebug.log("[StatDuration] WHITEHERB consumed - cleared stat timers for #{pbThis}")
        end
      rescue
      end
      return res
    end
  end
else
  
  # Si no existe pbConsumeItem, intentamos leer un posible pbUseItemOnPokemon o pbUseItem.
end
