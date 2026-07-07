#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'ShiftScheduler.xcodeproj'
project = Xcodeproj::Project.open(project_path)

if project.targets.any? { |t| t.name == 'ShiftSchedulerCLI' }
  abort "Target ShiftSchedulerCLI already exists — aborting to avoid duplicating."
end

# MARK: - Target

target = project.new_target(:application, 'ShiftSchedulerCLI', :osx, '14.0', nil, :swift, 'shift-scheduler')

team_id = 'M8T74C3QWG'

common_settings = {
  'CODE_SIGN_STYLE' => 'Automatic',
  'DEVELOPMENT_TEAM' => team_id,
  'CODE_SIGN_ENTITLEMENTS' => 'CLI.entitlements',
  'PRODUCT_BUNDLE_IDENTIFIER' => 'functioncraft.ShiftSchedulerCLI',
  'PRODUCT_NAME' => 'shift-scheduler',
  'MACOSX_DEPLOYMENT_TARGET' => '14.0',
  'SDKROOT' => 'macosx',
  'SWIFT_VERSION' => '5.0',
  'SWIFT_EMIT_LOC_STRINGS' => 'NO',
  'ENABLE_HARDENED_RUNTIME' => 'NO',
  'SKIP_INSTALL' => 'YES',
  'GENERATE_INFOPLIST_FILE' => 'YES',
  'INFOPLIST_KEY_LSUIElement' => 'YES',
  'CURRENT_PROJECT_VERSION' => '1',
  'MARKETING_VERSION' => '1.0',
}

target.build_configurations.each do |config|
  common_settings.each { |k, v| config.build_settings[k] = v }
end

# MARK: - Swift Argument Parser package dependency

pkg_ref = project.root_object.package_references.find do |ref|
  ref.respond_to?(:repositoryURL) && ref.repositoryURL == 'https://github.com/apple/swift-argument-parser.git'
end

unless pkg_ref
  pkg_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  pkg_ref.repositoryURL = 'https://github.com/apple/swift-argument-parser.git'
  pkg_ref.requirement = { 'kind' => 'upToNextMajorVersion', 'minimumVersion' => '1.3.0' }
  project.root_object.package_references << pkg_ref
end

product_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
product_dep.package = pkg_ref
product_dep.product_name = 'ArgumentParser'
project.root_object.attributes['TargetAttributes'] ||= {}

frameworks_phase = target.frameworks_build_phase
build_file = frameworks_phase.add_file_reference(product_dep, true) rescue nil
if build_file.nil?
  # Fall back to manually creating the build file referencing the package product
  bf = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  bf.product_ref = product_dep
  frameworks_phase.files << bf
end
target.package_product_dependencies << product_dep

# MARK: - Source groups (filesystem-synchronized, mirroring Package.swift's whitelist)

included_dirs = [
  'ShiftScheduler/Models',
  'ShiftScheduler/Domain',
  'ShiftScheduler/Persistence',
  'ShiftScheduler/Repositories',
  'ShiftScheduler/Protocols',
  'ShiftScheduler/Services',
  'ShiftScheduler/Redux/Errors',
  'Sources/ShiftSchedulerCLI',
]

included_dirs.each do |dir|
  group = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
  group.path = dir
  group.source_tree = '<group>'
  project.main_group << group
  target.file_system_synchronized_groups ||= []
  target.file_system_synchronized_groups << group
end

# Redux/Services needs exceptions: exclude Mocks/ and ServiceContainer.swift (matches Package.swift's `exclude:`)
redux_services_group = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
redux_services_group.path = 'ShiftScheduler/Redux/Services'
redux_services_group.source_tree = '<group>'
project.main_group << redux_services_group
target.file_system_synchronized_groups << redux_services_group

exception_set = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedBuildFileExceptionSet)
exception_set.target = target
exception_set.membership_exceptions = ['ServiceContainer.swift', 'Mocks']
redux_services_group.exceptions ||= []
redux_services_group.exceptions << exception_set

# MARK: - Entitlements file reference

entitlements_ref = project.main_group.new_reference('CLI.entitlements')
entitlements_ref.source_tree = '<group>'

project.save
puts "Added target 'ShiftSchedulerCLI'."
