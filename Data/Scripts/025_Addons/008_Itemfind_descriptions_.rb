#-------------------------------------------------------------------------------
# Item Find
# v1.2.1
# By Boonzeet
# Adapted to BES & 16.3 by MartxnoDev
#-------------------------------------------------------------------------------
# A script to show a helpful message with item name, icon and description
# when an item is found for the first time.
#-------------------------------------------------------------------------------
# Config
#-------------------------------------------------------------------------------

WINDOWSKIN_NAME = "" # set for custom windowskin

#-------------------------------------------------------------------------------
# Base Class
#-------------------------------------------------------------------------------

class PokemonItemFind_Scene
  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    skin = WINDOWSKIN_NAME == "" ? MessageConfig.pbGetSystemFrame : "Graphics/Windowskins/" + WINDOWSKIN_NAME
    
    
    @sprites["background"] = Window_UnformattedTextPokemon.newWithSize("", 0, 0, Graphics.width, 0, @viewport)
    @sprites["background"].z = @viewport.z - 1
    @sprites["background"].visible = false
    @sprites["background"].setSkin(skin)
    
    colors = getDefaultTextColors(@sprites["background"].windowskin)

    @sprites["itemicon"] = ItemIconSprite.new(42, Graphics.height - 48, -1, @viewport)
    @sprites["itemicon"].visible = false
    @sprites["itemicon"].z = @viewport.z + 2
	
    @sprites["descwindow"] = Window_UnformattedTextPokemon.newWithSize("", 64, 0, Graphics.width - 64, 64, @viewport)
    @sprites["descwindow"].windowskin = nil
    @sprites["descwindow"].z = @viewport.z
    @sprites["descwindow"].visible = false
    @sprites["descwindow"].baseColor = colors[0]
    @sprites["descwindow"].shadowColor = colors[1]

    @sprites["titlewindow"] = Window_UnformattedTextPokemon.newWithSize("", 0, 0, 128, 16, @viewport)
    @sprites["titlewindow"].visible = false
    @sprites["titlewindow"].z = @viewport.z + 1
    @sprites["titlewindow"].windowskin = nil
    @sprites["titlewindow"].baseColor = colors[0]
    @sprites["titlewindow"].shadowColor = colors[1]
  end

  def pbShow(item)
    name = PBItems.getName(item)
    description = pbGetMessage(MessageTypes::ItemDescriptions, item)

    descwindow = @sprites["descwindow"]
    descwindow.resizeToFit(description, Graphics.width - 64)
    descwindow.text = description
    descwindow.y = Graphics.height - descwindow.height
    descwindow.visible = true

    titlewindow = @sprites["titlewindow"]
    titlewindow.resizeToFit(name, Graphics.height)
    titlewindow.text = name
    titlewindow.y = Graphics.height - descwindow.height - 32
    titlewindow.visible = true

    background = @sprites["background"]
    background.height = descwindow.height + 32
    background.y = Graphics.height - background.height
    background.visible = true

    itemicon = @sprites["itemicon"]
    itemicon.item = item
    itemicon.y = Graphics.height - (descwindow.height / 2).floor
    itemicon.visible = true

    loop do
      background.update
      itemicon.update
      descwindow.update
      titlewindow.update
      Graphics.update
      Input.update
      pbUpdateSceneMap
      if Input.trigger?(Input::B) || Input.trigger?(Input::C)
        pbEndScene
        break
      end
    end
  end

  def pbEndScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#-------------------------------------------------------------------------------
# Game Player changes
#-------------------------------------------------------------------------------
# Adds a list of found items to the Game Player which is maintained over saves
#-------------------------------------------------------------------------------

class Game_Player
  alias initialize_itemfind initialize
  def initialize(*args)
    @found_items = []
    initialize_itemfind(*args)
  end

  def addFoundItem(item)
    if !defined?(@found_items)
      @found_items = []
    end
    if !@found_items.include?(item)
      @found_items.push(item)
      scene = PokemonItemFind_Scene.new
      scene.pbStartScene
      scene.pbShow(item)
    end
  end
end