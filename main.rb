require 'listen'
require 'sassc'
require 'fileutils'

# Constants
VERSION = '1.0'

# Compile HTML, SCSS, and JS files based on changes detected in specified directories.
#
# @param files [Array<String>] List of files that have been modified or added.
def compile_files(files)
  files.each do |file|
    case File.extname(file)
    when '.html'
      compile_html(file)
    when '.scss'
      compile_scss(file)
    when '.js'
      compile_js(file)
    end
  end
end

# Compile HTML file by replacing tags and including component files.
#
# @param file [String] Path to the HTML file to compile.
def compile_html(file)
  # Read the content of the HTML file
  html_content = File.read(file)

  # Replace <r> tags with the VERSION constant
  html_content.gsub!(/<R>(.*?)<\/R>/m) do
    eval($1)
  end

  # Replace <JS> tags with <script> tags
  html_content.gsub!(/<JS>(.*?)<\/JS>/m) do
    "<script src=\"./js/#{$1}.js\"></script>"
  end

  # Replace <SCSS> tags with <link> tags
  html_content.gsub!(/<SCSS>(.*?)<\/SCSS>/m) do
    "<link rel=\"stylesheet\" href=\"./css/#{$1}.css\">"
  end

  # Replace <C> tags with content of the component file
  html_content.gsub!(/<C>(.*?)<\/C>/m) do
    component_file = "components/#{$1}.html"
    File.exist?(component_file) ? File.read(component_file) : ""
  end

  # Write the compiled HTML content to the build directory
  output_file = "build/#{File.basename(file)}"
  File.write(output_file, html_content)
  puts "Compiled #{file} to #{output_file}"
end

# Compile SCSS file into CSS.
#
# @param file [String] Path to the SCSS file to compile.
def compile_scss(file)
  # Read the content of the SCSS file
  scss_content = File.read(file)

  # Compile SCSS to CSS
  css_content = SassC::Engine.new(scss_content, syntax: :scss).render

  # Write the compiled CSS content to the build directory
  output_file = "build/css/#{File.basename(file, '.scss')}.css"
  File.write(output_file, css_content)
  puts "Compiled #{file} to #{output_file}"
end

# Copy JS file to the build directory.
#
# @param file [String] Path to the JS file to copy.
def compile_js(file)
  # Read the content of the JS file
  js_content = File.read(file)

  # Evaluate Ruby code embedded within ruby() function calls and replace with result
  js_content.gsub!(/ruby\(\"(.*?)\"\)/m) do
    eval($1)
  end

  # Replace import() function with content of the component file
  js_content.gsub!(/import\(\"(.*?)\"\)/m) do
    code_file = "js/#{$1}"
    File.exist?(code_file) ? File.read(code_file) : ""
  end

  # Write the compiled JS content to the build directory
  output_file = "build/js/#{File.basename(file)}"
  File.write(output_file, js_content)
  puts "Compiled #{file} to #{output_file}"
end


# Create build directory if it doesn't exist
Dir.mkdir('build') unless Dir.exist?('build')
# Create build/js directory if it doesn't exist
Dir.mkdir('build/js') unless Dir.exist?('build/js')
# Create build/css directory if it doesn't exist
Dir.mkdir('build/css') unless Dir.exist?('build/css')

# Define the directories to watch
directories = ['html', 'scss', 'js', 'components']

# Create a listener to watch for changes
listener = Listen.to(*directories) do |modified, added, removed|
  puts "Changes detected:"
  puts "Modified: #{modified.join(', ')}" unless modified.empty?
  puts "Added: #{added.join(', ')}" unless added.empty?
  puts "Removed: #{removed.join(', ')}" unless removed.empty?

  # Perform compilation when changes detected
  compile_files(modified + added)
end

# Start the listener
puts "Listening for changes..."
listener.start

# Don't exit immediately, keep listening
sleep
