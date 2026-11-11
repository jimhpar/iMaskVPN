import Flutter
import UIKit
import NetworkExtension

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let vpnChannelName = "com.imask.vpn/vpn"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    setupVpnChannel(messenger: engineBridge.applicationRegistrar.messenger())
  }

  private func setupVpnChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: vpnChannelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "prepareAndConnect":
        let args = call.arguments as? [String: Any]
        let serverName = args?["serverName"] as? String ?? "iMask VPN"
        let serverIp = args?["serverIp"] as? String ?? "129.225.114.149"

        NETunnelProviderManager.loadAllFromPreferences { managers, _ in
          let manager = managers?.first ?? NETunnelProviderManager()
          let proto = NETunnelProviderProtocol()
          proto.providerBundleIdentifier = "com.imask.vpn.imaskVpn.PacketTunnel"
          proto.serverAddress = serverIp
          manager.protocolConfiguration = proto
          manager.localizedDescription = "iMask VPN (\(serverName))"
          manager.isEnabled = true

          manager.saveToPreferences { saveErr in
            if saveErr != nil {
              result(true)
              return
            }
            manager.loadFromPreferences { _ in
              do {
                try manager.connection.startVPNTunnel()
                result(true)
              } catch {
                result(true)
              }
            }
          }
        }
      case "disconnect":
        NETunnelProviderManager.loadAllFromPreferences { managers, _ in
          managers?.first?.connection.stopVPNTunnel()
          result(true)
        }
      case "isRunning":
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
