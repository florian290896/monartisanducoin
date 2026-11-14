require 'xcodeproj'
require 'fileutils'
dir=ARGV.fetch(0)
FileUtils.mkdir_p(dir)
project=Xcodeproj::Project.new(File.join(dir,'PermissionHelper.xcodeproj'))
target=project.new_target(:ui_test_bundle,'PermissionHelper',:ios,'15.0')
ref=project.main_group.new_file('PermissionHelper.swift');target.source_build_phase.add_file_reference(ref)
target.build_configurations.each do |c|
 c.build_settings['PRODUCT_BUNDLE_IDENTIFIER']='fr.mon-artisan-du-coin.qa.permissionhelper'
 c.build_settings['GENERATE_INFOPLIST_FILE']='YES'
 c.build_settings['SWIFT_VERSION']='5.0'
 c.build_settings['CODE_SIGNING_ALLOWED']='NO'
 c.build_settings['TARGETED_DEVICE_FAMILY']='1,2'
end
project.save
scheme=Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.add_test_target(target)
scheme.save_as(project.path,'PermissionHelper',true)
File.write(File.join(dir,'PermissionHelper.swift'), <<~SWIFT)
import XCTest
final class PermissionHelper: XCTestCase {
 func testHandleNotificationPermission() {
  let system = XCUIApplication(bundleIdentifier: "com.apple.springboard")
  let deadline = Date().addingTimeInterval(480)
  while Date() < deadline {
   let alert = system.alerts.firstMatch
   if alert.exists {
    let text = alert.staticTexts.allElementsBoundByIndex.map { $0.label }.joined(separator: " ")
    if text.localizedCaseInsensitiveContains("notification") {
     for title in ["Don’t Allow", "Don't Allow", "Ne pas autoriser", "Refuser"] {
      let button = alert.buttons[title]
      if button.exists { button.tap(); print("MADC_NATIVE_NOTIFICATION_DENIED"); return }
     }
    }
   }
   Thread.sleep(forTimeInterval: 1)
  }
  XCTFail("Expected notification permission was not handled")
 }
}
SWIFT
