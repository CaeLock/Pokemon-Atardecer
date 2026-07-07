#===============================================================================
# Adds new @starter attribute to define starter Pokemon
#===============================================================================

class PokeBattle_Pokemon
  attr_accessor :starter   # true if starter

  alias starterflag_initialize initialize

  def initialize(*args)
    starterflag_initialize(*args)
    @starter = false if @starter.nil?
  end

  def starter?
    return @starter == true
  end

  def make_starter
    @starter = true
  end

  def unmark_starter
    @starter = false
  end
end

#===============================================================================
# Event commands
#===============================================================================

# Marks a Pokemon as starter
def pbMarkAsStarter(pokemon)
  return if !pokemon
  pokemon.make_starter
end