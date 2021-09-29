import Foundation

class Helper: NSObject, NSXPCListenerDelegate, HelperProtocol, IFDInstallDelegate {

    private let listener: NSXPCListener

    private var connections = [NSXPCConnection]()
    private var shouldQuit = false
    private var shouldQuitCheckInterval = 1.0

    override init() {
        self.listener = NSXPCListener(machServiceName: HelperConstants.machServiceName)
        super.init()
        self.listener.delegate = self
    }

    public func run() {
        self.listener.resume()

        while !self.shouldQuit {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: self.shouldQuitCheckInterval))
        }
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {

        guard self.isValid(connection: connection) else {
            return false
        }

        connection.remoteObjectInterface = NSXPCInterface(with: AppProtocol.self)

        connection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
        connection.exportedObject = self

        connection.invalidationHandler = {
            if let connectionIndex = self.connections.firstIndex(of: connection) {
                self.connections.remove(at: connectionIndex)
            }

            if self.connections.isEmpty {
                self.shouldQuit = true
            }
        }

        self.connections.append(connection)
        connection.resume()

        return true
    }

    func installPkg(withPath path: String, completion: @escaping (NSNumber) -> Void) {
        writeLog(message: "installPkg called.")

        var error: AnyObject!
        
        writeLog(message: "Getting package for \(path)")

        let pkg = IFDocument.document(withPath: path) as? IFPKGDerivedDocument
        
        let b = IFDInstallController(distribution: pkg)
        let valid = pkg!.readAndValidateReturningError(&error)
        
        if(valid) {
            let targetController = b?.targetController() as? IFDTargetController
            if(targetController != nil) {
                writeLog(message: "targetController")
                let target = targetController?.target(forDomain: 0x2) as? IFDTarget
                writeLog(message: "Waiting.")
                targetController?.wait(untilTargetProcessed: target)
                writeLog(message: "Done Waiting.")
                
                //b?.setForceNoAuthInstall(false)
                target?.setStatus(0x2)
                b?.setTarget(target)
                b?.setDelegate(self)
                //b?.customizationController(forTarget: target)
                pkg?.setMinimumRequiredTrustLevel(0x64)
                pkg?.evaluateTrust()
                let trustLevel = pkg?.trustLevelReturningTrustRef(nil)
                if trustLevel! == 0x64 {
                    writeLog(message: "trustLevel == 0x64")

                    pkg?.setMinimumRequiredTrustLevel(0x2)
                }
                
                writeLog(message: "Installing...")

                b?.startInstall()
                RunLoop.current.run()
                
                writeLog(message: "Done installing.")
            } else {
                writeLog(message: "There was an unknown error while attempting to install package.")
            }
        } else {
            writeLog(message: "Invalid package.")
        }
    }
    
    func writeLog(message: String) {
        if let remoteObject = self.connection()?.remoteObjectProxy as? AppProtocol {
            remoteObject.log(stdOut: message)
        }
    }
    
    func installPkg(withPath path: String, authData: NSData?, completion: @escaping (NSNumber) -> Void) {

        guard self.verifyAuthorization(authData, forCommand: #selector(HelperProtocol.installPkg(withPath:authData:completion:))) else {
            writeLog(message: "verifyAuthorization failed.")

            completion(kAuthorizationFailedExitCode)
            return
        }
        
        self.installPkg(withPath: path, completion: completion)
    }
    
    func installRequestedMediaAccepted(_ arg1: Bool, forInstallDocument arg2: IFDocument!) {
        writeLog(message: "installRequestedMediaAccepted")
        
        print("installRequestedMediaAccepted")
    }
    
    func installRequestMedia(_ arg1: String!, forInstallDocument arg2: IFDocument!) {
        writeLog(message: "installRequestMedia: \(arg1 ?? "nil")")

        print("installRequestMedia: \(arg1 ?? "nil")")
    }
    
    func installError(_ arg1: Error!, forInstallDocument arg2: IFDocument!) {
        writeLog(message: "installError: \(arg1?.localizedDescription ?? "nil")")

        print("installError: \(arg1?.localizedDescription ?? "nil")")
    }
    
    func installTimeRemaining(_ arg1: String!, forInstallDocument arg2: IFDocument!) {
        writeLog(message: "installTimeRemaining: \(arg1 ?? "nil")")

        print("installTimeRemaining: \(arg1 ?? "nil")")
    }
    
    func installPercentageComplete(_ arg1: Double, forInstallDocument arg2: IFDocument!) {
        writeLog(message: "installPercentageComplete: \(arg1)%")
        
        if let remoteObject = self.connection()?.remoteObjectProxy as? AppProtocol {
            remoteObject.reportProgress(progress: arg1)
        }

        //self.progressValue = arg1
        //print("installPercentageComplete: \(arg1)%")
    }
    
    func installPhase(_ arg1: String!, forInstallDocument arg2: IFDocument!) {
        writeLog(message: "installPhase: \(arg1 ?? "nil")")

        if let remoteObject = self.connection()?.remoteObjectProxy as? AppProtocol {
            remoteObject.installPhase(phase: arg1)
        }
        
        //self.message = arg1
        print("installPhase: \(arg1 ?? "nil")")
    }
    
    func installStatus(_ arg1: String!, forInstallDocument arg2: IFDocument!) {
        writeLog(message: "installStatus: \(arg1 ?? "nil")")

        print("installStatus: \(arg1 ?? "nil")")
    }
    
    func installFinished(forInstallDocument arg1: IFDocument!) {
        writeLog(message: "The installation was successful.")

        if let remoteObject = self.connection()?.remoteObjectProxy as? AppProtocol {
            remoteObject.installFinished()
        }
        
        //self.canInstall = false
        //self.installing = false
        print("The installation was successful.")
        //exit(0)
        //detachDMG()
        
        //self.message = "The installation was successful."
    }
    
    func installStarted(forInstallDocument arg1: IFDocument!) {
        writeLog(message: "installStarted")

        if let remoteObject = self.connection()?.remoteObjectProxy as? AppProtocol {
            remoteObject.installStarted()
        }
        
        //self.installing = true
        print("installStarted")
    }

    private func isValid(connection: NSXPCConnection) -> Bool {
        do {
            return try CodesignCheck.codeSigningMatches(pid: connection.processIdentifier)
        } catch {
            writeLog(message: "Code signing check failed with error: \(error)")
            NSLog("Code signing check failed with error: \(error)")
            return false
        }
    }

    private func verifyAuthorization(_ authData: NSData?, forCommand command: Selector) -> Bool {
        do {
            try HelperAuthorization.verifyAuthorization(authData, forCommand: command)
        } catch {
            writeLog(message: "Authentication Error: \(error)")

            return false
        }
        return true
    }

    private func connection() -> NSXPCConnection? {
        return self.connections.last
    }

    private func runTask(command: String, arguments: Array<String>, completion:@escaping ((NSNumber) -> Void)) -> Void {
        let task = Process()
        let stdOut = Pipe()

        let stdOutHandler =  { (file: FileHandle!) -> Void in
            let data = file.availableData
            guard let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return }
            if let remoteObject = self.connection()?.remoteObjectProxy as? AppProtocol {
                remoteObject.log(stdOut: output as String)
            }
        }
        stdOut.fileHandleForReading.readabilityHandler = stdOutHandler

        let stdErr:Pipe = Pipe()
        let stdErrHandler =  { (file: FileHandle!) -> Void in
            let data = file.availableData
            guard let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return }
            if let remoteObject = self.connection()?.remoteObjectProxy as? AppProtocol {
                remoteObject.log(stdErr: output as String)
            }
        }
        stdErr.fileHandleForReading.readabilityHandler = stdErrHandler

        task.launchPath = command
        task.arguments = arguments
        task.standardOutput = stdOut
        task.standardError = stdErr

        task.terminationHandler = { task in
            completion(NSNumber(value: task.terminationStatus))
        }

        task.launch()
    }
}
