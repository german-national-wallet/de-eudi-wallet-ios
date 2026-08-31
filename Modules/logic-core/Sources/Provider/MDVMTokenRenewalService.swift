//
//  MDVMTokenRenewalService.swift
//  logic-core
//

public protocol MDVMTokenRenewalService: Sendable {
  func renewMDVMTokenIgnoringFreshness() async throws
}
