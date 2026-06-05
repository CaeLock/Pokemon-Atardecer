module Console
  @@console_open = false

  # Al inicio del script Console
  def self.setup_console
    return unless $DEBUG
    return if @@console_open
    if defined?(Win32API)
      apiAllocConsole = Win32API.new("kernel32", "AllocConsole", "", "l")
      apiAllocConsole.call
      
      # Configurar consola para UTF-8 (código de página 65001)
      begin
        apiSetConsoleCP = Win32API.new("kernel32", "SetConsoleCP", "l", "l")
        apiSetConsoleOutputCP = Win32API.new("kernel32", "SetConsoleOutputCP", "l", "l")
        apiSetConsoleCP.call(65001)
        apiSetConsoleOutputCP.call(65001)
      rescue
        # Si falla, continuar con la configuración por defecto
      end
      
      $stdout = File.open("CONOUT$", "w")
      $stdout.sync = true
      $stdout.binmode if $stdout.respond_to?(:binmode)
    end
    @@console_open = true
    begin
    echoln "GPU Cache Max: #{Bitmap.max_size}"
    echoln "-------------------------------------------------------------------------------"
    echoln "#{System.game_title} Output Window"
    echoln "-------------------------------------------------------------------------------"
    echoln "If you can see this window, you are running the game in Debug Mode. This means"
    echoln "that you're either playing a debug version of the game, or you're playing from"
    echoln "within RPG Maker XP."
    echoln ""
    echoln "Closing this window will close the game. If you want to get rid of this window,"
    echoln "run the program from the Shell, or download a release version of the game."
    echoln "-------------------------------------------------------------------------------"
    echoln "Debug Output:"
    echoln "-------------------------------------------------------------------------------"
    echoln ""
    rescue;end
  end

  def self.readInput
    return gets.strip
  end

  def self.readInput2
    return self.readInput
  end

  def self.get_input
    echo self.readInput2
  end
  

  def self.open?
    return @@console_open
  end

end

module Kernel
  def echo(string)
    return unless $DEBUG
    printf(string.is_a?(String) ? string : string.inspect)
  end

  def echoln(string)
    echo string
    echo "\n"
  end
end

#Console.setup_console

#===============================================================================
#  Console message formatting
#===============================================================================
module Console
  # Nota Ruby 1.8: module_function hace que los metodos sean privados
  # de instancia Y metodos del modulo. Se declara antes de los metodos
  # que debe afectar, o se lista cada nombre individualmente al final.
  module_function

  def echo_h1(msg)
    echoln markup_style(msg, :text => :brown)  # => en lugar de key:
    echoln ""
  end

  # Ruby 1.8: **options no existe; se usa un hash normal con valor por defecto
  def echo_h2(msg, options={})
    echoln markup_style(msg, options)
    echoln ""
  end

  def echo_h3(msg)
    echoln markup(msg)
    echoln ""
  end

  def echo_li(msg, pad=0, color=:brown)
    echo markup_style("  -> ", :text => color)
    pad = (pad - msg.length) > 0 ? "." * (pad - msg.length) : ""
    echo markup(msg + pad)
  end

  def echoln_li(msg, pad=0, color=:brown)
    self.echo_li(msg, pad, color)
    echoln ""
  end

  def echoln_li_done(msg)
    self.echo_li(markup_style(msg, :text => :green), 0, :green)
    echoln ""
    echoln ""
  end

  def echo_p(msg)
    echoln markup(msg)
  end

  def echo_warn(msg)
    echoln markup_style("WARNING: #{msg}", :text => :yellow)
  end

  def echo_error(msg)
    echoln markup_style("ERROR: #{msg}", :text => :light_red)
  end

  def echo_status(status)
    if status
      echoln markup_style("OK", :text => :green)
    else
      echoln markup_style("FAIL", :text => :red)
    end
  end

  def echo_done(status)
    if status
      echoln markup_style("done", :text => :green)
    else
      echoln markup_style("error", :text => :red)
    end
  end

  #-----------------------------------------------------------------------------
  # Markup options
  #-----------------------------------------------------------------------------
  def string_colors
    {
      :default => "38", :black => "30", :red => "31", :green => "32", :brown => "33",
      :blue => "34", :purple => "35", :cyan => "36", :gray => "37",
      :dark_gray => "1;30", :light_red => "1;31", :light_green => "1;32", :yellow => "1;33",
      :light_blue => "1;34", :light_purple => "1;35", :light_cyan => "1;36", :white => "1;37"
    }
  end

  def background_colors
    {
      :default => "0", :black => "40", :red => "41", :green => "42", :brown => "43",
      :blue => "44", :purple => "45", :cyan => "46", :gray => "47",
      :dark_gray => "100", :light_red => "101", :light_green => "102", :yellow => "103",
      :light_blue => "104", :light_purple => "105", :light_cyan => "106", :white => "107"
    }
  end

  def font_options
    {
      :bold => "1", :dim => "2", :italic => "3", :underline => "4", :reverse => "7",
      :hidden => "8"
    }
  end

  def markup_colors
    {
      "`" => :cyan, '"' => :purple, "==" => :purple, "$" => :green, "~" => :red
    }
  end

  def markup_options
    {
      "__" => :underline, "*" => :bold, "|" => :italic
    }
  end

  # Ruby 1.8: no existe **options; se recibe un hash y se extrae :text y :bg
  def markup_style(string, options={})
    text = options.delete(:text) || :default
    bg   = options.delete(:bg)   || :default
    # Las claves restantes son opciones de fuente (bold:true, etc.)
    code_text = string_colors[text]
    code_bg   = background_colors[bg]
    # Ruby 1.8: select devuelve un Array de pares [key,val], no un Hash
    options_pool = options.select { |key, val| font_options.key?(key) && val }
    markup_pool  = options_pool.map { |opt| font_options[opt[0]] }.join(";").squeeze
    return "\e[#{code_bg};#{markup_pool};#{code_text}m#{string}\e[0m".squeeze(";")
  end

  #-----------------------------------------------------------------------------
  # Markup en texto
  #-----------------------------------------------------------------------------

  def markup_all_options
    # Ruby 1.8: ||= con metodos de modulo puede dar error de ambiguedad;
    # se usa la forma explicita con variable de clase para el cache
    @@markup_all_options ||= markup_colors.merge(markup_options)
  end

  def markup_component(string, component, key, options)
    l = key.length
    trimmed = component[l...-l]
    options[trimmed] = {} unless options[trimmed]
    # Ruby 1.8: no hay deep_merge! nativo; se implementa la fusion a mano
    new_opt = {}
    new_opt[:text] = markup_colors[key] if markup_colors.key?(key)
    new_opt[markup_options[key]] = true if markup_options.key?(key)
    # Fusion manual equivalente a deep_merge!
    new_opt.each do |k, v|
      if options[trimmed][k].is_a?(Hash) && v.is_a?(Hash)
        options[trimmed][k].merge!(v)
      else
        options[trimmed][k] = v
      end
    end
    string = string.gsub(component, trimmed)
    return string, options
  end

  def markup_breakdown(string, options={})
    markup_all_options.each_key do |key|
      key_char = key.chars.map { |c| "\\#{c}" }.join
      regex = "#{key_char}.*?#{key_char}"
      string.scan(/#{regex}/).each do |component|
        return *markup_breakdown(*markup_component(string, component, key, options))
      end
    end
    return string, options
  end

  def markup(string)
    string, options = markup_breakdown(string)
    options.each do |key, opt|
      string = string.gsub(key, markup_style(key, opt))
    end
    return string
  end
end