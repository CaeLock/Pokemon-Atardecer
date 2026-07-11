#Este script sobreescribe el "def update" de "Game_Player"
#Añade velocidades ligeramente más rapidas de movimiento, y que no se ven afectadas en eventos.
#By Clara
class Game_Player
  def update
    
    if PBTerrain.isIce?(pbGetTerrainTag)
      @move_speed = (Graphics.frame_rate>=60) ? 4.6 : 5 # Sliding on ice
    elsif !moving? && !@move_route_forcing && $PokemonGlobal
      if $PokemonGlobal.bicycle
        @move_speed = (Graphics.frame_rate>=60) ? 5.4 : 6 # Cycling
      elsif pbCanRun? || $PokemonGlobal.surfing || $PokemonGlobal.diving
        @move_speed = (Graphics.frame_rate>=60) ? 4.6 : 5 # Running, surfing or diving
      else
        unless pbMapInterpreterRunning?
          @move_speed = (Graphics.frame_rate>=60) ? 3.6 : 4 # Walking
        else
          @move_speed = (Graphics.frame_rate>=60) ? 3 : 4 # Walking
        end
      end
    end
    update_old
  end
end