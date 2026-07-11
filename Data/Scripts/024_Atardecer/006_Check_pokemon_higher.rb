# Devuelve un array de índices PBStats ordenados por el BaseStat (PBS) descendente.
# species_or_pkmn: PokeBattle_Pokemon/Pokemon object OR species id (int) OR species name (symbol/string)
# include_hp: si true incluye PBStats::HP en la lista (por defecto true)
# Ejemplo de retorno: [PBStats::SPATK, PBStats::SPEED, PBStats::ATTACK, ...]
def Kernel.pbOrderByBaseStats(species_or_pkmn, include_hp=true)
  # Obtener baseStats [HP, Atk, Def, Speed, SpAtk, SpDef]
  bs = nil
  if species_or_pkmn.respond_to?(:baseStats)
    bs = species_or_pkmn.baseStats
  else
    species = nil
    if species_or_pkmn.is_a?(String) || species_or_pkmn.is_a?(Symbol)
      species = getID(PBSpecies, species_or_pkmn) rescue 0
    elsif species_or_pkmn.is_a?(Integer)
      species = species_or_pkmn.to_i
    end
    return [] if !species || species <= 0
    dexdata = pbOpenDexData
    begin
      pbDexDataOffset(dexdata, species, 10)
      bs = []
      for i in 0...6
        bs.push(dexdata.fgetb)
      end
    ensure
      dexdata.close rescue nil
    end
  end
  return [] if !bs || bs.length < 6

  # Mapear baseStats a índices PBStats:
  # baseStats: [HP, Atk, Def, Speed, SpAtk, SpDef]
  mapping = [
    [PBStats::HP,     bs[0]],
    [PBStats::ATTACK, bs[1]],
    [PBStats::DEFENSE,bs[2]],
    [PBStats::SPEED,  bs[3]],
    [PBStats::SPATK,  bs[4]],
    [PBStats::SPDEF,  bs[5]]
  ]

  # Omitir HP si no queremos incluirlo
  mapping.reject! { |id,_| id == PBStats::HP } unless include_hp

  # Orden descendente por valor base (compatible con todas las versiones de Ruby)
  mapping.sort! { |a,b| b[1] <=> a[1] }

  # Devolver sólo los índices (enteros PBStats::*)
  mapping.map { |id, _val| id }
end