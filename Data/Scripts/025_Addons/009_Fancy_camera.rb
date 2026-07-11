#===============================================================================
# ENLS's Fancy Camera — PORT Essentials v16.x (RMXP / Ruby 1.8)
# ------------------------------------------------------------------------------
# Basado en los 3 archivos del recurso v21.1:
#   000_Config.rb
#   001_Camera Script.rb
#   002_Method Overrides.rb
#
# Objetivo del port:
# - Mantener la MISMA API pública:
#   pbCameraScroll, pbCameraScrollTo, pbCameraScrollDirection,
#   pbCameraReset, pbCameraToEvent, pbCameraShake, pbCameraShakeOff,
#   pbCameraSpeed, pbCameraOffset
# - Mantener el MISMO estado en $game_temp:
#   camera_pos/camera_x/camera_y/camera_shake/camera_speed/camera_offset/camera_target_event
# - Mantener el mismo easing (ease_in_out -> old_lerp) y el shake aleatorio.
# - Override del comando de evento "Scroll Map" (Interpreter#command_203) si está activado.
#
# Instalación: pegar encima de Main.
#===============================================================================

#-------------------------------------------------------------------------------
# 0) Compat helpers (v16 no siempre tiene estos constantes/métodos)
#-------------------------------------------------------------------------------
class FancyCamera
  # Default camera speed (Default: 1)
  DEFAULT_SPEED = 1
  # Increase camera speed when running (Default: true)
  INCREASE_WHEN_RUNNING = true
  # Override Scroll Map event commands (Default: true)
  OVERRIDE_SCROLL_MAP = true
end

# Graphics.average_frame_rate no existe en muchas bases viejas.
# En v21 se usa para que el lerp sea "framerate independent".
if !Graphics.respond_to?(:average_frame_rate)
  module Graphics
    def self.average_frame_rate
      # frame_rate en RMXP suele ser 40 por defecto
      return (self.frame_rate rescue 40)
    end
  end
end

# En RMXP/Essentials v16, display_x/y usan "real units" (1 tile = 128).
# En v21 están como Game_Map::REAL_RES_X/Y.
class Game_Map
  REAL_RES_X = 128 if !const_defined?(:REAL_RES_X)
  REAL_RES_Y = 128 if !const_defined?(:REAL_RES_Y)
end

# En v21 están como Game_Player::SCREEN_CENTER_X/Y.
# En RMXP el center clásico usa: (Graphics.width - 32)/2 * 4  (porque 1px = 4 units)
class Game_Player
  if !const_defined?(:SCREEN_CENTER_X)
    SCREEN_CENTER_X = ((Graphics.width  - 32) / 2) * 4
  end
  if !const_defined?(:SCREEN_CENTER_Y)
    SCREEN_CENTER_Y = ((Graphics.height - 32) / 2) * 4
  end
end

#-------------------------------------------------------------------------------
# 1) Game_Temp: estado de cámara (calcado al original)
#-------------------------------------------------------------------------------
class Game_Temp
  attr_accessor :camera_pos, :camera_x, :camera_y, :camera_shake,
                :camera_speed, :camera_offset, :camera_target_event

  def camera_pos
    @camera_pos = [0, 0] if !@camera_pos
    return @camera_pos || [(self.camera_x * Game_Map::REAL_RES_X) - Game_Player::SCREEN_CENTER_X,
                           (self.camera_y * Game_Map::REAL_RES_Y) - Game_Player::SCREEN_CENTER_Y] || [0, 0]
  end

  def camera_pos=(value)
    @camera_pos = [0, 0] if !@camera_pos
    $game_temp.camera_target_event = nil
    self.camera_x = value[0]
    self.camera_y = value[1]
  end

  def camera_x=(value)
    @camera_pos = [0, 0] if !@camera_pos
    @camera_x = value
    @camera_pos[0] = ((value == 0) ? 0 : (@camera_x * Game_Map::REAL_RES_X) - Game_Player::SCREEN_CENTER_X)
  end

  def camera_y=(value)
    @camera_pos = [0, 0] if !@camera_pos
    @camera_y = value
    @camera_pos[1] = ((value == 0) ? 0 : (@camera_y * Game_Map::REAL_RES_Y) - Game_Player::SCREEN_CENTER_Y)
  end

  def camera_x
    return @camera_x || 0
  end

  def camera_y
    return @camera_y || 0
  end

  def camera_shake
    return @camera_shake || 0
  end

  def camera_shake=(value)
    @camera_shake = value
  end

  def camera_speed
    # OJO: el original devuelve *0.16 y luego en update_screen_position multiplica *0.2,
    # pero ese *0.2 es ya parte del método override. Mantengo tal cual su clase.
    return (@camera_speed || FancyCamera::DEFAULT_SPEED || 1) * 0.16
  end

  def camera_offset
    @camera_offset = [0, 0] if !@camera_offset
    return @camera_offset
  end

  def camera_offset=(value)
    @camera_offset = value
  end

  def camera_target_event
    return @camera_target_event || 0
  end

  def camera_target_event=(value)
    @camera_target_event = value
  end
end

#-------------------------------------------------------------------------------
# 2) API pública (calcada al original v21.1)
#-------------------------------------------------------------------------------

# Scrolls the camera to x, y relative the player
def pbCameraScroll(relative_x, relative_y, speed = nil)
  pbCameraSpeed(speed) if speed
  $game_temp.camera_pos = [$game_player.x + relative_x, $game_player.y + relative_y]
end

def pbCameraScrollDirection(direction, distance, speed = nil)
  speed = FancyCamera::DEFAULT_SPEED if !speed || speed == 0
  x = ($game_temp.camera_x == 0) ? $game_player.x : $game_temp.camera_x
  y = ($game_temp.camera_y == 0) ? $game_player.y : $game_temp.camera_y
  case direction
  when 1 # Down Left
    x -= 1 * distance
    y += 1 * distance
  when 2 # Down
    y += 1 * distance
  when 3 # Down Right
    x += 1 * distance
    y += 1 * distance
  when 4 # Left
    x -= 1 * distance
  when 6 # Right
    x += 1 * distance
  when 7 # Up Left
    x -= 1 * distance
    y -= 1 * distance
  when 8 # Up
    y -= 1 * distance
  when 9 # Up Right
    x += 1 * distance
    y -= 1 * distance
  end
  case speed
  when 1  # Slowest
    speed = FancyCamera::DEFAULT_SPEED * 0.5
  when 2  # Slower
    speed = FancyCamera::DEFAULT_SPEED * 0.75
  when 3  # Slow
    speed = FancyCamera::DEFAULT_SPEED * 0.85
  when 4  # Fast
    speed = FancyCamera::DEFAULT_SPEED * 1
  when 5  # Faster
    speed = FancyCamera::DEFAULT_SPEED * 1.5
  when 6  # Fastest
    speed = FancyCamera::DEFAULT_SPEED * 2
  end
  pbCameraScrollTo(x, y, speed)
end

# Scrolls the camera to x, y on the map
def pbCameraScrollTo(x, y, speed = nil)
  if x == $game_player.x && y == $game_player.y
    pbCameraReset(speed)
  else
    pbCameraSpeed(speed) if speed
    $game_temp.camera_pos = [x, y]
  end
end

# Sets the camera to the player and resets the speed
def pbCameraReset(speed = nil)
  $game_temp.camera_speed = (speed != nil) ? speed : FancyCamera::DEFAULT_SPEED
  $game_temp.camera_target_event = nil
  $game_temp.camera_pos = [0, 0]
end

# Scrolls the camera to an event
def pbCameraToEvent(event_id = nil, speed = nil)
  pbCameraSpeed(speed) if speed
  # En v21 usa get_self.id si no pasas id.
  # En v16 suele existir get_self dentro de eventos; lo dejamos igual pero protegido.
  event_id = (get_self.id rescue nil) if !event_id
  return if !event_id
  event = $game_map.events[event_id] rescue nil
  return if !event
  $game_temp.camera_target_event = event_id
end

# Starts a camera shake
def pbCameraShake(power = 2)
  $game_temp.camera_shake = power
end

# Stops the camera shake
def pbCameraShakeOff
  $game_temp.camera_shake = 0
end

# Sets the camera speed
def pbCameraSpeed(speed)
  speed = FancyCamera::DEFAULT_SPEED if !speed || speed == 0
  $game_temp.camera_speed = speed
end

# Sets the camera offset
def pbCameraOffset(x, y)
  $game_temp.camera_offset = [x, y]
end

#-------------------------------------------------------------------------------
# 3) Lerp helpers (calcados al original)
#-------------------------------------------------------------------------------
def old_lerp(a, b, t)
  t = t / (Graphics.average_frame_rate / 60.0)
  return (1 - t) * a + t * b
end

def ease_in_out(a, b, t)
  return old_lerp(a, b, t * (3.0 - t))
end

#-------------------------------------------------------------------------------
# 4) Overrides (adaptados a v16 sin depender de GameData::PlayerMetadata)
#-------------------------------------------------------------------------------
class Game_Player < Game_Character
  # v16: aseguramos que exista update_screen_position y que se ejecute cada frame.
  def update_screen_position(_last_real_x = nil, _last_real_y = nil)
    return if $game_map.scrolling?

    # Target = seguir al jugador
    target = [@real_x - SCREEN_CENTER_X, @real_y - SCREEN_CENTER_Y]

    # Si hay camera_pos fijada (no 0,0) -> lock a tile/coord
    if $game_temp.camera_pos && $game_temp.camera_pos[0] != 0 && $game_temp.camera_pos[1] != 0
      target = $game_temp.camera_pos
    end

    # Si sigue a evento
    if $game_temp.camera_target_event && $game_temp.camera_target_event != 0
      event = $game_map.events[$game_temp.camera_target_event] rescue nil
      if event
        target = [event.real_x - SCREEN_CENTER_X, event.real_y - SCREEN_CENTER_Y]
      end
    end

    # Shake aleatorio
    if $game_temp.camera_shake > 0
      power = $game_temp.camera_shake * 25
      target = [target[0] + rand(-power..power), target[1] + rand(-power..power)]
    end

    # Offset (en tiles -> real units)
    if $game_temp.camera_offset && $game_temp.camera_offset != [0, 0]
      target = [target[0] + ($game_temp.camera_offset[0] * Game_Map::REAL_RES_X),
                target[1] + ($game_temp.camera_offset[1] * Game_Map::REAL_RES_Y)]
    end

    distance = Math.sqrt((target[0] - $game_map.display_x)**2 + (target[1] - $game_map.display_y)**2)
    speed = $game_temp.camera_speed * 0.2

    # Aumento de velocidad según move_speed (v16 no tiene set_movement_type como v21)
    if FancyCamera::INCREASE_WHEN_RUNNING
      ms = (self.move_speed rescue 3)
      # ms 3 walk, 4 run, 5 bike (depende de tu base). Esto lo aproxima.
      speed *= 1.0 + [(ms - 3), 0].max * 0.20
    end

    if distance < 0.75
      $game_map.display_x = target[0]
      $game_map.display_y = target[1]
    else
      $game_map.display_x = ease_in_out($game_map.display_x, target[0], speed)
      $game_map.display_y = ease_in_out($game_map.display_y, target[1], speed)
    end
  end

  # Hook para llamarlo cada frame en v16
  alias __fancycam_update update
  def update
    last_x = @real_x
    last_y = @real_y
    __fancycam_update
    update_screen_position(last_x, last_y)
  end

  # center clásico: si te centran por transfer u otros scripts, resetea cámara y hace snap
  def center(x, y)
    pbCameraReset if $game_temp.camera_pos
    $game_map.display_x = (x * Game_Map::REAL_RES_X) - SCREEN_CENTER_X
    $game_map.display_y = (y * Game_Map::REAL_RES_Y) - SCREEN_CENTER_Y
  end

  # moveto con tercer parámetro opcional (compat con el recurso)
  alias __fancycam_moveto moveto
  def moveto(x, y, center = false)
    __fancycam_moveto(x, y)
    self.center(x, y) if center
    make_encounter_count if self.respond_to?(:make_encounter_count)
  end
end

#-------------------------------------------------------------------------------
# 5) Override del comando de evento "Scroll Map" (Interpreter#command_203)
#-------------------------------------------------------------------------------
if FancyCamera::OVERRIDE_SCROLL_MAP
  class Interpreter
    # Si tu base ya tiene command_203, lo machacamos tal cual hace el recurso.
    def command_203
      # En algunas bases existe $game_temp.in_battle, en otras no.
      return true if ($game_temp.respond_to?(:in_battle) && $game_temp.in_battle)

      x = ($game_temp.camera_x == 0) ? $game_player.x : $game_temp.camera_x
      y = ($game_temp.camera_y == 0) ? $game_player.y : $game_temp.camera_y

      case @parameters[0]
      when 2  # Down
        y += 1 * @parameters[1]
      when 4  # Left
        x -= 1 * @parameters[1]
      when 6  # Right
        x += 1 * @parameters[1]
      when 8  # Up
        y -= 1 * @parameters[1]
      end

      case @parameters[2]
      when 1  # Slowest
        speed = FancyCamera::DEFAULT_SPEED * 0.5
      when 2  # Slower
        speed = FancyCamera::DEFAULT_SPEED * 0.75
      when 3  # Slow
        speed = FancyCamera::DEFAULT_SPEED * 0.85
      when 4  # Fast
        speed = FancyCamera::DEFAULT_SPEED * 1
      when 5  # Faster
        speed = FancyCamera::DEFAULT_SPEED * 1.5
      when 6  # Fastest
        speed = FancyCamera::DEFAULT_SPEED * 2
      else
        speed = FancyCamera::DEFAULT_SPEED
      end

      pbCameraScrollTo(x, y, speed)
      return true
    end
  end
end

#-------------------------------------------------------------------------------
# 6) Safety: resetear cámara en transfers (sin reescribir todo transfer_player)
#-------------------------------------------------------------------------------
class Scene_Map
  if instance_methods.include?("transfer_player") || instance_methods.include?(:transfer_player)
    alias __fancycam_transfer_player transfer_player
    def transfer_player(*args)
      __fancycam_transfer_player(*args)
      pbCameraReset rescue nil
    end
  end
end
#===============================================================================
# END
#===============================================================================
