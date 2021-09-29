import Foundation

@objc(HelperProtocol)
protocol HelperProtocol {
    func installPkg(withPath: String, completion: @escaping (NSNumber) -> Void)
    func installPkg(withPath: String, authData: NSData?, completion: @escaping (NSNumber) -> Void)
}
