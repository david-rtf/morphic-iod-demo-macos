//
//  DiskImages.swift
//  extractdmg
//
//  Created by David Stetz on 6/30/21.
//

/*
 using Hopper and opening hdiutil, searched for references to DIHLDiskImageAttach. Looking at sub_10002451e and finding the line where DIHLDiskImageAttach is being called, we see that it takes 4 parameters. the first parameter is a dictionary (rdi has been set to r15, r15 was set to a mutable CFDictionary), the second is a function pointer for a call back, the 3 parameter is being passed a null pointer, and the last parameter is a reference to a dictionary for the results to be returned.

 the first dictionary paramater has a number of key value pairs being set. They primary ones to be set are "agent" and "main-url". setting "agent" to "framework" causes the attach process to be silent, setting it to "dim" shows the standard ui expected when mounting a dmg. "main-url" is the path to the dmg as a URL.

 the second paramater is a point to a callback function that takes 3 paramaters, arg0, arg1, and arg2. arg0 is not used, arg1 is a dictionary.

 */
import Foundation

class DiskImages {
    typealias TestFunctionType = @convention(c) (Any, NSDictionary) -> Int
    typealias DIHLDiskImageAttachFunction = @convention(c) (CFDictionary, TestFunctionType?, UnsafeMutableRawPointer?, UnsafeMutablePointer<CFDictionary>) -> Void
    private var DIHLDiskImageAttach: DIHLDiskImageAttachFunction
    
    typealias DISetVerboseLevelFunction = @convention(c) (Int) -> Void
    private var DISetVerboseLevel: DISetVerboseLevelFunction
    
    typealias DISetDebugLevelFunction = @convention(c) (Int) -> Void
    private var DISetDebugLevel: DISetDebugLevelFunction
    
    private static let defaultInstance = DiskImages()
    
    public class var `default`: DiskImages {
        get {
            return defaultInstance
        }
    }
    
    private init() {
        let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/DiskImages.framework"))

        if (!CFBundleIsExecutableLoaded(bundle))
        {
            CFBundleLoadExecutable(bundle)
        }

        let DIHLDiskImageAttachPointer = CFBundleGetFunctionPointerForName(bundle, "DIHLDiskImageAttach" as CFString)
        
        DIHLDiskImageAttach = unsafeBitCast(DIHLDiskImageAttachPointer, to: DIHLDiskImageAttachFunction.self)
        
        let DISetVerboseLevelPointer = CFBundleGetFunctionPointerForName(bundle, "DISetVerboseLevel" as CFString)
        DISetVerboseLevel = unsafeBitCast(DISetVerboseLevelPointer, to: DISetVerboseLevelFunction.self)
        
        let DISetDebugLevelPointer = CFBundleGetFunctionPointerForName(bundle, "DISetDebugLevel" as CFString)
        DISetDebugLevel = unsafeBitCast(DISetDebugLevelPointer, to: DISetDebugLevelFunction.self)
        
        DISetVerboseLevel(1)
        DISetDebugLevel(1)
    }
    
    private func getMountPoint(dictionary: CFDictionary) -> String
    {
        // Example structure that is passed in
        /*
         {
             "system-entities" = [
                                     {
                                         "content-hint": "GUID_partition_scheme",
                                         "dev-entry": "/dev/disk4",
                                         "potentially-mountable": 0,
                                         "unmapped-content-hint": "GUID_partition_scheme"
                                     },
                                     {
                                         "content-hint": "EFI",
                                         "dev-entry": "/dev/disk4s1",
                                         "potentially-mountable": 1,
                                         "unmapped-content-hint": "C12A7328-F81F-11D2-BA4B-00A0C93EC93B",
                                         "volume-kind": "msdos"
                                     },
                                     {
                                         "content-hint": "Apple_HFS",
                                         "dev-entry": "/dev/disk4s2",
                                         "mount-point": "/Volumes/IntelliJ IDEA",
                                         "potentially-mountable": 1,
                                         "unmapped-content-hint": "48465300-0000-11AA-AA11-00306543ECAC",
                                         "volume-kind": "hfs"
                                     }
                                ]
             }
         */
        let response = dictionary as? [NSString: AnyObject]
        let systemEntities = response!["system-entities"] as! [Dictionary<String, AnyObject>]
        let filteredEntity = systemEntities.filter({$0["content-hint"] as! NSString == "Apple_HFS"}).first!
        let mountPoint = filteredEntity["mount-point"] as! String
        
        return mountPoint
    }
    
    public func attach(dmgPath: String) -> String {
        
        let input = [
                        "agent": "framework",
                        "main-url": URL(fileURLWithPath: dmgPath)
                    ] as CFDictionary
        
        var output = [String: AnyObject]() as CFDictionary
        
        DIHLDiskImageAttach(input, {(arg0, arg1) in
                print(arg1)
            
                return 0;
            }, nil, &output)
        
        return getMountPoint(dictionary: output)
    }
    
    public func detach(volumePath: String)
    {
        FileManager.default.unmountVolume(at: URL(fileURLWithPath: volumePath), options: [FileManager.UnmountOptions.allPartitionsAndEjectDisk, FileManager.UnmountOptions.withoutUI], completionHandler: {(_)in})
    }
}
