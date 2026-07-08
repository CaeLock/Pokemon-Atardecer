#Allows the use of MO if the Pokemon could learn it in any way (TM, egg list or level up)

module Kernel

  #Load egg moves cache
  def self.pb_load_pbs_egg_moves_cache
    return $pkmn_egg_moves_cache if $pkmn_egg_moves_cache
    $pkmn_egg_moves_cache = {}
    begin
      File.open("PBS/pokemon.txt","rb"){|f|
        pbEachFileSection(f){|section_hash,species_id|
          next if !section_hash
          em = section_hash["EggMoves"]
          if em && em!=""

            # Format: COMMA-separated constant names (ej. TACKLE,EMBER)
            arr = em.split(",").map{|s| s.strip}.reject{|s| s==""}.map{|tok|
              begin
                getID(PBMoves,tok)
              rescue
                0
              end
            }.reject{|id| !id || id<=0}
            $pkmn_egg_moves_cache[species_id] = arr
          else
            $pkmn_egg_moves_cache[species_id] = []
          end
        }
      }
    rescue
      # Empty if it fails
      $pkmn_egg_moves_cache = {}
    end
    return $pkmn_egg_moves_cache
  end

  # Check for Egg moves
  def self.pb_species_has_eggmove?(species, move)
    return false if !species || species<=0
    move = getID(PBMoves, move) if move.is_a?(String) || move.is_a?(Symbol)
    cache = pb_load_pbs_egg_moves_cache
    arr = cache[species] || []
    return arr.include?(move)
  end

  # Check if move is avaliable in move list
  def self.pb_species_can_learn_by_level?(species, move)
    return false if !species || species<=0
    move = getID(PBMoves, move) if move.is_a?(String) || move.is_a?(Symbol)
    begin
      tmp = PokeBattle_Pokemon.new(species, 1, $Trainer) rescue nil
      return false if !tmp
      moveList = tmp.getMoveList rescue nil
      if moveList && moveList.is_a?(Array)
        moveList.each do |entry|
          atk = entry[1] rescue nil
          return true if atk == move
        end
      end
    rescue 
    # ignore errors
    end
    return false
  end

  # Returns PokeBattle_Pokemon if the one avaliable to use the M0.
  # Returns nil if nobody
  def self.pbCheckMove(move)
    move = getID(PBMoves, move)
    return nil if !move || move <= 0

    #Check for Pokemon with the move learned that is not egg/debilitated
    for p in $Trainer.party
      next if !p || p.isEgg? || p.hp <= 0
      for mm in p.moves
        return p if mm.id == move
      end
    end

    #Check for MT/M0-compatible Pokémon
    for p in $Trainer.party
      next if !p || p.isEgg? || p.hp <= 0
      begin
        return p if p.isCompatibleWithMove?(move)  
      rescue
        # ignorar y continuar
      end
    end

    #Check for movelist-compatible Pokémon
    for p in $Trainer.party
      next if !p || p.isEgg? || p.hp <= 0
      begin
        return p if Kernel.pb_species_can_learn_by_level?(p.species, move)
        return p if Kernel.pb_species_has_eggmove?(p.species, move)
      rescue
        # ignorar y continuar
      end
    end

    return
  end
end