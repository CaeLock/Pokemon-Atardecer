#==============================================================================
# Script de "Tienda" de movimientos, para hacer los tutores mas sencillos de manejar.
# Creado por Clara.
# Para usarlo hay que llamar al script pbTutorMoves y añadir un array con los movimientos y el precio deseado.
# Ejemplo:
#     pbTutorMoves([[:SWIFT,2000],[:PLUCK,5000]])
#==============================================================================
def pbTutorMoves(moves)
  if !Kernel.pbConfirmMessage(_INTL("\\g¿Quieres que tus Pokémon aprendan algún movimiento?"))
    return false
  end
  loop do
    moveID=0
    choices=[]
    price=0
    move=0
    ret = false
    for i in 0..moves.length
      move=moves[i]
      if move && move[0] && move[0]!=0
        moveID=getConst(PBMoves,move[0])
        movename=PBMoves.getName(moveID)
        price=move[1]
        choices.push(_ISPRINTF(_INTL("${2:d} - {1:s}"),movename,price))
      end
    end
    choices.push(_INTL("Salir"))
    command=Kernel.pbMessage(_INTL("\\g¿Qué movimiento debería enseñarle a tu Pokémon?"),choices,-1)
    cmd=command
    if cmd == choices.length-1
      break
    elsif cmd!=-1
      move=moves[cmd]
      choosenprice=move[1]
      if move && move[0] && move[0]!=0
        choosenMove=move[0]
        choosenMovename=PBMoves.getName(getConst(PBMoves,move[0]))
        ret = true
      else
        break
      end
    else
      break
    end
    if ret
      if $Trainer.money<choosenprice
        Kernel.pbMessage(_INTL("\\g¡Vaya!\\n¡No tienes suficiente dinero!"))
        break
      else
        p choosenMovename
        Kernel.pbMessage(_INTL("\\g¿A que Pokémon quieres enseñarle {1}",choosenMovename))
        if pbMoveTutorChoose(choosenMove)
          pbSEPlay("SlotsCoin")
          $Trainer.money-=choosenprice
          Kernel.pbMessage(_INTL("\\g¡Todo listo!"))
          if !Kernel.pbConfirmMessageSerious(_INTL("\\g¿Quieres que les enseñe otro movimiento?"))
            break
          end
        else
          break
        end
      end
    end
  end #Loop
  Kernel.pbMessage(_INTL("¡Hasta la próxima!"))
end