#By Clara
#Un pequeño apaño para poder usar eventos sobre puentes, requiere usar un interruptor llamado: s:!pbOnBridge
#Lo pondremos en una segunda pagina configurada como en la imagen, y con el mismo grafico que estemos usando 
#para el evento que queremos que este sobre el puente

alias pbBridgeOn_refresh pbBridgeOn
def pbBridgeOn(height=2)
  pbBridgeOn_refresh 
  $game_map.need_refresh = true
end

alias pbBridgeOff_refresh pbBridgeOff
def pbBridgeOff
  pbBridgeOff_refresh
  $game_map.need_refresh = true
end

def pbOnBridge #Switch 38
  return true if $PokemonGlobal.bridge != 0
  return false
end