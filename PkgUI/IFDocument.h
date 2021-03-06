/*
 *     Generated by class-dump 3.3.4 (64 bit).
 *
 *     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2011 by Steve Nygard.
 */

#import <objc/NSObject.h>

@interface IFDocument : NSObject
{
    struct IFDocument_Private *_private;
}

+ (id)documentWithPath:(id)arg1;
+ (id)fileURLForURL:(id)arg1;
+ (id)canonicalURLForPath:(id)arg1;
+ (id)localizedStringForKey:(id)arg1;
+ (id)localizedFormattedStringForKey:(id)arg1;
//+ (id)localizedFormattedStringForKey:(id)arg1 withArguments:(struct __va_list_tag [1])arg2;
+ (id)distributionWithPackages:(id)arg1 andTitle:(id)arg2;
+ (id)createXMLDataToInstallPackages:(id)arg1 andTitle:(id)arg2;
+ (id)distributionWithXML:(id)arg1 withBundlePath:(id)arg2;
+ (id)softwareUpdateDocumentFromPath:(id)arg1;
+ (id)softwareUpdateDocumentFromXML:(id)arg1 withBundlePath:(id)arg2;
- (id)objectForOptionNamed:(id)arg1;
- (BOOL)getData:(id *)arg1 andMIMEType:(id *)arg2 forResourceNamed:(id)arg3 forLanguage:(id)arg4;
- (BOOL)getData:(id *)arg1 andMIMEType:(id *)arg2 forResourceNamed:(id)arg3;
- (BOOL)containsResourceNamed:(id)arg1;
- (BOOL)canLoadResourceNamed:(id)arg1;
- (id)languagesAvailableForResource:(id)arg1;
- (id)versionString;
- (id)title;
- (id)locationURL;
- (id)path;
- (void)dealloc;
- (id)init;
- (id)installableCheckResults;
- (BOOL)readAndValidateDocumentReturningError:(id *)arg1;
- (BOOL)hasInsecureChecks;
- (void)_setPath:(id)arg1;
- (id)installerSectionPaths;
- (id)installerSectionOrder;
- (BOOL)containsChoicesWhichCanChooseSubFolder;
- (int)trustLevelReturningTrustRef:(struct __SecTrust **)arg1;
- (int)trustLevelReturningCertificateChain:(id *)arg1;
- (BOOL)evaluateTrust;
- (void)setMinimumRequiredTrustLevel:(int)arg1;
- (int)minimumRequiredTrustLevel;
- (id)certificateIdentity;
- (BOOL)isForSoftwareUpdate;
- (BOOL)shouldCreateRecoverySystem;
- (BOOL)shouldCopyPackagesBeforeInstall;
- (BOOL)isFNI;
- (BOOL)installsOperatingSystem;
- (void)setAllowInsecureOverride:(BOOL)arg1;
- (BOOL)evaluateAgainstPredicateFile:(id)arg1 returningMatchDictionary:(id *)arg2;
- (id)predicateEvaluationContext;
- (id)localizedStringForKey:(id)arg1;
- (BOOL)allURLsAccessibleAtRequestedAuthorizationLevel;
- (id)searchDefinitions;
- (id)errorForPackage:(id)arg1 onTarget:(id)arg2 withCustomizationController:(id)arg3;
- (id)receiptForPackage:(id)arg1 onVolumeOrHomeDir:(id)arg2;
- (id)packageForIdentifier:(id)arg1 withVersion:(id)arg2;
- (id)packagesForIdentifier:(id)arg1;
- (id)packageForUniqueIdentifier:(id)arg1;
- (void)addPackage:(id)arg1;
- (id)_distributionScriptsPath;
- (id)packagesForLocation:(id)arg1 fromSet:(id)arg2;
- (id)jobVersionForLocation:(id)arg1;
- (id)jobTitleForLocation:(id)arg1;
- (id)packagesForLocation:(id)arg1;
- (id)sortedPackageLocations;
- (id)packageReps;
- (id)defaultSubFolder;
- (BOOL)canChooseSubFolder;
- (int)enabledInstallDomains;
- (int)availableInstallDomains;
- (BOOL)isDomainInstall;
- (id)copyChoiceTreeWithScripts:(id *)arg1 andChoiceList:(id *)arg2 forTarget:(id)arg3;

@end

