#import <objc/NSObject.h>

@interface IASFilesystemUtils : NSObject
{
}

+ (id)firmlinksOnTargetGivenPath:(id)arg1 isAppleInternal:(BOOL)arg2 requireTargetInSystemVolumeGroup:(BOOL)arg3 withOutSyntheticSymlinks:(id *)arg4;
+ (BOOL)isAPFSDataVolumeRoleGivenDiskIdentifier:(id)arg1;
+ (BOOL)isAPFSSystemVolumeRoleGivenDiskIdentifier:(id)arg1;
+ (id)volumePathGivenPath:(id)arg1;
+ (id)systemVolumePathGivenDataPath:(id)arg1;
+ (id)dataVolumePathGivenSystemPath:(id)arg1;
+ (BOOL)pathIsMemberOfReadOnlySystemGroup:(id)arg1;
+ (BOOL)pathIsMemberOfSystemDataVolumeGroup:(id)arg1;
+ (BOOL)pathIsMemberOfSystemDataVolumeGroup:(id)arg1 isDataRole:(char *)arg2 isSystemRole:(char *)arg3;
+ (id)volumePathForSystemOrDataGivenPath:(id)arg1 withRequestingDataVolume:(BOOL)arg2;
+ (id)devNodeForVolumeInContainer:(unsigned int)arg1 withGroup:(id)arg2 withRequestingDataVolume:(BOOL)arg3;
+ (unsigned int)newIOServiceFromDevNode:(id)arg1;
+ (id)getXattr:(id)arg1 forPath:(id)arg2;
+ (BOOL)isPathSafe:(id)arg1 ofType:(id)arg2 andOwnedByUID:(unsigned int)arg3 andGID:(unsigned int)arg4;
+ (BOOL)isPathSafe:(id)arg1 andOwnedByUID:(unsigned int)arg2 andGID:(unsigned int)arg3;
+ (BOOL)isPathSafe:(id)arg1;
+ (BOOL)isPathSymlinked:(id)arg1;
+ (BOOL)localizeParentFolderForBundleWithURL:(id)arg1;

@end
