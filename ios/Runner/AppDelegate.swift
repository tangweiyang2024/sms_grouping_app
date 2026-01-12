import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    setupSMSClassificationChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    private func setupSMSClassificationChannel() {
        let controller = window?.rootViewController as? FlutterViewController
        let smsChannel = FlutterMethodChannel(
            name: "com.smsgrouping.app/sms",
            binaryMessenger: controller!.binaryMessenger
        )
        
        smsChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else {
                result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate not available", details: nil))
                return
            }
            
            switch call.method {
            case "getAllMessages":
                let messages = SMSClassificationManager.shared.getAllMessages()
                result(messages)
                
            case "getCategoryGroups":
                let groups = SMSClassificationManager.shared.getCategoryGroups()
                result(groups)
                
            case "getCategoryStats":
                let stats = SMSClassificationManager.shared.getCategoryStats()
                result(stats)
                
            case "deleteMessage":
                if let args = call.arguments as? [String: Any],
                   let messageId = args["id"] as? String {
                    SMSClassificationManager.shared.deleteMessage(withId: messageId)
                    result(true)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing message id", details: nil))
                }
                
            case "clearAllMessages":
                SMSClassificationManager.shared.clearAllMessages()
                result(true)
                
            case "addTestMessage":
                if let args = call.arguments as? [String: Any],
                   let content = args["content"] as? String,
                   let sender = args["sender"] as? String,
                   let category = args["category"] as? String {
                    SMSClassificationManager.shared.addTestMessage(content: content, sender: sender, category: category)
                    result(true)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing required arguments", details: nil))
                }
                
            case "checkExtensionStatus":
                let isEnabled = SMSClassificationManager.shared.checkExtensionStatus()
                result(isEnabled)
                
            case "getExtensionSetupInstructions":
                let instructions = SMSClassificationManager.shared.getExtensionSetupInstructions()
                result(instructions)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
