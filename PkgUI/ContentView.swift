import SwiftUI
import Darwin
import Foundation
import ServiceManagement

public let geteuid       = Darwin.geteuid
public let getegid       = Darwin.getegid

public let getuid        = Darwin.getuid
public let getgid        = Darwin.getgid

class DelegateHandler: ObservableObject, IFDInstallDelegate, AppProtocol {
    @Published var progressValue: Double = 0.0
    @Published var message: String?
    @Published var dmgMountPoint: String?
    @Published var canInstall: Bool = false
    @Published var installing: Bool = false
    
    var pkg: IFDocument?
    
    var currentHelperConnection: NSXPCConnection?
    
    func log(stdOut: String) {
        guard !stdOut.isEmpty else { return }
        OperationQueue.main.addOperation {
            self.message = stdOut
        }
    }

    func log(stdErr: String) {
        guard !stdErr.isEmpty else { return }
        OperationQueue.main.addOperation {
            self.message = stdErr
        }
    }
    
    func installStarted() {
        self.installing = true
        print("installStarted")
    }
    
    func installPhase(phase: String) {
        self.message = phase
        print("installPhase: \(phase ?? "nil")")
    }
    
    func installFinished() {
        self.canInstall = false
        self.installing = false
    }
    
    func reportProgress(progress: Double) {
        self.progressValue = progress
        print("installPercentageComplete: \(progress)%")
    }
    
    func helperConnection() -> NSXPCConnection? {
        guard self.currentHelperConnection == nil else {
            return self.currentHelperConnection
        }

        let connection = NSXPCConnection(machServiceName: HelperConstants.machServiceName, options: .privileged)
        connection.exportedInterface = NSXPCInterface(with: AppProtocol.self)
        connection.exportedObject = self
        connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
        connection.invalidationHandler = {
            self.currentHelperConnection?.invalidationHandler = nil
            OperationQueue.main.addOperation {
                self.message = "helper connection invalidated."
                self.currentHelperConnection = nil
            }
        }

        self.currentHelperConnection = connection
        self.currentHelperConnection?.resume()

        return self.currentHelperConnection
    }
    
    func helperInstall() throws -> Bool {

        // Install and activate the helper inside our application bundle to disk.

        var cfError: Unmanaged<CFError>?
        return try kSMRightBlessPrivilegedHelper.withCString
        {
            var authItem = AuthorizationItem(name: $0, valueLength: 0, value:UnsafeMutableRawPointer(bitPattern: 0), flags: 0)
            return try withUnsafeMutablePointer(to: &authItem)
            {
                var authRights = AuthorizationRights(count: 1, items: $0)

                guard
                    let authRef = try HelperAuthorization.authorizationRef(&authRights, nil, [.interactionAllowed, .extendRights, .preAuthorize]),
                    SMJobBless(kSMDomainSystemLaunchd, HelperConstants.machServiceName as CFString, authRef, &cfError) else {
                        if let error = cfError?.takeRetainedValue() { throw error }
                        return false
                }

                self.currentHelperConnection?.invalidate()
                self.currentHelperConnection = nil

                return true
            }
        }
    }

    func helper(_ completion: ((Bool) -> Void)?) -> HelperProtocol? {
        guard let helper = self.helperConnection()?.remoteObjectProxyWithErrorHandler({ error in
            self.message = "Helper connection was closed with error: \(error)"
            if let onCompletion = completion { onCompletion(false) }
        }) as? HelperProtocol else { return nil }
        return helper
    }
    
    func openPkg (packagePath: String) {
        DispatchQueue.main.async {
            let r = IASFilesystemUtils.pathIsMember(ofSystemDataVolumeGroup: "/", isDataRole: nil, isSystemRole: nil) //] != 0x0) && (var_2B != 0x0))
            let path = IASFilesystemUtils.systemVolumePath(givenDataPath: "/")
            
            print("systemVolumePath: '\(path ?? "nil")', r: '\(r)'")
            let document = IFDocument.document(withPath: packagePath)
            self.pkg = document as? IFDocument
            
            if(self.pkg != nil) {
                self.canInstall = true
                self.message = "Ready to install '\(self.pkg?.title() as? String ?? "Unknown Package Title")'"
            } else {
                self.canInstall = false
                self.message = "Not a valid package."
            }
        }
    }
    
    func install() {
        guard
            let inputPath = self.pkg?.path() as? String,
            let helper = self.helper(nil) else { return }
        
        do {
            guard let authData = try HelperAuthorization.emptyAuthorizationExternalFormData() else {
                self.message = "Failed to get the empty authorization external form"
                return
            }

            helper.installPkg(withPath: inputPath, authData: authData) { (exitCode) in
                OperationQueue.main.addOperation {

                    // Verify that authentication was successful

                    guard exitCode != kAuthorizationFailedExitCode else {
                        self.message = "Authentication Failed"
                        return
                    }

                    self.message = "Command exit code: \(exitCode)"
                    /*
                    if self.checkboxCacheAuthentication.state == .on, self.currentHelperAuthData == nil {
                        self.currentHelperAuthData = authData
                        self.textFieldAuthorizationCached.stringValue = "Yes"
                        self.buttonDestroyCachedAuthorization.isEnabled = true
                    }
                    */

                }
            }
        } catch {
            self.message = "Command failed with error: \(error)"
        }
        //var error: AnyObject!
/*
        let b = IFDInstallController(distribution: pkg)
        let valid = pkg!.readAndValidateReturningError(&error)
        
        if(valid) {
            let availableInstallDomains = pkg?.availableInstallDomains()
            //var distribution = b?.distribution();
            let homeDirectory = NSHomeDirectory();
            print("availableInstallDomains: '\(availableInstallDomains ?? 0)', homeDirectory: '\(homeDirectory)'")
            //homeDirectory.resolvingSymlinksInPath()
            
            
            let targetController = b?.targetController() as? IFDTargetController
            if(targetController != nil) {
                let target = targetController?.target(forDomain: 0x2) as? IFDTarget
                targetController?.wait(untilTargetProcessed: target)
                
                let euid = geteuid()
                let egid = getegid()
                
                let uid = getuid()
                let gid = getgid()
                
                print("uid: \(uid), gid: \(gid), euid: \(euid), egid: \(egid)")
                
                if(euid == 0) {
                    
                } else {
                    b?.setForceNoAuthInstall(true)
                    target?.setStatus(0x2)
                }
                
                b?.setTarget(target)
                b?.setDelegate(self)
                //b?.customizationController(forTarget: target)
                pkg?.setMinimumRequiredTrustLevel(0x64)
                pkg?.evaluateTrust()
                let trustLevel = pkg?.trustLevelReturningTrustRef(nil)
                if trustLevel! > 0x63 {
                    
                }
                b?.startInstall()
            } else {
                print("There was an unknown error while attempting to install package.")
            }
        } else {
            self.message = "Invalid package."
        }
 */
    }
    
    func cancel() {
        if !self.installing {
            self.message = nil
            self.pkg = nil
            self.canInstall = false
        }
        
        detachDMG()
    }
    
    func detachDMG() {
        if self.dmgMountPoint != nil {
            DiskImages.default.detach(volumePath: self.dmgMountPoint!)
            self.dmgMountPoint = nil
            self.message = nil
        }
    }
    
    func installRequestedMediaAccepted(_ arg1: Bool, forInstallDocument arg2: IFDocument!) {
        print("installRequestedMediaAccepted")
    }
    
    func installRequestMedia(_ arg1: String!, forInstallDocument arg2: IFDocument!) {
        print("installRequestMedia: \(arg1 ?? "nil")")
    }
    
    func installError(_ arg1: Error!, forInstallDocument arg2: IFDocument!) {
        print("installError: \(arg1)")
    }
    
    func installTimeRemaining(_ arg1: String!, forInstallDocument arg2: IFDocument!) {
        print("installTimeRemaining: \(arg1 ?? "nil")")
    }
    
    func installPercentageComplete(_ arg1: Double, forInstallDocument arg2: IFDocument!) {
        self.progressValue = arg1
        print("installPercentageComplete: \(arg1)%")
    }
    
    func installPhase(_ arg1: String!, forInstallDocument arg2: IFDocument!) {
        self.message = arg1
        print("installPhase: \(arg1 ?? "nil")")
    }
    
    func installStatus(_ arg1: String!, forInstallDocument arg2: IFDocument!) {
        print("installStatus: \(arg1 ?? "nil")")
    }
    
    func installFinished(forInstallDocument arg1: IFDocument!) {
        self.canInstall = false
        self.installing = false
        print("The installation was successful.")
        
        detachDMG()
        
        self.message = "The installation was successful."
    }
    
    func installStarted(forInstallDocument arg1: IFDocument!) {
        self.installing = true
        print("installStarted")
    }
}

struct ContentView: View {
    @State var progressValue: Double = 0.0
    
    @State var pkg: IFDocument?
    
    @ObservedObject var delegateHandler = DelegateHandler()
    
    var body: some View {
        VStack {
            Text(delegateHandler.message ?? "Select a valid package.")
                .frame(width: 400)
            
            if delegateHandler.canInstall == false {
                HStack {
                    Button(action: {
                        self.openPackage()
                    }) {
                        Text("Open Package")
                    }
                    
                    Button(action: {
                        if delegateHandler.dmgMountPoint == nil {
                            self.mountDMG()
                        } else {
                            delegateHandler.detachDMG()
                        }
                    }) {
                        if delegateHandler.dmgMountPoint == nil {
                            Text("Mount DMG")
                        } else {
                            Text("Detach DMG")
                        }
                    }
                    
                    if delegateHandler.dmgMountPoint != nil {
                        Button(action: {
                            do
                            {
                                let fileList = try FileManager.default.contentsOfDirectory(at: URL.init(fileURLWithPath: delegateHandler.dmgMountPoint!), includingPropertiesForKeys: nil)
                                let appFiles = fileList.filter { $0.pathExtension.contains("app") }
                                let pkgFiles = fileList.filter{ $0.pathExtension.contains("pkg") }
                                
                                if appFiles.count > 0 {
                                    if let appBundle = appFiles.first {
                                        print(appBundle)
                                        let destination = URL(fileURLWithPath: "/Applications").appendingPathComponent(appBundle.lastPathComponent)
                                        if(FileManager.default.fileExists(atPath: destination.path))
                                        {
                                            try FileManager.default.removeItem(at: destination)
                                        }

                                        try FileManager.default.copyItem(at: appBundle, to: destination)
                                    }
                                } else if pkgFiles.count > 0 {
                                    if let pkgFile = pkgFiles.first {
                                        print(pkgFile)
                                        let path = pkgFile.path
                                        delegateHandler.message = path
                                        delegateHandler.openPkg(packagePath: path)
                                    }
                                }
                            }
                            catch
                            {
                                print(error)
                            }
                        }) {
                            Text("Install from DMG")
                        }
                    }
                    
                    Button(action: {
                        do {
                            if try delegateHandler.helperInstall() {
                                delegateHandler.message = "Installed helper."
                            } else {
                                delegateHandler.message = "Unable to install helper."
                            }
                        } catch {
                            delegateHandler.message = "An exception occured: \(error)."
                            print(error)
                        }
                        
                    }, label: {
                        Text("Install Helper")
                    })
                }
            } else {
                ProgressBarView(value: $delegateHandler.progressValue).frame(height: 20)

                HStack {
                    Button(action: {
                        delegateHandler.install()
                    }) {
                        Text("Install Package")
                    }
                    .disabled(delegateHandler.installing)
                    
                    Button(action: {
                        delegateHandler.cancel()
                    }) {
                        Text("Cancel")
                    }
                    .disabled(delegateHandler.installing)
                }
            }
        }.padding()
    }
        
    func mountDMG() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedFileTypes = ["dmg"]
        if panel.runModal() == .OK && panel.url?.path != nil {
            delegateHandler.dmgMountPoint = DiskImages.default.attach(dmgPath: panel.url!.path)
            
            if delegateHandler.dmgMountPoint != nil {
                delegateHandler.message = "Successfully mounted DMG to '\(delegateHandler.dmgMountPoint!)'."
            } else {
                delegateHandler.message = "Unable to mount DMG."
            }
        } else {
            delegateHandler.message = "Invalid dmg."
        }
    }
    
    func openPackage() {
        let euid = geteuid()
        let egid = getegid()
        
        let uid = getuid()
        let gid = getgid()
        
        print("uid: \(uid), gid: \(gid), euid: \(euid), egid: \(egid)")
        
        if(euid == 0) {
            
        }
        
        self.resetProgressBar()
        
        let panel = NSOpenPanel()
        
        if delegateHandler.dmgMountPoint != nil {
            panel.directoryURL = URL.init(fileURLWithPath: delegateHandler.dmgMountPoint!, isDirectory: true)
        }
        
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedFileTypes = ["pkg"]
        if panel.runModal() == .OK && panel.url?.path != nil {
            let path = panel.url!.path
            delegateHandler.message = path
            delegateHandler.openPkg(packagePath: path)
        } else {
            delegateHandler.message = "Invalid package."
        }
    }
    
    func resetProgressBar() {
        self.progressValue = 0.0
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
