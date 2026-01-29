require 'xcodeproj'

project_path = 'Baldes.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target_name = 'Baldes'
target = project.targets.find { |t| t.name == target_name }

if target.nil?
  puts "Error: Target #{target_name} not found"
  exit 1
end

# Define files to add relative to project root
files_to_add = [
  'Baldes/Features/Shared/Models/Activity.swift',
  'Baldes/Features/Shared/Extensions/Color+Hex.swift',
  'Baldes/Features/Dashboard/Components/ActivityCardView.swift',
  'Baldes/Features/Dashboard/Components/DashboardHistoryView.swift'
]

# Get the main group (usually the project root group)
main_group = project.main_group

files_to_add.each do |file_path|
  # Split path to find/create groups
  # Assuming file_path is like "Group/SubGroup/File.swift"
  
  # We want to add it to the project.
  # Check if already exists in build phase to avoid duplication?
  
  # Find or create group structure
  current_group = main_group
  
  # Split path components
  components = file_path.split('/')
  filename = components.pop
  
  components.each do |component|
    # Find subgroup or create it
    # We use find_subpath for existing, but manual traversal is safer for creation
    next_group = current_group[component]
    if next_group.nil?
      next_group = current_group.new_group(component)
    end
    current_group = next_group
  end
  
  # Now current_group is the parent group for the file
  # Check if file reference already exists
  file_ref = current_group.files.find { |f| f.path == filename }
  
  if file_ref.nil?
    file_ref = current_group.new_file(filename)
    puts "Added file reference: #{file_path}"
  else
    puts "File reference already exists: #{file_path}"
  end
  
  # Add to target source build phase
  if target.source_build_phase.files_references.include?(file_ref)
    puts "File already in compile sources: #{file_path}"
  else
    target.add_file_references([file_ref])
    puts "Added to compile sources: #{file_path}"
  end
end

project.save
puts "Project saved."
