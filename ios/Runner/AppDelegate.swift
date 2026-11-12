import Flutter
import UIKit
import NetworkExtension
import Darwin

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

  /// Checks live OS network interfaces for an active WireGuard / IPsec tunnel (`utun*` / `ipsec*`)
  /// carrying iMask's virtual subnet (`10.8.0.x` or `10.9.0.x`).
  private func isSystemWireGuardTunnelActive() -> Bool {
    var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddrPtr) == 0, let firstAddr = ifaddrPtr else {
      return false
    }
    defer { freeifaddrs(ifaddrPtr) }

    var cursor: UnsafeMutablePointer<ifaddrs>? = firstAddr
    while let ifa = cursor?.pointee {
      defer { cursor = ifa.ifa_next }
      let flags = Int32(ifa.ifa_flags)
      let isUp = (flags & (IFF_UP | IFF_RUNNING)) == (IFF_UP | IFF_RUNNING)
      guard isUp, let addr = ifa.ifa_addr else { continue }
      let name = String(cString: ifa.ifa_name)
      guard name.hasPrefix("utun") || name.hasPrefix("ipsec") else { continue }

      if addr.pointee.sa_family == UInt8(AF_INET) {
        var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let sockLen = socklen_t(addr.pointee.sa_len)
        if getnameinfo(addr, sockLen, &hostBuffer, socklen_t(hostBuffer.count), nil, 0, NI_NUMERICHOST) == 0 {
          let ip = String(cString: hostBuffer)
          if ip.hasPrefix("10.8.0.") || ip.hasPrefix("10.9.0.") {
            return true
          }
        }
      }
    }
    return false
  }

  private func hasEmbeddedPacketTunnelExtension() -> Bool {
    guard let pluginsUrl = Bundle.main.builtInPlugInsURL,
          let items = try? FileManager.default.contentsOfDirectory(atPath: pluginsUrl.path) else {
      return false
    }
    return items.contains { $0.hasSuffix(".appex") }
  }

  private func topViewController() -> UIViewController? {
    let windowScene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
      ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    var root = windowScene?.windows.first { $0.isKeyWindow }?.rootViewController
      ?? windowScene?.windows.first?.rootViewController
    while let presented = root?.presentedViewController {
      root = presented
    }
    return root
  }

  private func setupVpnChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: vpnChannelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate released", details: nil))
        return
      }

      switch call.method {
      case "prepareAndConnect":
        // First check if an external WireGuard / system VPN tunnel (10.8.0.x) is already up.
        if self.isSystemWireGuardTunnelActive() {
          result(true)
          return
        }

        // Only attempt in-app NETunnelProviderManager if a PacketTunnel .appex is bundled & signed.
        if !self.hasEmbeddedPacketTunnelExtension() {
          result(
            FlutterError(
              code: "IOS_TUNNEL_SETUP_REQUIRED",
              message: "iOS VPN tunnel is not active yet. Import iMask-VPN.conf in WireGuard and turn it ON.",
              details: nil
            )
          )
          return
        }

        let args = call.arguments as? [String: Any]
        let serverName = args?["serverName"] as? String ?? "iMask VPN"
        let serverIp = args?["serverIp"] as? String ?? "129.225.114.149"

        NETunnelProviderManager.loadAllFromPreferences { managers, loadErr in
          if let loadErr = loadErr {
            result(FlutterError(code: "IOS_NE_LOAD_ERROR", message: loadErr.localizedDescription, details: nil))
            return
          }

          let manager = managers?.first ?? NETunnelProviderManager()
          let proto = NETunnelProviderProtocol()
          proto.providerBundleIdentifier = "\(Bundle.main.bundleIdentifier ?? "com.imask.vpn.imaskVpn").PacketTunnel"
          proto.serverAddress = serverIp
          manager.protocolConfiguration = proto
          manager.localizedDescription = "iMask VPN (\(serverName))"
          manager.isEnabled = true

          manager.saveToPreferences { saveErr in
            if let saveErr = saveErr {
              result(FlutterError(code: "IOS_NE_SAVE_ERROR", message: saveErr.localizedDescription, details: nil))
              return
            }
            manager.loadFromPreferences { reloadErr in
              if let reloadErr = reloadErr {
                result(FlutterError(code: "IOS_NE_RELOAD_ERROR", message: reloadErr.localizedDescription, details: nil))
                return
              }
              do {
                try manager.connection.startVPNTunnel()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                  let active = self.isSystemWireGuardTunnelActive()
                    || manager.connection.status == .connected
                  if active {
                    result(true)
                  } else {
                    result(
                      FlutterError(
                        code: "IOS_NE_START_FAILED",
                        message: "VPN tunnel did not become active.",
                        details: nil
                      )
                    )
                  }
                }
              } catch {
                result(FlutterError(code: "IOS_NE_START_ERROR", message: error.localizedDescription, details: nil))
              }
            }
          }
        }

      case "disconnect":
        if self.hasEmbeddedPacketTunnelExtension() {
          NETunnelProviderManager.loadAllFromPreferences { managers, _ in
            managers?.first?.connection.stopVPNTunnel()
            result(true)
          }
          return
        }

        if self.isSystemWireGuardTunnelActive() {
          result(
            FlutterError(
              code: "IOS_MANUAL_DISCONNECT",
              message: "Turn off VPN from WireGuard or iOS Settings > VPN to disconnect completely.",
              details: nil
            )
          )
        } else {
          result(true)
        }

      case "isRunning":
        result(self.isSystemWireGuardTunnelActive())

      case "shareWireGuardConfig":
        let args = call.arguments as? [String: Any]
        guard let config = args?["config"] as? String, !config.isEmpty else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing WireGuard config", details: nil))
          return
        }
        DispatchQueue.main.async {
          let fileUrl = FileManager.default.temporaryDirectory.appendingPathComponent("iMask-VPN.conf")
          do {
            try config.write(to: fileUrl, atomically: true, encoding: .utf8)
            guard let presenter = self.topViewController() else {
              result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Unable to present Share Sheet", details: nil))
              return
            }
            let activityVC = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = presenter.view
            activityVC.popoverPresentationController?.sourceRect = CGRect(
              x: presenter.view.bounds.midX,
              y: presenter.view.bounds.midY,
              width: 0,
              height: 0
            )
            presenter.present(activityVC, animated: true) {
              result(true)
            }
          } catch {
            result(FlutterError(code: "FILE_WRITE_ERROR", message: error.localizedDescription, details: nil))
          }
        }

      case "openExternalUrl":
        let args = call.arguments as? [String: Any]
        guard let urlStr = args?["url"] as? String, let url = URL(string: urlStr) else {
          result(false)
          return
        }
        DispatchQueue.main.async {
          UIApplication.shared.open(url, options: [:]) { ok in
            result(ok)
          }
        }

      case "openVpnSettings":
        DispatchQueue.main.async {
          let settingsUrl = URL(string: UIApplication.openSettingsURLString)
          if let vpnPrefsUrl = URL(string: "App-Prefs:VPN") {
            UIApplication.shared.open(vpnPrefsUrl, options: [:]) { ok in
              if !ok, let fallback = settingsUrl {
                UIApplication.shared.open(fallback, options: [:], completionHandler: nil)
              }
              result(true)
            }
          } else if let fallback = settingsUrl {
            UIApplication.shared.open(fallback, options: [:]) { ok in
              result(ok)
            }
          } else {
            result(false)
          }
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
