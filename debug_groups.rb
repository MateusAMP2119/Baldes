require 'xcodeproj'

project_path = 'Baldes.xcodeproj'
project = Xcodeproj::Project.open(project_path)

main_group = project.main_group
puts "Main Group: #{main_group.display_name} (#{main_group.class})"

main_group.children.each do |child|
  puts " - #{child.display_name} (#{child.class})"
  if child.is_a?(Xcodeproj::Project::Object::PBXGroup)
     puts "   Path: #{child.path}"
  end
end
