###############################################################
#               Pokémon compañero inserparable                #
#                      Autor : Bezier                         #
###############################################################
# Este código permite guardar un ID personal de un pokémon y  #
# evitar que sea liberado o dejado en el PC.                  #
#                                                             # 
# En un evento se deberá poner un código similar a este para  #
# poder guardar el ID personal del Pokémon entregado:         #
###############################################################
=begin
# Código de evento que entrega un Pokémon y guarda su ID Personal

poke=PokeBattle_Pokemon.new(:PIKACHU,6,$Trainer)
pbAddPokemon(poke)
$Trainer.partnerID=poke.personalID

=end

class PokeBattle_Trainer
  attr_accessor(:partnerID)
end

class PokemonStorageScreen

  def pbRelease(selected,heldpoke)
    box=selected[0]
    index=selected[1]
    pokemon=(heldpoke)?heldpoke:@storage[box,index]
    return if !pokemon

    # Comprueba el ID personal del Pokémon compañero
    if pokemon.personalID==$Trainer.partnerID
      if pokemon.genderflag==0
        pbDisplay(_INTL("No puedes soltar a tu compañero."))
      else
        pbDisplay(_INTL("No puedes soltar a tu compañera."))
      end
      return false
    end

    if pokemon.isEgg?
      pbDisplay(_INTL("No puedes soltar un Huevo."))
      return false
    elsif pokemon.mail
      pbDisplay(_INTL("Primero se debe quitar la Carta."))
      return false
    end
    if box==-1 && pbAbleCount<=1 && pbAble?(pokemon) && !heldpoke
      pbDisplay(_INTL("¡Ése es tu último Pokémon!"))
      return
    end
    command=pbShowCommands(_INTL("¿Soltar a este Pokémon?"),[_INTL("No"),_INTL("Sí")])
    if command==1
      pkmnname=pokemon.name
      @scene.pbRelease(selected,heldpoke)
      if heldpoke
        @heldpkmn=nil
      else
        @storage.pbDelete(box,index)
      end
      @scene.pbRefresh
      pbDisplay(_INTL("Soltaste a {1}.",pkmnname))
      pbDisplay(_INTL("¡Adiós, {1}!",pkmnname))
      @scene.pbRefresh
    end
    return
  end

  def pbStore(selected,heldpoke)
    box=selected[0]
    index=selected[1]
    if box!=-1 && $Trainer.playerClass == :ENTRENADORA
      raise _INTL("No se puede dejar desde la Caja...")
    end

    pokemon=heldpoke ? heldpoke : @storage[box,index]
    return if !pokemon

    if pokemon.personalID==$Trainer.partnerID && $Trainer.playerClass == :ENTRENADORA
      if pokemon.genderflag==0
        pbDisplay(_INTL("No puedes dejar a tu compañero."))
      else
        pbDisplay(_INTL("No puedes dejar a tu compañera."))
      end
      return false
    end

    if pbAbleCount<=1 && pbAble?(@storage[box,index]) && !heldpoke
      pbDisplay(_INTL("¡Ése es tu último Pokémon!"))
    elsif @storage[box,index].mail
      pbDisplay(_INTL("Primero se debe quitar la Carta."))
    else
      loop do
        destbox=@scene.pbChooseBox(_INTL("¿En qué Caja dejarlo?"))
        if destbox>=0
          success=false
          firstfree=@storage.pbFirstFreePos(destbox)
          if firstfree<0
            pbDisplay(_INTL("La Caja está llena."))
            next
          end
          @scene.pbStore(selected,heldpoke,destbox,firstfree)
          if heldpoke
            @storage.pbMoveCaughtToBox(heldpoke,destbox)
            @heldpkmn=nil
          else
            @storage.pbMove(destbox,-1,-1,index)
          end
        end
        break
      end
      @scene.pbRefresh
    end
  end

  def pbSwap(selected)
    box=selected[0]
    index=selected[1]

    if box>=0 && @heldpkmn.personalID==$Trainer.partnerID && $Trainer.playerClass == :ENTRENADORA
      if @heldpkmn.genderflag==0
        pbDisplay(_INTL("No puedes dejar a tu compañero."))
      else
        pbDisplay(_INTL("No puedes dejar a tu compañera."))
      end
      return false
    end
    
    if !@storage[box,index]
      raise _INTL("Posición {1},{2} está vacía...",box,index)
    end
    if box==-1 && pbAble?(@storage[box,index]) && pbAbleCount<=1 && !pbAble?(@heldpkmn)
      pbDisplay(_INTL("¡Ése es tu último Pokémon!"))
      return false
    end
    if box!=-1 && @heldpkmn.mail
      pbDisplay("Primero se debe quitar la Carta.")
      return false
    end
    @scene.pbSwap(selected,@heldpkmn)
    if box>=0
      @heldpkmn.heal
      @heldpkmn.formTime=nil if @heldpkmn.respond_to?("formTime") && @heldpkmn.formTime
    end
    tmp=@storage[box,index]
    @storage[box,index]=@heldpkmn
    @heldpkmn=tmp
    @scene.pbRefresh
    return true
  end

  def pbPlace(selected)
    box=selected[0]
    index=selected[1]

    if box>=0 && @heldpkmn.personalID==$Trainer.partnerID && $Trainer.playerClass == :ENTRENADORA
      if @heldpkmn.genderflag==0
        pbDisplay(_INTL("No puedes dejar a tu compañero."))
      else
        pbDisplay(_INTL("No puedes dejar a tu compañera."))
      end
      return false
    end

    if @storage[box,index]
      raise _INTL("Posición {1},{2} no está vacía...",box,index)
    end
    if box!=-1 && index>=@storage.maxPokemon(box)
      pbDisplay("No se puede colocar ahí.")
      return
    end
    if box!=-1 && @heldpkmn.mail
      pbDisplay("Primero se debe quitar la Carta.")
      return
    end
    if box>=0
      @heldpkmn.heal
      @heldpkmn.formTime=nil if @heldpkmn.respond_to?("formTime") && @heldpkmn.formTime
    end
    @scene.pbPlace(selected,@heldpkmn)
    @storage[box,index]=@heldpkmn
    if box==-1
      @storage.party.compact!
    end
    @scene.pbRefresh
    @heldpkmn=nil
  end

end