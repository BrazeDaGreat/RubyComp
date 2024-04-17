require 'listen'
require 'sassc'
require 'fileutils'
require 'colorize'

module Compiler
  VERSION = '2.0.0'
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
  end

  def self.html_processor(html_content, filepath = nil)
    html_content.gsub!(/<R>(.*?)<\/R>/m) { eval($1) }
    html_content.gsub!(/<JS>(.*?)<\/JS>/m) { "<script src=\"./js/#{$1}.js\"></script>" }
    html_content.gsub!(/<SCSS>(.*?)<\/SCSS>/m) { "<link rel=\"stylesheet\" href=\"./css/#{$1}.css\">" }
    html_content.gsub!(/<C>(.*?)<\/C>/m) do
      component_file = "build/.cache/comp_#{$1}.xhtml"
      if $1 && filepath
        DEPENDENCIES["#{$1}.xhtml"] ||= []
        DEPENDENCIES["#{$1}.xhtml"].push(filepath) unless DEPENDENCIES["#{$1}.xhtml"].include?(filepath)
      end
      File.exist?(component_file) ? File.read(component_file) : ""
    end
    html_content
  end

  def self.process_component(file)
    DEPENDENCIES[File.basename(file)] ||= []
    html_content = File.read(file)
    pre_processed = html_processor(html_content, file)
    output_file = "build/.cache/comp_#{File.basename(file)}"
    File.write(output_file, pre_processed)
    puts "Detected, compiled 1 file(s)".green
    DEPENDENCIES[File.basename(file)].each do |dep|
      puts "Detected, compiled 2 file(s)".green
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
    puts "Detected, compiled 1 file(s)".green
  end

  def self.compile_scss(file)
    scss_content = File.read(file)
    css_content = SassC::Engine.new(scss_content, syntax: :scss).render
    output_file = "build/css/#{File.basename(file, '.scss')}.css"
    File.write(output_file, css_content)
    puts "Detected, compiled 1 file(s)".green
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
    puts "Detected, compiled 1 file(s)".green
  end
end

puts "---- [ RubyComp v#{Compiler::VERSION} ] ----".blue
puts "Initialized, listening for changes ...".green

directories = ['html', 'scss', 'js', 'components']
directories.each do |directory|
  Compiler.compile_files(Dir.glob("#{directory}/*"))
end

listener = Listen.to(*directories) do |modified, added, _removed|
  puts "Detected, compiled #{modified.length + added.length} file(s)".green
  Compiler.compile_files(modified + added)
end

listener.start
sleep
