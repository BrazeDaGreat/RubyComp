require 'listen'
require 'sassc'
require 'fileutils'
require 'colorize'
require 'io/console'

# Importing all the Add-ons.
Dir["addons/*.rb"].each { |file| require_relative file }

module Compiler
  VERSION = '3.1'
  DEPENDENCIES = {}

  def self.compile_files(files)
    files.each do |file|
      case File.extname(file)
      when '.xhtml'
        process_component(file)
      when '.html'
        compile_html(file)
      when '.scss'
        compile_scss(file)
      when '.js'
        compile_js(file)
      end
    end
    puts "|".white + " ~> ".red + "Compiled".white + " #{files.length} ".green + "file(s).".white
  end

  def self.parse_component(component_file, attributes)
    file = File.read(component_file)
    if attributes == nil
      attributes = "{}"
    end
    attributes_hash = eval(attributes)

    # Scan for {{x}} where x is a key in attributes_hash
    file.gsub!(/{{(.*?)}}/) do
      x = $1
      key = x.dup
      key.gsub!("?",'')
      if attributes_hash.key?(key.to_sym)
        attributes_hash[key.to_sym]
      else
        if x.include?("?")
          ""
        else
          "<script>alert('Key #{key} is missing from #{component_file}.')</script>"
        end
      end
    end

    file
  end

  def self.html_processor(html_content, filepath = nil)
    html_content.gsub!(/<R>(.*?)<\/R>/m) { eval($1) }
    html_content.gsub!(/<JS>(.*?)<\/JS>/m) { "<script src=\"./js/#{$1}.js\"></script>" }
    html_content.gsub!(/<SCSS>(.*?)<\/SCSS>/m) { "<link rel=\"stylesheet\" href=\"./css/#{$1}.css\">" }

    html_content.gsub!(/<C(\s+[^>]+)?>([^<]+)<\/C>/) do
      attributes = $1
      component_file = "build/.cache/comp_#{$2}.xhtml"
      if $2 && filepath
        DEPENDENCIES["#{$2}.xhtml"] ||= []
        DEPENDENCIES["#{$2}.xhtml"].push(filepath) unless DEPENDENCIES["#{$2}.xhtml"].include?(filepath)
      end
      File.exist?(component_file) ? self.parse_component(component_file, attributes) : ""
    end
    html_content
  end

  def self.process_component(file)
    DEPENDENCIES[File.basename(file)] ||= []
    html_content = File.read(file)
    pre_processed = html_processor(html_content, file)
    output_file = "build/.cache/comp_#{File.basename(file)}"
    File.write(output_file, pre_processed)
    DEPENDENCIES[File.basename(file)].each do |dep|
      if File.extname(dep) == '.html'
        compile_html(dep)
      elsif File.extname(dep) == '.xhtml'
        process_component(dep)
      end
    end
  end

  def self.compile_html(file)
    html_content = File.read(file)
    pre_processed = html_processor(html_content, file)
    output_file = "build/#{File.basename(file)}"
    File.write(output_file, pre_processed)
  end

  def self.compile_scss(file)
    scss_content = File.read(file)
    css_content = SassC::Engine.new(scss_content, syntax: :scss).render
    output_file = "build/css/#{File.basename(file, '.scss')}.css"
    File.write(output_file, css_content)
  end

  def self.compile_js(file)
    js_content = File.read(file)
    js_content.gsub!(/ruby\(\"(.*?)\"\)/m) { eval($1) }
    js_content.gsub!(/import\(\"(.*?)\"\)/m) do
      code_file = "js/#{$1}"
      File.exist?(code_file) ? File.read(code_file) : ""
    end
    output_file = "build/js/#{File.basename(file)}"
    File.write(output_file, js_content)
  end
end


# -------------------------------------------------------------------------------------------------------------------------------------------- #

puts "--------------- ".white + "[ ".blue + "RubyComp".red + " v".white + "#{Compiler::VERSION}".red + " ]".blue + " ---------------".white
puts "|".white + " ~> ".red + "Running".white + " ... ".green
puts "|".white + " ~> ".red + "Press ".white + "c".red + " to exit.".white
puts "|".white + " ~> ".red + "Press ".white + "r".red + " to force recompile.".white

directories = ['html', 'scss', 'js', 'components']
files_to_compile = []
directories.each do |directory|
  files_to_compile += Dir.glob("#{directory}/*")
end

Compiler.compile_files(files_to_compile)

listener = Listen.to(*directories) do |modified, added, _removed|
  puts "|".white + " ~> ".red + "Changes detected.".white
  Compiler.compile_files(modified + added)
end

listener.start

loop do
  begin
    case $stdin.getch
    when 'r'
      puts "|".white + " ~> ".red + "Forcing recompile...".white
      Compiler.compile_files(files_to_compile)
    when 'c'
      puts "|".white + " ~> ".red + "Exiting...".white
      break
    end
  end
end
