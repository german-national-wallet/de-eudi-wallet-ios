//
//  PresentationErrorNoticePreviewMocks.swift
//  feature-presentation
//

import Foundation
import logic_core
import logic_ui
import logic_resources
import feature_common

#if DEBUG
struct PreviewPIDRevokeInteractor: PIDRevokeInteractor {
  func deletePIDFromWallet() async throws {}
}

struct PreviewDeepLinkController: DeepLinkController {
  func hasDeepLink(url: URL) -> DeepLink.Executable? { nil }
  @MainActor func handleDeepLinkAction(
    routerHost: RouterHost,
    deepLinkExecutable: DeepLink.Executable,
    remoteSessionCoordinator: RemoteSessionCoordinator?
  ) {}
  func getPendingDeepLinkAction() -> DeepLink.Executable? { nil }
  func cacheDeepLinkURL(url: URL) {}
  func removeCachedDeepLinkURL() {}
  func isDeeplinkFlowActive() async -> Bool { false }
  func setDeeplinkFlowFlag(_ active: Bool) async {}
  func clearFirstRunFlag() async {}
}
#endif
