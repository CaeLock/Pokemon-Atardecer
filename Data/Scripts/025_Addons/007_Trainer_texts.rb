#-----------------------------------------------------------------------------
# Script creado por FiaPlay para Pokémon Essentials BES. Créditos si se usa.
# Si vas reportar algún bug o preguntar algo recomiendo hacerlo en el hilo del Discord de PokeLiberty.
#-----------------------------------------------------------------------------
# Demostración https://youtu.be/qri2bylfpQA
#-----------------------------------------------------------------------------
# Modo de uso:
# Para activar los textos solo setBattleRule("mbs",:Symbol que contiene los datos) #Los : son necesarios
=begin Para un ejemplo práctico pegue una de las siguientes 4 líneas en una llamada a script
setBattleRule("mbs",:FiaPlay)#Demo General
setBattleRule("mbs",:Multy)  #Demo de Combate Múltiple
setBattleRule("mbs",:MBS)    #Demo de Mid-Battle-Script
setBattleRule("mbs",:MEWTWO) #Demo de Pokémon Salvaje
=end
=begin Si lo que quiere es definirlo desde una llamada a Script (Ni idea de por qué) podría:
dialogue={
"mega" => "¡Voy con todo!",
"super_effective_move(player)" => "Sabes lo que haces muchacho."
}
setBattleRule("mbs",dialogue)
En caso de que quieras solo el del último pokémon:
setBattleRule("mbs","¡Es el momento de darlo todo!")
=end

#-----------------------------------------------------------------------------
# FAQ:
#*¿Para cuando videotutorial?
# Para cuando tenga ganas.
#
#*¿Cómo puedo añadir nuevos "dialog_trigers" o modificar como se muestran?
# Dale un vistazo a los métodos fpShowText , fpDialog y fpXtraChecks. Deberás tener algunos conocimientos de programación.
#
#*He recibido x error y me parece que es este script.
# Avísame por el Discord. (Solo si de verdad crees que fue este script)
#-----------------------------------------------------------------------------
# Estas son las opciones cámbialas a como necesites.
#-----------------------------------------------------------------------------
module MBS_Data

COLORBARSTYLE = 1 # 0:No se usa, 1:Por defecto, 2:Rellenar.
SHOWSE = "" # Efecto de sonido que se reproducirá al mostrarse el entrenador.
DEFAULTLASTBGM = "Battle! (Champion)" #BGM por defecto para el último Pokemon.

#Lista con los colores de texto de cada entrenador (Base, Sombra).
#Por limitaciones de RGSS no funcionan nombres con caracteres no ingleses.
CHARACTERS_COLORS = {"FiaPlay"     => [Color.new(22,245,237),Color.new(1,102,99)],
                     "Flandecson"  => [Color.new(245,22,22),Color.new(102,1,1)],
                     "Cozmoz"      => [Color.new(204,22,245),Color.new(102,1,95)],
                     "//PN"        => [Color.new(22,245,237),Color.new(1,102,99)] #Jugador
}

#Coloca en el sig. Hash como clave un fragmento del nombre de algún entrenador y como parámetro la clave que tendrá sus colores en el Hash anterior.
#Esto es para que funcione bien con caracteres no ingleses. Aunque Quisás alguien le encuentre otro uso :)
NONENGLISCHARACTERS = {"ndecson" => "Flandecson"} #Flándecson en este caso
#-------------------------------------------------------------------------------------------------------------------------------------------------
# En la siguiente constante están configurados todos los diálogos posibles.
# Es posible colocar (player) , (opp2) o (ally) al final de algunas claves para que se active con el jugador, segundo oponente o el aliado.
# Si colocas |cry| en un texto se repdoducirá el grito del Pokémon enemigo.
# Si colocas //ht en un texto no se mostrará el entrenador.
# Si colocas //t2 en un texto se mostrará el entrenador 2.
# Si colocas //bt en un texto se mostrará ambos entrenadores.
# Si colocas : en un texto todo lo que esté antes de : se considerará nombre del entrenador.
# Si colocas //PN en un texto se mostrará el nombre del entrenador.
# Si colocas //BXN en un texto se mostrará el nombre del battler X.
# Si colocas //T1BXN en un texto se mostrará el primer tipo del battler X.
# Si colocas //ON en un texto se mostrará el nombre del rival.
# Si colocas //O2N en un texto se mostrará el nombre del rival 2.
# Si colocas //AN en un texto se mostrará el nombre del aliado.
# En algunos casos puedes colocar af_ antes de la clave para que se ejecute luego de la acción:
# mega primal tera ultra z_move recall last faint
#-------------------------------------------------------------------------------------------------------------------------------------------------
FiaPlay={
  "barscolor" => Color.new(0,255,255),
  "last_bgm" => true,
  "last" => "Último Pokémon.",
  "end_turn" => {0  =>  "Final del primer turno.",
                 11 =>  "Final del 12mo turno."},
  "pre_start_turn" => {0  =>  "Inicio del primer turno."},
  "start_turn" => {0  =>  "Luego de seleccionar acción en el primer turno."},
  "one_poke" => "Cuando el jugador solo tiene un Pokémon en su equipo.",
  "lowhp_last" => "El último Pokémon tiene pocos PS",
  "shiny" => "Sale un Pokémon Shiny al combate.",
  "mega" => "Texto de Megaevolución.",
  "mega(ICE)" => "Texto de Megaevolución. (Pokémon de Hielo)",
  "primal" => "Texto de Regresión Primigenia.",
  "primal(WATER)" => "Texto de Regresión Primigenia. (Kyogre)",
  "ultra" => "Texto de Ultraexplosión.",
  "faint" => {:KYOGRE => "Se debilitó Kygogre.",
              "mega" => "Se debilitó un Mega-Pokémon."},
  "z_move" => "Movimiento Z.",
  "z_move(GRASS)" => "Movimiento Z de Planta.",
  "tera" => "Teracristalización.",
  "send" => {:KYOGRE   =>  "Texto al enviar a Kyogre.",
             :GROUDON  =>  "Texto al enviar a Groudon.",
             :FIRE =>  "Texto al enviar a un Pokémon de Fuego."},
  "item" => "Al usar un objeto.",
  "recall" => "Cuando un Pokémon es llamado a salir del combate.",
  "shadow" => "Sale un Pokémon Oscuro al combate.",
  "caught" => "El pokémon enemigo es capturado.",
  "weather" => {PBWeather::SUNNYDAY => "Día Soleado.",
                PBWeather::RAINDANCE => "Danza Lluvia."},
  "terrain" => {"Electric" => "Campo Eléctrico.", #Los terrenos son Grassy , Electric , Misty y Psiqui
                "Misty"    => "Campo de Niebla."},
  "critical_move" => "Glope Crítico.",
  "low_effective_move" => "No es muy eficaz.",
  "super_effective_move" => "Súper efectivo.",
  "non_effective_move" => "Movimiento ineficaz",
  "neutral_move" => "Movimiento Neutro.",
  "damage_move" => "Movimiento de daño directo.",
  "special_move" => "Movimiento especial.",
  "physical_move" => "Movimiento físico.",
  "status_move(player)" => "Movimiento de estado.",
  "ohko_move" => "Movimiento OHKO" #Incluye cualquier Movimiento que elimine al objetivo de un golpe
}

#-----------------------------------------------------------------------------
# Demo combate múltiple.
#-----------------------------------------------------------------------------
Multy={
  "last" => "No puedo dejar que me derrotes ahora.",
  "lowhp_last(ally)" => "//AN: Resiste //B2N.//ht",
  "end_turn" => {0  =>  ["Este combate solo está empezando.", "No debes confiarte.//t2"]},
  "lowhp_last" => "Mientras tenga uno mi poder es infinito.",
  "critical_move(player)" => "Solo con eso no me ganarás.",
  "low_effective_move(ally)" => "No puedo creer que pensaras ganarme junto a alguien tan débil como //AN",
  "super_effective_move(opp2)" => ["Deberías saberlo //PN.//t2","Junto a //O2N soy invencible."]
}
#-----------------------------------------------------------------------------
# Demo Mid-Battle-Script.
# Esta es una funcionalidad avanzada no apta para novatos.
#-----------------------------------------------------------------------------
MBS={
  "last_bgm" => "Battle! (Champion)",
  "af_last" => proc {|battle,battlers,scene|
    battlers[1].pbIncreaseStat(PBStats::ATTACK,2,battlers[1],false)
    battlers[1].pbIncreaseStat(PBStats::SPATK,2,battlers[1],false)
    battlers[1].pbIncreaseStat(PBStats::SPEED,2,battlers[1],false)
    scene.pbShowOpponent(0,true)
    battle.pbDisplayPaused("Es en momentos duros como este donde #{battlers[1].name} muestra todo su poder.")
    battlers[1].pokemon.setTeratype(:STELLAR)
    scene.pbHideOpponent(true)
    battle.pbTeraCristal(1)},
  "tera" => "¡//B1N, deslumbra a este niñato con tu brillo!"
}
#-----------------------------------------------------------------------------
# Esto quedaría bien para un combate contra Mewtwo.
# Los 2 primeros son necesarios para que funcione bien con Pokémon salvajes.
#-----------------------------------------------------------------------------
MEWTWO={
  "tr_graphic" => "trainer058.png",
  "speaker" => "Giovani",
  "pre_start_turn" => {0  =>  proc {|battle,battlers,scene|
                       battlers[1].item = rand(2) == 0 ? PBItems::MEWTWONITEY : PBItems::MEWTWONITEX #Le da una de sus megapiedras aleatoriamente
}},
  "caught" => ["Nooo.","Un simple niño no puede quitarme a mi obra maestra."],
  "lowhp_last" => "Imposible, el Proyecto Ultimate está a punto de caer.|cry|",
  "mega" => "Hasta ahora nunca has visto todo el poder de la naturaleza.",
  "af_mega(player)(DARK)" => "No lograrás explotar esa debilidad del gran //B1N.",
  "ohko_move(player)" => "¡Pero cómo es algo así posible!"
}
end

#--------------------------------------------------------------------------------
# A patir de aquí no toques nada a no ser que sepas bien lo que estás haciendo.
# Método que devuelve el nombre del entrenador hablante.
#--------------------------------------------------------------------------------
def getSpeaker(text,battle)
  if text.include?(":")
    return text.before(":")
  elsif battle.opponent
    if battle.opponent.is_a?(Array)
      if text.include?("//t2")
        return battle.opponent[1].name
      else
        return battle.opponent[0].name
      end
    else
      return battle.opponent.name
    end
  else
    return battle.mbs["speaker"]
  end
  return ""
end

class PokeBattle_Battle
  attr_reader :mbs
#--------------------------------------------------------------------------------
# Control de Variables.
#--------------------------------------------------------------------------------
  alias initialize_fpd initialize
  def initialize(*args)
    initialize_fpd(*args)
    m = @rules["mbs"] || {}
    if m.is_a?(Symbol)
      if hasConst?(MBS_Data,m)
          d=getConst(MBS_Data,m).dup
          @mbs=d.dup
      else
          raise "Constante de Diálogos no definida. (#{m})"
      end
    elsif m.is_a?(Hash)
      @mbs=m.dup
    elsif m.is_a(String)
      @mbs={};@mbs["last"]=m
    else
      raise "Parámetro de MBS incorrecto, se esperaba un Hash, Symbol o String."
    end
    @mbu=[]
  end

  def fpCheck_mbu(mbu,idx)
    return @mbu.include?(mbu+idx.to_s)
  end

#--------------------------------------------------------------------------------
# Método que muestra los textos. (Aquí es donde ocurre la magia)
#--------------------------------------------------------------------------------
  def fpShowText(key="",mbu="",dtext="")
    return false if !@mbs[key] #Termina la ejecución si el diálogo no está definido
    return false if !dtext #Termina la ejecución si el texto directo es inválido
    return false if @mbu.include?(mbu) #Revisa si se mostró el diálogo antes
    text = (dtext.is_a?(Proc) || dtext.length > 0) ? dtext : @mbs[key] #Revisa si se utilizará el texto directo
    if text.is_a?(Array) #Revisa si es definición simple o en cadena
      @scene.fpShowBars
      it=0 #Index del diálogo actual en la lista
      for i in text #Inicia la ejecución de la lista de Diálogos
        not_show = i.include?("//ht")
        if not_show #Revisa si debe mostrarse el entrenador
          @scene.setDialogColor(i) #Recolorea las letras para este Diálogo
          pbPlayCry(@battlers[1].pokemon) if i.include?("|cry|") #Reproduce el grito del Pokémon rival
          pbDisplayPaused(fpBuffer(i)) #Muestra el diálogo
        else
          bt=i.include?("//bt")
          id  = i.include?("//t2") ? 1 : 0 #Revisa si debe mostrarse el rival 1 o 2
          @scene.setDialogColor(i) #Recolorea las letras para este Diálogo
          @scene.pbShowOpponent(id,true) #Muestra el entrenador
          @scene.pbShowOpponent(@scene.last_showed^1,true,true) if bt
          pbPlayCry(@battlers[1].pokemon) if i.include?("|cry|") #Reproduce el grito del Pokémon rival
          pbDisplayPaused(fpBuffer(i)) #Muestra el diálogo
          nt=text[it+1] #Revisa si hay un próximo Diálogo
          ntid = nt.include?("//t2") ? 1 : 0 if nt #Revisa si se debe mostrar el entrenador 0 o 1
          nbt = nt.include?("//bt") if nt
          @scene.pbHideOpponent(true) if (!nt || nt.include?("//ht") || (@scene.last_showed != ntid)) && !nbt #Oculta el entrenador
          @scene.pbHideOpponent(true) if !nbt && @scene.showed_trainers==[true,true]
        end
        it+=1
      end
      @scene.fpHideBars()
      @scene.pbHideOpponent(true)
    elsif text.is_a?(String)
      @scene.fpShowBars
      if text.include?("//ht")#Revisa si debe mostrarse el entrenador
        @scene.setDialogColor(text) #Recolorea las letras para este Diálogo
        pbPlayCry(@battlers[1].pokemon) if text.include?("|cry|") #Reproduce el grito del Pokémon rival
        pbDisplayPaused(fpBuffer(text)) #Muestra el diálogo
      else
        id = text.include?("//t2") ? 1 : 0 #Revisa si debe mostrarse el rival 1 o 2
        bt = text.include?("//bt")#Revisa si deben ambos rivales
        @scene.setDialogColor(text) #Recolorea las letras para este Diálogo
        @scene.pbShowOpponent(id,true) #Muestra el entrenador
        @scene.pbShowOpponent(@scene.last_showed^1,true,true) if bt
        pbPlayCry(@battlers[1].pokemon) if text.include?("|cry|") #Reproduce el grito del Pokémon rival
        pbDisplayPaused(fpBuffer(text)) #Muestra el diálogo
        @scene.pbHideOpponent(true) #Oculta el entrenador
      end
      @scene.fpHideBars
    elsif text.is_a?(Proc)
      text.call(self,@battlers,@scene) #Ejecuta el Mid-Battle-Script
  	else
	    raise "Tipo de dato MBS incorrecto, se esperaba Array, String o Proc. (Clave: #{key})"
    end
    @scene.setDialogColor("") #Reestablece los colores de las letras a la normalidad
    PBDebug.log("Díalogo Mostrado: #{text}")
    @mbu.push(mbu) if mbu!="" #Añade el diálogo a la lista de los mostrados
  	return true
  end

#--------------------------------------------------------------------------------
# Devuelve la clave completa del diálogo.
#--------------------------------------------------------------------------------
  def getKey(base,idx)
    case idx
    when 0
      return base+"(player)" #Jugador
    when 1
      return base #Oponente
    when 2
      return @player.is_a?(Array) ? base + "(ally)" : base + "(player)" #Aliado
    when 3
      return @opponent && @opponent.is_a?(Array) ? base + "(opp2)" : base #Oponente 2
    end
  end

#--------------------------------------------------------------------------------
# Chequeos adicionales para Diálogos Específicos. (Experimental)
#--------------------------------------------------------------------------------
  def fpXtraChecks(battler,key,xtra=nil)
    r=0
    if ["faint","send"].include?(key)
      if @mbs[key]
        r+=1 if fpShowText(key,key+battler.index.to_s+"mega",key["mega"]) if battler.isMega?
        r+=1 if fpShowText(key,key+battler.index.to_s+"tera",key["tera"]) if battler.isTera?
        r+=1 if fpShowText(key,key+battler.index.to_s+"ultra",key["ultra"]) if battler.isUltra?
        r+=1 if fpShowText(key,key+battler.index.to_s+"shiny",key["shiny"]) if battler.isShiny?
        r+=1 if fpShowText(key,key+battler.index.to_s+"shadow",key["shadow"]) if battler.isShadow?
        t=pbGetTypeConst(battler.type1).to_sym
        p=pbGetTypeConst(battler.type2).to_sym
        r+=1 if fpShowText(key,key+battler.index.to_s+t.to_s,key[t])
        r+=1 if fpShowText(key,key+battler.index.to_s+p.to_s,key[p])
      end
    elsif ["mega","primal","ultra","shiny","shadow","recall"].include_some?(key)
      t=pbGetTypeConst(battler.type1)
      p=pbGetTypeConst(battler.type2)
      r+=1 if fpShowText(key+"(#{t})",key+battler.index.to_s+t)
      r+=1 if fpShowText(key+"(#{p})",key+battler.index.to_s+p)
      r+=1 if fpShowText(key+"(shadow)",key+battler.index.to_s+"shadow") if battler.isShadow?
      r+=1 if fpShowText(key+"(shiny)",key+battler.index.to_s+"shiny") if battler.isShiny?
      r+=1 if fpShowText(key+"(mega)",key+battler.index.to_s+"mega") if battler.isMega?
      r+=1 if fpShowText(key+"(primal)",key+battler.index.to_s+"primal") if battler.isPrimal?
      r+=1 if fpShowText(key+"(ultra)",key+battler.index.to_s+"ultra") if battler.isUltra?
      r+=1 if fpShowText(key+"(tera)",key+battler.index.to_s+"tera") if battler.isTera?
    elsif key.include?("tera")
      t=pbGetTypeConst(battler.pokemon.teratype)
      r+=1 if fpShowText(key+"(#{t})",key+battler.index.to_s+t)
      r+=1 if fpShowText(key+"(shiny)",key+battler.index.to_s+"shiny") if battler.isShiny?
    elsif key.include?("move")
      t = pbGetTypeConst(xtra.type)
      r+=1 if fpShowText(key+"(#{t})",key+battler.index.to_s+t)
    end
  	return r>0
  end

#--------------------------------------------------------------------------------
# Control de claves adicional necesario para los combates múltiples.
#--------------------------------------------------------------------------------
  def fpDialog(key,idx,mbu="",dtext="",xtra=nil)
    key = getKey(key,idx)
    unless fpXtraChecks(@battlers[idx],key,xtra)
      fpShowText(key,mbu,dtext)
   	end
  end

#--------------------------------------------------------------------------------
# Método que controla los buffers.
#--------------------------------------------------------------------------------
  def fpBuffer(str)
    nstr=str.dup
    nstr.gsub!("//PN",$Trainer.name) #Nombre de PLAYER
    nstr.gsub!("//ON",@opponent.name) if @opponent && !@opponent.is_a?(Array) #Nombre del rival
    nstr.gsub!("//ON",@opponent[0].name) if @opponent && @opponent.is_a?(Array) #Nombre del rival
    nstr.gsub!("//O2N",@opponent[1].name) if @opponent && @opponent.is_a?(Array)#Nombre del rival 2
    nstr.gsub!("//AN",@player[1].name) if @player.is_a?(Array) #Nombre del aliado
    nstr.gsub!("//ht","") #Elimina la marca de no mostrar el entrenador
    nstr.gsub!("|cry|","") #Elimina la marca del grito
  	nstr.gsub!("//t2","") #Elimina la marca de mostrar el entrenador 2
    nstr.gsub!("//bt","") #Elimina la marca de mostrar ambos entrenadores
    for i in 0...4
      nstr.gsub!("//B#{i}N",@battlers[i].name) #Nombre del Battler X
      nstr.gsub!("//T1B#{i}N",PBTypes.getName(@battlers[i].type1)) #Nombre del tipo 1 del Battler X
    end
	  return nstr
  end

#------------------------------------------------------------------------------------------
#Para el último Pokémon , los Pokémon específicos y los Pokémon Oscuros del jugador.
#------------------------------------------------------------------------------------------
  def pbSendOut(index,pokemon)
    pbSetSeen(pokemon)
    @peer.pbOnEnteringBattle(self,pokemon)
    lp = @doublebattle && !@opponent.is_a?(Array) ? 2 : 1
    if pbPokemonCount(pbParty(index)) <=lp
      if index % 2 == 0
        if $Trainer.party.length > 1
          fpDialog("last",index)
        else
          fpDialog("one_poke",index)
        end
      else
	      fpDialog("last",index)
        l = @mbs["last_bgm"]
        path = l.is_a?(String) ? l : MBS_Data::DEFAULTLASTBGM
        pbBGMPlay(path,100,100) if l
      end
    end
    if pbIsOpposing?(index)
      @scene.pbTrainerSendOut(index,pokemon)
      if (pbPokemonCount(@party2) > 1 || !@mbs["last"]) && @mbs["send"]
        fpShowText("send","opp#{pokemon.name}",@mbs["send"][pbGetSpeciesConst(pokemon.species)])
      end
    else
      @scene.pbSendOut(index,pokemon)
      fpDialog("shadow",index,"shp") if pokemon.isShadow?
    end
    fpDialog("af_last",index,"afl#{index}") if pbPokemonCount(pbParty(index))==1
    @scene.pbResetMoveIndex(index)
  end

#--------------------------------------------------------------------------------
#Para la Regresión Primigenia.
#--------------------------------------------------------------------------------
  def pbPrimalReversion(index)
    return if !@battlers[index] || !@battlers[index].pokemon
    return if !@battlers[index].hasPrimal?
    return if @battlers[index].isPrimal?
    fpDialog("primal",index,"pr")
  	pbCommonAnimation("Primal#{PBSpecies.getName(@battlers[index].species)}",@battlers[index],nil)
    @battlers[index].pokemon.makePrimal
    @battlers[index].form=@battlers[index].pokemon.form
    @battlers[index].pbUpdate(true)
    @scene.pbChangePokemon(@battlers[index],@battlers[index].pokemon)
    pbCommonAnimation("Primal#{PBSpecies.getName(@battlers[index].species)}2",@battlers[index],nil)
    pbDisplay(_INTL("¡{1} ha esperimentado una Regresión Primigenia y ha recobrado su apariencia primitiva!",@battlers[index].pbThis))
    fpDialog("af_primal",index,"apr")
    PBDebug.log("[Regresión Primigenia] #{@battlers[index].pbThis} ha recobrado su apariencia primitiva")
  end

#--------------------------------------------------------------------------------
#Para la Megaevolución.
#--------------------------------------------------------------------------------
  def pbMegaEvolve(index)
    return if !@battlers[index] || !@battlers[index].pokemon
    return if !@battlers[index].hasMega?
    return if @battlers[index].isMega?
    fpDialog("mega",index)
    if !pbGetOwner(index)
      case (@battlers[index].pokemon.megaMessage rescue 0)
      when 1 # Rayquaza
        pbDisplay(_INTL("¡El ruego vehemente alcanza a {1}!",@battlers[index].pbThis))
      else
        pbDisplay(_INTL("¡La {2} de {1} está reaccionando su poder interior!",
           @battlers[index].pbThis,PBItems.getName(@battlers[index].item)))
      end
    else
      ownername=pbGetOwner(index).fullname
      ownername=pbGetOwner(index).name if pbBelongsToPlayer?(index)
      case (@battlers[index].pokemon.megaMessage rescue 0)
      when 1                                                           # Rayquaza
        pbDisplay(_INTL("¡El ruego vehemente de {1} alcanza a {2}!",ownername,@battlers[index].pbThis))
      else
        pbDisplay(_INTL("¡La {2} de {1} está reaccionando al {4} de {3}!",
           @battlers[index].pbThis,PBItems.getName(@battlers[index].item),
           ownername,pbGetMegaRingName(index)))
      end
    end
    pbCommonAnimation("MegaEvolution",@battlers[index],nil)
    @battlers[index].pokemon.makeMega
    @battlers[index].form=@battlers[index].pokemon.form
    @battlers[index].pbUpdate(true)
    @scene.pbChangePokemon(@battlers[index],@battlers[index].pokemon)
    pbCommonAnimation("MegaEvolution2",@battlers[index],nil)
    meganame=(@battlers[index].pokemon.megaName rescue nil)
    if !meganame || meganame == ""
      meganame=_INTL("Mega {1}",PBSpecies.getName(@battlers[index].pokemon.species))
    end
    pbDisplay(_INTL("¡{1} ha Mega Evolucionado en {2}!",@battlers[index].pbThis,meganame))
    PBDebug.log("[Mega Evolución] #{@battlers[index].pbThis} ha Mega Evolucionado")
    fpDialog("af_mega",index)
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @megaEvolution[side][owner] =- 2
  end

#--------------------------------------------------------------------------------
# Para la Ultraexplosión.
#--------------------------------------------------------------------------------
  def pbUltraBurst(index)
    return if !@battlers[index] || !@battlers[index].pokemon
    return if !@battlers[index].hasUltra?
    return if @battlers[index].isUltra?
    @necrozmaVar = [@battlers[index].pokemonIndex,@battlers[index].form] if pbBelongsToPlayer?(index)
    ownername=pbGetOwner(index).fullname
    ownername=pbGetOwner(index).name if pbBelongsToPlayer?(index)
    fpDialog("ultra",index)
    pbDisplay(_INTL("¡{1} emite una luz cegadora!",@battlers[index].pbThis))
    pbCommonAnimation("UltraBurst",@battlers[index],nil)
    @battlers[index].pokemon.makeUltra
    @battlers[index].form=@battlers[index].pokemon.form
    @battlers[index].pbUpdate(true)
    @scene.pbChangePokemon(@battlers[index],@battlers[index].pokemon)
    pbCommonAnimation("UltraBurst2",@battlers[index],nil)
    ultraname=(@battlers[index].pokemon.ultraName rescue nil)
    if !ultraname || ultraname == ""
      ultraname=_INTL("Ultra {1}",PBSpecies.getName(@battlers[index].pokemon.species))
    end
    pbDisplay(_INTL("¡{1} ha adoptado una nueva forma gracias a la Ultraexplosión!",@battlers[index].pbThis))
    fpDialog("af_ultra",index)
    PBDebug.log("[Ultra Burst] #{@battlers[index].pbThis} became #{ultraname}")
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @ultraBurst[side][owner] =- 2
  end

#--------------------------------------------------------------------------------
# Para la Teracristalización.
#--------------------------------------------------------------------------------
  def pbTeraCristal(index)
    teratype=@battlers[index].pokemon.teratype
    return if !@battlers[index] || !@battlers[index].pokemon
    return if @battlers[index].isTera?
    fpDialog("tera",index)
    pbDisplay(_INTL("¡{1} se está rodeando de cristal!",@battlers[index].pbThis))
    pbCommonAnimation("MegaEvolution",@battlers[index],nil)
    @battlers[index].pokemon.original_types=[@battlers[index].type1,@battlers[index].type2]
    @battlers[index].pokemon.makeTera
    @battlers[index].pbUpdate(true)
    @scene.pbChangePokemon(@battlers[index],@battlers[index].pokemon)
    pbCommonAnimation("MegaEvolution2",@battlers[index],nil)
    typename=PBTypes.getName(teratype)
    pbDisplay(_INTL("¡{1} ha Teracristalizado al tipo {2}!",@battlers[index].pbThis,typename))
    fpDialog("af_tera",index)
    PBDebug.log("[Teracristalización] #{@battlers[index].pbThis} ha Teracristalizado (#{typename})")
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @teraCristal[side][owner]=-2
    $PokemonGlobal.teraorb[0]-=1
  end

#--------------------------------------------------------------------------------
# Para los Movimientos Z.
#--------------------------------------------------------------------------------
  def pbUseZMove(index,move,crystal)
    return if !@battlers[index] || !@battlers[index].pokemon
    return if !@battlers[index].hasZMove?
    ownername=pbGetOwner(index).fullname
    ownername=pbGetOwner(index).name if pbBelongsToPlayer?(index)
    fpDialog("z_move",index,"","",move)
    pbDisplay(_INTL("¡{1} se envuelve en un halo de Poder Z!",@battlers[index].pbThis))
    pbCommonAnimation("ZPower",@battlers[index],nil)
    PokeBattle_ZMoves.new(self,@battlers[index],move,crystal)
    fpDialog("af_z_move",index,"","",move)
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @zMove[side][owner]=-2
  end

#--------------------------------------------------------------------------------
# Para los objetos.
#--------------------------------------------------------------------------------
  alias pbEnemyUseItem_fp pbEnemyUseItem
  def pbEnemyUseItem(*args) #Entrenadores controlados por la IA
    idx = args[1].index
    fpDialog("item",idx,"i"+idx.to_s)
    pbEnemyUseItem_fp(*args)
  end

  alias pbRegisterItem_fp pbRegisterItem
  def pbRegisterItem(*args) #Jugador
    ret = pbRegisterItem_fp(*args)
    fpShowText("item(player)","ip")
	return ret
  end

#--------------------------------------------------------------------------------
# Para los Preinicios de turno.
#--------------------------------------------------------------------------------
  alias pbCommandPhase_fp pbCommandPhase
  def pbCommandPhase
    fpShowText("pre_start_turn","ps#{@turncount}",@mbs["pre_start_turn"][@turncount]) if @mbs["pre_start_turn"]
    pbCommandPhase_fp
  end

#--------------------------------------------------------------------------------
# Para los inicios de turno.
#--------------------------------------------------------------------------------
alias pbAttackPhase_fp pbAttackPhase
def pbAttackPhase
  fpShowText("start_turn","start#{@turncount}",@mbs["start_turn"][@turncount]) if @mbs["start_turn"]
  pbAttackPhase_fp
end

#--------------------------------------------------------------------------------
# Para los finales de turno y pocos PS en el último Pokémon.
#--------------------------------------------------------------------------------
  alias pbEndOfRoundPhase_fp pbEndOfRoundPhase
  def pbEndOfRoundPhase
    for i in 0...4
      fpDialog("lowhp_last",i,"ll#{i}") if pbPokemonCount(pbParty(i))==1 && @battlers[i].totalhp/2 >= @battlers[i].hp && !@battlers[i].isFainted?
    end
    fpShowText("end_turn","e#{@turncount}",@mbs["end_turn"][@turncount]) if @mbs["end_turn"]
    pbEndOfRoundPhase_fp
  end

#--------------------------------------------------------------------------------
# Para los climas.
#--------------------------------------------------------------------------------
  def weather=(v)
    @weather=v
    fpShowText("weather","weather#{v}",@mbs["weather"][v]) if @mbs["weather"]
  end

#--------------------------------------------------------------------------------
# Para los cambios.
#--------------------------------------------------------------------------------
  def pbRecallAndReplace(index,newpoke,newpokename=-1,batonpass=false,moldbreaker=false)
    @battlers[index].pbResetForm
    if !@battlers[index].isFainted?
      fpDialog("recall",index,"r#{index}")
      @scene.pbRecall(index)
      fpDialog("af_recall",index,"ar#{index}")
    end
    pbMessagesOnReplace(index,newpoke,newpokename)
    pbReplace(index,newpoke,batonpass)
    return pbOnActiveOne(@battlers[index],false,moldbreaker)
  end
end

#--------------------------------------------------------------------------------
# Para los Pokémon capturados.
#--------------------------------------------------------------------------------
module PokeBattle_BattleCommon
  alias pbStorePokemon_fp pbStorePokemon
  def pbStorePokemon(poke)
    fpShowText("caught","c")
    pbStorePokemon_fp(poke)
  end
end

#--------------------------------------------------------------------------------
# Para los Pokémon debilitados.
#--------------------------------------------------------------------------------
class PokeBattle_Battler
  alias pbFaint_fp pbFaint
  def pbFaint(*args)
    k = @battle.getKey("faint",@index)
    s = pbGetSpeciesConst(@pokemon.species).to_sym
    @battle.fpDialog("faint",@index,"ft#{@battle.pbGetOwner(@index).name}#{s}",@battle.mbs[k][s]) if @battle.mbs[k]
    pbFaint_fp(*args)
    @battle.fpDialog("af_faint",@index,"aft#{@battle.pbGetOwner(@index).name}#{s}",@battle.mbs["af_"+k][s]) if @battle.mbs["af_"+k]
  end

#--------------------------------------------------------------------------------
# Para los Campos. (Habilidad)
#--------------------------------------------------------------------------------
  alias pbAbilitiesOnSwitchIn_fp pbAbilitiesOnSwitchIn
  def pbAbilitiesOnSwitchIn(*args)
    pbAbilitiesOnSwitchIn_fp(*args)
    if @battle.mbs["terrain"]
      if hasWorkingAbility(:ELECTRICSURGE) || self.hasWorkingAbility(:HADRONENGINE) && @battle.effects[PBEffects::ElectricTerrain]>=5
        @battle.fpShowText("terrain","terrain_elect",@battle.tts["terrain"]["Electric"]) #Eléctrico
      elsif hasWorkingAbility(:PSYCHICSURGE)
        @battle.fpShowText("terrain","terrain_psyqu",@battle.tts["terrain"]["Psiqui"])   #Psíquico
      elsif hasWorkingAbility(:GRASSYSURGE)
        @battle.fpShowText("terrain","terrain_grass",@battle.tts["terrain"]["Grassy"])   #Hierba
      elsif hasWorkingAbility(:MISTYSURGE)
        @battle.fpShowText("terrain","terrain_misty",@battle.tts["terrain"]["Misty"])    #Niebla
      end
    end
  end
end

#--------------------------------------------------------------------------------
# Para los Campos. (Movimientos)
#--------------------------------------------------------------------------------
class PokeBattle_Move_154
  alias pbEffect_fp pbEffect
  def pbEffect(*args)
    ret = pbEffect_fp(*args)
    @battle.fpShowText("terrain","terrain_elect",@battle.tts["terrain"]["Electric"]) if ret == 0 && @battle.mbs["terrain"] #Eléctrico
  end
end

class PokeBattle_Move_155
  alias pbEffect_fp pbEffect
  def pbEffect(*args)
    ret = pbEffect_fp(*args)
    @battle.fpShowText("terrain","terrain_grass",@battle.tts["terrain"]["Grassy"]) if ret == 0 && @battle.mbs["terrain"] #Hierba
  end
end

class PokeBattle_Move_156
  alias pbEffect_fp pbEffect
  def pbEffect(*args)
    ret = pbEffect_fp(*args)
    @battle.fpShowText("terrain","terrain_misty",@battle.tts["terrain"]["Misty"]) if ret == 0 && @battle.mbs["terrain"] #Niebla
  end
end

class PokeBattle_Move_157
  alias pbEffect_fp pbEffect
  def pbEffect(*args)
    ret = pbEffect_fp(*args)
    @battle.fpShowText("terrain","terrain_psyqu",@battle.tts["terrain"]["Psiqui"]) if ret == 0 && @battle.mbs["terrain"] #Psíquico
  end
end
#--------------------------------------------------------------------------------
# Para los golpes Super-Efectivos, Poco-Efectivos, Críticos, etc....
#--------------------------------------------------------------------------------
class PokeBattle_Move
  def pbEffectMessages(attacker,opponent,ignoretype=false,alltargets=nil)
    if opponent.damagestate.critical
      if alltargets && alltargets.length>1
        @battle.pbDisplay(_INTL("¡Es un golpe crítico en {1}!",opponent.pbThis(true)))
      else
        @battle.pbDisplay(_INTL("¡Es un golpe crítico!"))
      end
      @battle.fpDialog("critical_move",attacker.index,"cm#{attacker.index}","",self)
    end
    if !pbIsMultiHit && attacker.effects[PBEffects::ParentalBond]==0
      if opponent.damagestate.typemod>8
        if alltargets && alltargets.length>1
          @battle.pbDisplay(_INTL("¡Es super efectivo en {1}!",opponent.pbThis(true)))
        else
          @battle.pbDisplay(_INTL("¡Es super efectivo!"))
        end
        @battle.fpDialog("super_effective_move",attacker.index,"sem#{attacker.index}","",self)
      elsif opponent.damagestate.typemod>=1 && opponent.damagestate.typemod<8
        if alltargets && alltargets.length>1
          @battle.pbDisplay(_INTL("No es muy efectivo en {1}...",opponent.pbThis(true)))
        else
          @battle.pbDisplay(_INTL("No es muy efectivo..."))
        end
        @battle.fpDialog("low_effective_move",attacker.index,"lem#{attacker.index}","",self)
      elsif opponent.damagestate.typemod == 8
        @battle.fpDialog("neutral_move",attacker.index,"nm#{attacker.index}","",self)
      end
    end
	if pbIsDamaging? && !@battle.fpCheck_mbu("dam",attacker.index)
	  @battle.fpDialog("damage_move",attacker.index,"dam#{attacker.index}","",self)
    elsif pbIsSpecial?(0)
      @battle.fpDialog("special_move",attacker.index,"sm#{attacker.index}","",self)
    elsif pbIsPhysical?(0)
      @battle.fpDialog("physical_move",attacker.index,"pm#{attacker.index}","",self)
    else
      @battle.fpDialog("status_move",attacker.index,"stm#{attacker.index}","",self)
    end
    if opponent.damagestate.endured
      @battle.pbDisplay(_INTL("¡{1} aguantó el golpe!",opponent.pbThis))
    elsif opponent.damagestate.sturdy
      @battle.pbDisplay(_INTL("¡{1} resistió con Robustez!",opponent.pbThis))
    elsif opponent.damagestate.focussash
      @battle.pbDisplay(_INTL("¡{1} resistió usando Banda Focus!",opponent.pbThis))
      opponent.pbConsumeItem
    elsif opponent.damagestate.focusband
      @battle.pbDisplay(_INTL("¡{1} resistió usando Cinta Focus!",opponent.pbThis))
    end
  	if opponent.damagestate.calcdamage == opponent.totalhp
	    @battle.fpDialog("ohko_move",attacker.index,"ohm#{attacker.index}","",self)
	  end
  end

#--------------------------------------------------------------------------------
# Para los golpes Ineficaces.
#--------------------------------------------------------------------------------
  def pbTypeModMessages(type,attacker,opponent)
    return 8 if type<0
    typemod=pbTypeModifier(type,attacker,opponent)
    if typemod==0
      @battle.pbDisplay(_INTL("No afecta a {1}...",opponent.pbThis(true)))
    else
      typemod = 0 if pbTypeImmunityByAbility(type,attacker,opponent)
    end
    if typemod==0
      @battle.fpDialog("non_effective_move",attacker.index,"nem#{attacker.index}","",self)
    end
    return typemod
  end
end

#--------------------------------------------------------------------------------
# Para los Pokémon Shiny y Oscuros.
#--------------------------------------------------------------------------------
class PokeBattle_Scene
  alias pbCommonAnimation_fp pbCommonAnimation
  def pbCommonAnimation(*args)
    pbCommonAnimation_fp(*args)
	  name=args[0] ; attacker=args[1]
    case name
    when "Shadow"
      @battle.fpDialog("shadow",attacker.index,"sh#{attacker.index}")
    when "Shiny"
      @battle.fpDialog("shiny",attacker.index,"shi#{attacker.index}")
    end
  end

#--------------------------------------------------------------------------------
#Setea el color de las letras.
#--------------------------------------------------------------------------------
  def setDialogColor(text)
	  name=getSpeaker(text,@battle)
    msgwindow=@sprites["messagewindow"]
    for i in MBS_Data::NONENGLISCHARACTERS.keys
      if name.include?(i)
        name = MBS_Data::NONENGLISCHARACTERS[i]
      end
    end
    if MBS_Data::CHARACTERS_COLORS.include?(name) && text.length>0
      msgwindow.baseColor=MBS_Data::CHARACTERS_COLORS[name][0]
      msgwindow.shadowColor=MBS_Data::CHARACTERS_COLORS[name][1]
    else
      msgwindow.baseColor=PokeBattle_SceneConstants::MESSAGEBASECOLOR
      msgwindow.shadowColor=PokeBattle_SceneConstants::MESSAGESHADOWCOLOR
    end
  end

#--------------------------------------------------------------------------------
# Modificaciones necesarias a los métodos que ocultan y muestran al entrenador.
#--------------------------------------------------------------------------------
  attr_reader :showed_trainers
  attr_reader :last_showed

  alias initialize_fp initialize
  def initialize(*args)
    initialize_fp(*args)
    @showed_trainers = [false,false]
    @last_showed=-1
  end


  def fpShowBars()
    barscolor = @battle.mbs["barscolor"] || Color.new(0,0,0)
    b2y = MBS_Data::COLORBARSTYLE==2 ? Graphics.height-96 : Graphics.height-124
    b2h = MBS_Data::COLORBARSTYLE==2 ? 96 : 28
    @sprites["black_bar1"]=Sprite.new(@viewport);@sprites["black_bar1"].fill(barscolor,Graphics.width,16)
    @sprites["black_bar2"]=Sprite.new(@viewport);@sprites["black_bar2"].fill(barscolor,Graphics.width,b2h)
    @sprites["black_bar1"].x=Graphics.width;@sprites["black_bar2"].x=Graphics.width*-1;@sprites["black_bar2"].y=b2y
    @sprites["black_bar1"].z=8
    @sprites["black_bar2"].z=90
    20.times do
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      @sprites["black_bar1"].x-=25.6
      @sprites["black_bar2"].x+=25.6
    end
  end

  def fpHideBars
    10.times do
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      @sprites["black_bar1"].opacity -= 25.5
      @sprites["black_bar2"].opacity -= 25.5
    end
  end

  def pbShowOpponent(index,mbs=false,d=false)
    return if @showed_trainers[index]
    @showed_trainers[index]=true
    @last_showed=index
    if @battle.opponent
      if @battle.opponent.is_a?(Array)
        trainerfile=pbTrainerSpriteFile(@battle.opponent[index].trainertype)
      else
        trainerfile=pbTrainerSpriteFile(@battle.opponent.trainertype)
      end
    else
      trainerfile = "Graphics/Battlers/Trainers/"+@battle.mbs["tr_graphic"]
    end
    if @sprites["trainer"] && @sprites["trainer"].x < Graphics.width
      pbAddSprite("trainer2",Graphics.width+40,PokeBattle_SceneConstants::FOETRAINER_Y,trainerfile,@viewport)
      xtra="2"
    else
      pbAddSprite("trainer",Graphics.width,PokeBattle_SceneConstants::FOETRAINER_Y,trainerfile,@viewport)
      xtra=""
    end
    if @sprites["trainer"+xtra].bitmap
      @sprites["trainer"+xtra].y -= @sprites["trainer"].bitmap.height
      @sprites["trainer"+xtra].z = 8
      @sprites["trainer"+xtra].visible = true
    end
    pbSEPlay(MBS_Data::SHOWSE) if MBS_Data::SHOWSE.length>0 && mbs
    20.times do
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      @sprites["trainer"+xtra].x-=6
      @sprites["trainer"+xtra].x-=3 if mbs
      for i in 0...4
        @sprites["pokemon#{i}"].opacity -= @battle.doublebattle ? 10 : 7 if @sprites["pokemon#{i}"] && i % 2==1 && mbs && !d
      end
    end
  end

  def pbHideOpponent(mbs=false)
    @showed_trainers=[false,false]
    @last_showed=-1
    20.times do
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      @sprites["trainer"].x += 6
      @sprites["trainer"].x += 3 if mbs
      @sprites["trainer2"].x += 9 if @sprites["trainer2"]
      for i in 0...4
	      o = @sprites["pokemon#{i}"].opacity if @sprites["pokemon#{i}"]
        @sprites["pokemon#{i}"].opacity += @battle.doublebattle ? 24 : 14 if @sprites["pokemon#{i}"] && (i % 2==1) && o>0 && mbs
      end
    end
  end
end

#--------------------------------------------------------------------------------
#Métodos Auxiliares.
#--------------------------------------------------------------------------------
class String
  def before(t)
    z=0
    r = ""
    for i in self.scan(/./)
      break if i == t
      r.insert(z,i)
      z += 1
    end
    return r
  end
end

class Array
  def all_is_a?(type)
    for i in self
      return false if !i.is_a?(type)
    end
    return true
  end

  def some_include?(something)
    for i in self
      if i.include?(something)
        return true
      end
    end
    return false
  end

  def include_some?(something)
    for i in self
      if something.include?(i)
        return true
      end
    end
    return false
  end
end

class ::Sprite
  def fill(color,width,height)
    self.bitmap = Bitmap.new(width,height)
    self.bitmap.fill_rect(0,0,width,height,color)
  end
end

def mbsVersion
  return 4.2
end