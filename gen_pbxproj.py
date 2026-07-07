#!/usr/bin/env python3
"""
Generates PhotoCaptionLayer.xcodeproj/project.pbxproj for the
PhotoCaptionLayer SwiftUI iOS app.

Run from the folder that contains this script:
    python3 gen_pbxproj.py
"""

import os

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
PBXPROJ_PATH = os.path.join(PROJECT_ROOT, "PhotoCaptionLayer.xcodeproj", "project.pbxproj")
SCHEME_PATH = os.path.join(
    PROJECT_ROOT,
    "PhotoCaptionLayer.xcodeproj",
    "xcshareddata",
    "xcschemes",
    "PhotoCaptionLayer.xcscheme",
)

TARGET_NAME = "PhotoCaptionLayer"
BUNDLE_ID = "com.photocaptionlayer.app"

GROUPS = {
    "App": ["PhotoCaptionLayerApp.swift"],
    "Models": ["Caption.swift", "AppEnums.swift"],
    "Utils": ["Constants.swift", "Logger.swift"],
    "Services": [
        "PhotoLibraryService.swift",
        "OCRService.swift",
        "CaptionService.swift",
        "PhotoWriterService.swift",
    ],
    "ViewModels": ["EditorViewModel.swift"],
    "Views": ["PhotoPickerView.swift", "EditorView.swift", "SuccessView.swift"],
    "Views/Components": ["PhotoThumbnailView.swift", "CaptionFieldView.swift"],
}

SOURCE_FILES = [
    os.path.join(group, name).replace("\\", "/")
    for group, names in GROUPS.items()
    for name in names
]

RESOURCES = ["Resources/Assets.xcassets"]
INFO_PLIST = "Resources/Info.plist"


class IDGen:
    def __init__(self):
        self.counter = 0x10000000

    def next(self):
        self.counter += 1
        return f"{self.counter:024X}"


ids = IDGen()
ID_PROJECT = ids.next()
ID_MAIN_GROUP = ids.next()
ID_PRODUCTS_GROUP = ids.next()
ID_TARGET_GROUP = ids.next()
ID_APP_GROUP = ids.next()
ID_MODELS_GROUP = ids.next()
ID_UTILS_GROUP = ids.next()
ID_SERVICES_GROUP = ids.next()
ID_VIEWMODELS_GROUP = ids.next()
ID_VIEWS_GROUP = ids.next()
ID_COMPONENTS_GROUP = ids.next()
ID_RESOURCES_GROUP = ids.next()
ID_TARGET = ids.next()
ID_PRODUCT_REF = ids.next()
ID_SOURCES_PHASE = ids.next()
ID_RESOURCES_PHASE = ids.next()
ID_FRAMEWORKS_PHASE = ids.next()
ID_PROJECT_CONFIG_LIST = ids.next()
ID_TARGET_CONFIG_LIST = ids.next()
ID_CONFIG_DEBUG_PROJECT = ids.next()
ID_CONFIG_RELEASE_PROJECT = ids.next()
ID_CONFIG_DEBUG_TARGET = ids.next()
ID_CONFIG_RELEASE_TARGET = ids.next()

GROUP_ID_MAP = {
    "App": ID_APP_GROUP,
    "Models": ID_MODELS_GROUP,
    "Utils": ID_UTILS_GROUP,
    "Services": ID_SERVICES_GROUP,
    "ViewModels": ID_VIEWMODELS_GROUP,
    "Views": ID_VIEWS_GROUP,
    "Views/Components": ID_COMPONENTS_GROUP,
}


def quote(value):
    return '"' + value.replace('"', '\\"') + '"'


def file_type(path):
    if path.endswith(".swift"):
        return "sourcecode.swift"
    if path.endswith(".plist"):
        return "text.plist.xml"
    if path.endswith(".xcassets"):
        return "folder.assetcatalog"
    return "text"


def make_refs():
    refs = {}
    builds = {}
    all_paths = SOURCE_FILES + [INFO_PLIST] + RESOURCES
    for p in all_paths:
        refs[p] = ids.next()
    for p in SOURCE_FILES + RESOURCES:
        builds[p] = ids.next()
    return refs, builds


def group_children_for(group, refs):
    children = []
    for name in GROUPS[group]:
        path = os.path.join(group, name).replace("\\", "/")
        children.append((refs[path], name))
    return children


def main():
    refs, builds = make_refs()
    lines = []
    a = lines.append

    a("// !$*UTF8*$!")
    a("{")
    a("\tarchiveVersion = 1;")
    a("\tclasses = {")
    a("\t};")
    a("\tobjectVersion = 56;")
    a("\tobjects = {")
    a("")

    a("/* Begin PBXBuildFile section */")
    for p in SOURCE_FILES:
        a(f"\t\t{builds[p]} /* {os.path.basename(p)} in Sources */ = {{isa = PBXBuildFile; fileRef = {refs[p]} /* {os.path.basename(p)} */; }};")
    for p in RESOURCES:
        a(f"\t\t{builds[p]} /* {os.path.basename(p)} in Resources */ = {{isa = PBXBuildFile; fileRef = {refs[p]} /* {os.path.basename(p)} */; }};")
    a("/* End PBXBuildFile section */")
    a("")

    a("/* Begin PBXFileReference section */")
    for p in SOURCE_FILES:
        name = os.path.basename(p)
        a(f"\t\t{refs[p]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type(p)}; name = {name}; path = {name}; sourceTree = \"<group>\"; }};")
    a(f"\t\t{refs[INFO_PLIST]} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; name = Info.plist; path = Info.plist; sourceTree = \"<group>\"; }};")
    for p in RESOURCES:
        name = os.path.basename(p)
        a(f"\t\t{refs[p]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; name = {name}; path = {name}; sourceTree = \"<group>\"; }};")
    a(f"\t\t{ID_PRODUCT_REF} /* {TARGET_NAME}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {TARGET_NAME}.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    a("/* End PBXFileReference section */")
    a("")

    a("/* Begin PBXFrameworksBuildPhase section */")
    a(f"\t\t{ID_FRAMEWORKS_PHASE} /* Frameworks */ = {{")
    a("\t\t\tisa = PBXFrameworksBuildPhase;")
    a("\t\t\tbuildActionMask = 2147483647;")
    a("\t\t\tfiles = (")
    a("\t\t\t);")
    a("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    a("\t\t};")
    a("/* End PBXFrameworksBuildPhase section */")
    a("")

    a("/* Begin PBXGroup section */")
    for group in ["App", "Models", "Utils", "Services", "ViewModels"]:
        gid = GROUP_ID_MAP[group]
        a(f"\t\t{gid} /* {group} */ = {{")
        a("\t\t\tisa = PBXGroup;")
        a("\t\t\tchildren = (")
        for cid, name in group_children_for(group, refs):
            a(f"\t\t\t\t{cid} /* {name} */,")
        a("\t\t\t);")
        a(f"\t\t\tpath = {group};")
        a("\t\t\tsourceTree = \"<group>\";")
        a("\t\t};")

    a(f"\t\t{ID_COMPONENTS_GROUP} /* Components */ = {{")
    a("\t\t\tisa = PBXGroup;")
    a("\t\t\tchildren = (")
    for cid, name in group_children_for("Views/Components", refs):
        a(f"\t\t\t\t{cid} /* {name} */,")
    a("\t\t\t);")
    a("\t\t\tpath = Components;")
    a("\t\t\tsourceTree = \"<group>\";")
    a("\t\t};")

    a(f"\t\t{ID_VIEWS_GROUP} /* Views */ = {{")
    a("\t\t\tisa = PBXGroup;")
    a("\t\t\tchildren = (")
    for cid, name in group_children_for("Views", refs):
        a(f"\t\t\t\t{cid} /* {name} */,")
    a(f"\t\t\t\t{ID_COMPONENTS_GROUP} /* Components */,")
    a("\t\t\t);")
    a("\t\t\tpath = Views;")
    a("\t\t\tsourceTree = \"<group>\";")
    a("\t\t};")

    a(f"\t\t{ID_RESOURCES_GROUP} /* Resources */ = {{")
    a("\t\t\tisa = PBXGroup;")
    a("\t\t\tchildren = (")
    a(f"\t\t\t\t{refs[INFO_PLIST]} /* Info.plist */,")
    for p in RESOURCES:
        a(f"\t\t\t\t{refs[p]} /* {os.path.basename(p)} */,")
    a("\t\t\t);")
    a("\t\t\tpath = Resources;")
    a("\t\t\tsourceTree = \"<group>\";")
    a("\t\t};")

    a(f"\t\t{ID_TARGET_GROUP} /* {TARGET_NAME} */ = {{")
    a("\t\t\tisa = PBXGroup;")
    a("\t\t\tchildren = (")
    for gid, name in [
        (ID_APP_GROUP, "App"),
        (ID_MODELS_GROUP, "Models"),
        (ID_UTILS_GROUP, "Utils"),
        (ID_SERVICES_GROUP, "Services"),
        (ID_VIEWMODELS_GROUP, "ViewModels"),
        (ID_VIEWS_GROUP, "Views"),
        (ID_RESOURCES_GROUP, "Resources"),
    ]:
        a(f"\t\t\t\t{gid} /* {name} */,")
    a("\t\t\t);")
    a(f"\t\t\tpath = {TARGET_NAME};")
    a("\t\t\tsourceTree = \"<group>\";")
    a("\t\t};")

    a(f"\t\t{ID_PRODUCTS_GROUP} /* Products */ = {{")
    a("\t\t\tisa = PBXGroup;")
    a("\t\t\tchildren = (")
    a(f"\t\t\t\t{ID_PRODUCT_REF} /* {TARGET_NAME}.app */,")
    a("\t\t\t);")
    a("\t\t\tname = Products;")
    a("\t\t\tsourceTree = \"<group>\";")
    a("\t\t};")

    a(f"\t\t{ID_MAIN_GROUP} = {{")
    a("\t\t\tisa = PBXGroup;")
    a("\t\t\tchildren = (")
    a(f"\t\t\t\t{ID_TARGET_GROUP} /* {TARGET_NAME} */,")
    a(f"\t\t\t\t{ID_PRODUCTS_GROUP} /* Products */,")
    a("\t\t\t);")
    a("\t\t\tsourceTree = \"<group>\";")
    a("\t\t};")
    a("/* End PBXGroup section */")
    a("")

    a("/* Begin PBXNativeTarget section */")
    a(f"\t\t{ID_TARGET} /* {TARGET_NAME} */ = {{")
    a("\t\t\tisa = PBXNativeTarget;")
    a(f"\t\t\tbuildConfigurationList = {ID_TARGET_CONFIG_LIST} /* Build configuration list for PBXNativeTarget \"{TARGET_NAME}\" */;")
    a("\t\t\tbuildPhases = (")
    a(f"\t\t\t\t{ID_SOURCES_PHASE} /* Sources */,")
    a(f"\t\t\t\t{ID_FRAMEWORKS_PHASE} /* Frameworks */,")
    a(f"\t\t\t\t{ID_RESOURCES_PHASE} /* Resources */,")
    a("\t\t\t);")
    a("\t\t\tbuildRules = (")
    a("\t\t\t);")
    a("\t\t\tdependencies = (")
    a("\t\t\t);")
    a(f"\t\t\tname = {TARGET_NAME};")
    a("\t\t\tproductName = " + TARGET_NAME + ";")
    a(f"\t\t\tproductReference = {ID_PRODUCT_REF} /* {TARGET_NAME}.app */;")
    a("\t\t\tproductType = \"com.apple.product-type.application\";")
    a("\t\t};")
    a("/* End PBXNativeTarget section */")
    a("")

    a("/* Begin PBXProject section */")
    a(f"\t\t{ID_PROJECT} /* Project object */ = {{")
    a("\t\t\tisa = PBXProject;")
    a(f"\t\t\tbuildConfigurationList = {ID_PROJECT_CONFIG_LIST} /* Build configuration list for PBXProject \"{TARGET_NAME}\" */;")
    a("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
    a("\t\t\tdevelopmentRegion = en;")
    a("\t\t\thasScannedForEncodings = 0;")
    a("\t\t\tknownRegions = (")
    a("\t\t\t\ten,")
    a("\t\t\t\tBase,")
    a("\t\t\t);")
    a(f"\t\t\tmainGroup = {ID_MAIN_GROUP};")
    a(f"\t\t\tproductRefGroup = {ID_PRODUCTS_GROUP} /* Products */;")
    a("\t\t\tprojectDirPath = \"\";")
    a("\t\t\tprojectRoot = \"\";")
    a("\t\t\ttargets = (")
    a(f"\t\t\t\t{ID_TARGET} /* {TARGET_NAME} */,")
    a("\t\t\t);")
    a("\t\t};")
    a("/* End PBXProject section */")
    a("")

    a("/* Begin PBXResourcesBuildPhase section */")
    a(f"\t\t{ID_RESOURCES_PHASE} /* Resources */ = {{")
    a("\t\t\tisa = PBXResourcesBuildPhase;")
    a("\t\t\tbuildActionMask = 2147483647;")
    a("\t\t\tfiles = (")
    for p in RESOURCES:
        a(f"\t\t\t\t{builds[p]} /* {os.path.basename(p)} in Resources */,")
    a("\t\t\t);")
    a("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    a("\t\t};")
    a("/* End PBXResourcesBuildPhase section */")
    a("")

    a("/* Begin PBXSourcesBuildPhase section */")
    a(f"\t\t{ID_SOURCES_PHASE} /* Sources */ = {{")
    a("\t\t\tisa = PBXSourcesBuildPhase;")
    a("\t\t\tbuildActionMask = 2147483647;")
    a("\t\t\tfiles = (")
    for p in SOURCE_FILES:
        a(f"\t\t\t\t{builds[p]} /* {os.path.basename(p)} in Sources */,")
    a("\t\t\t);")
    a("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    a("\t\t};")
    a("/* End PBXSourcesBuildPhase section */")
    a("")

    a("/* Begin XCBuildConfiguration section */")
    project_debug = {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ANALYZER_NONNULL": "YES",
        "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
        "CLANG_CXX_LANGUAGE_STANDARD": "\"gnu++20\"",
        "CLANG_CXX_LIBRARY": "\"libc++\"",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING": "YES",
        "CLANG_WARN_BOOL_CONVERSION": "YES",
        "CLANG_WARN_COMMA": "YES",
        "CLANG_WARN_CONSTANT_CONVERSION": "YES",
        "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS": "YES",
        "CLANG_WARN_DIRECT_OBJC_ISA_USAGE": "YES_ERROR",
        "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
        "CLANG_WARN_EMPTY_BODY": "YES",
        "CLANG_WARN_ENUM_CONVERSION": "YES",
        "CLANG_WARN_INFINITE_RECURSION": "YES",
        "CLANG_WARN_INT_CONVERSION": "YES",
        "CLANG_WARN_NON_LITERAL_NULL_CONVERSION": "YES",
        "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF": "YES",
        "CLANG_WARN_OBJC_LITERAL_CONVERSION": "YES",
        "CLANG_WARN_OBJC_ROOT_CLASS": "YES_ERROR",
        "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORKS": "YES",
        "CLANG_WARN_RANGE_LOOP_ANALYSIS": "YES",
        "CLANG_WARN_STRICT_PROTOTYPES": "YES",
        "CLANG_WARN_SUSPICIOUS_MOVE": "YES",
        "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE",
        "CLANG_WARN_UNREACHABLE_CODE": "YES",
        "COPY_PHASE_STRIP": "NO",
        "DEBUG_INFORMATION_FORMAT": "dwarf",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "ENABLE_TESTABILITY": "YES",
        "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
        "GCC_C_LANGUAGE_STANDARD": "gnu17",
        "GCC_DYNAMIC_NO_PIC": "NO",
        "GCC_NO_COMMON_BLOCKS": "YES",
        "GCC_OPTIMIZATION_LEVEL": "0",
        "GCC_PREPROCESSOR_DEFINITIONS": "(\"DEBUG=1\", \"$(inherited)\")",
        "GCC_WARN_64_TO_32_BIT_CONVERSION": "YES",
        "GCC_WARN_ABOUT_RETURN_TYPE": "YES_ERROR",
        "GCC_WARN_UNDECLARED_SELECTOR": "YES",
        "GCC_WARN_UNINITIALIZED_AUTOS": "YES_AGGRESSIVE",
        "GCC_WARN_UNUSED_FUNCTION": "YES",
        "GCC_WARN_UNUSED_VARIABLE": "YES",
        "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
        "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
        "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
        "MTL_FAST_MATH": "YES",
        "ONLY_ACTIVE_ARCH": "YES",
        "SDKROOT": "iphoneos",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "\"DEBUG $(inherited)\"",
        "SWIFT_OPTIMIZATION_LEVEL": "\"-Onone\"",
        "SWIFT_VERSION": "5.0",
    }
    project_release = dict(project_debug)
    project_release.update({
        "DEBUG_INFORMATION_FORMAT": "\"dwarf-with-dsym\"",
        "ENABLE_TESTABILITY": None,
        "GCC_DYNAMIC_NO_PIC": None,
        "GCC_OPTIMIZATION_LEVEL": "s",
        "GCC_PREPROCESSOR_DEFINITIONS": None,
        "MTL_ENABLE_DEBUG_INFO": "NO",
        "ONLY_ACTIVE_ARCH": None,
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": None,
        "SWIFT_COMPILATION_MODE": "wholemodule",
        "SWIFT_OPTIMIZATION_LEVEL": "\"-O\"",
        "VALIDATE_PRODUCT": "YES",
    })

    target_common = {
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "DEVELOPMENT_TEAM": "\"\"",
        "ENABLE_PREVIEWS": "YES",
        "GENERATE_INFOPLIST_FILE": "NO",
        "INFOPLIST_FILE": quote(f"{TARGET_NAME}/Resources/Info.plist"),
        "INFOPLIST_KEY_CFBundleDisplayName": quote("Caption Layer"),
        "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
        "INFOPLIST_KEY_UIRequiresFullScreen": "YES",
        "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
        "LD_RUNPATH_SEARCH_PATHS": "(\n\t\t\t\t\t\"$(inherited)\",\n\t\t\t\t\t\"@executable_path/Frameworks\",\n\t\t\t\t)",
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE_ID,
        "PRODUCT_NAME": "\"$(TARGET_NAME)\"",
        "SWIFT_EMIT_LOC_STRINGS": "YES",
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": "\"1,2\"",
    }
    target_debug = dict(target_common)
    target_debug.update({
        "CODE_SIGN_IDENTITY": "\"-\"",
        "DEBUG_INFORMATION_FORMAT": "dwarf",
        "ENABLE_TESTABILITY": "YES",
        "ONLY_ACTIVE_ARCH": "YES",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "\"DEBUG $(inherited)\"",
        "SWIFT_OPTIMIZATION_LEVEL": "\"-Onone\"",
    })
    target_release = dict(target_common)
    target_release.update({
        "CODE_SIGN_IDENTITY": "\"-\"",
        "DEBUG_INFORMATION_FORMAT": "\"dwarf-with-dsym\"",
        "SWIFT_COMPILATION_MODE": "wholemodule",
        "SWIFT_OPTIMIZATION_LEVEL": "\"-O\"",
        "VALIDATE_PRODUCT": "YES",
    })

    def emit_config(config_id, name, settings):
        a(f"\t\t{config_id} /* {name} */ = {{")
        a("\t\t\tisa = XCBuildConfiguration;")
        a("\t\t\tbuildSettings = {")
        for k in sorted(settings):
            v = settings[k]
            if v is not None:
                if "\n" in v:
                    a(f"\t\t\t\t{k} = {v};")
                else:
                    a(f"\t\t\t\t{k} = {v};")
        a("\t\t\t};")
        a(f"\t\t\tname = {name};")
        a("\t\t};")

    emit_config(ID_CONFIG_DEBUG_PROJECT, "Debug", project_debug)
    emit_config(ID_CONFIG_RELEASE_PROJECT, "Release", project_release)
    emit_config(ID_CONFIG_DEBUG_TARGET, "Debug", target_debug)
    emit_config(ID_CONFIG_RELEASE_TARGET, "Release", target_release)
    a("/* End XCBuildConfiguration section */")
    a("")

    a("/* Begin XCConfigurationList section */")
    a(f"\t\t{ID_PROJECT_CONFIG_LIST} /* Build configuration list for PBXProject \"{TARGET_NAME}\" */ = {{")
    a("\t\t\tisa = XCConfigurationList;")
    a("\t\t\tbuildConfigurations = (")
    a(f"\t\t\t\t{ID_CONFIG_DEBUG_PROJECT} /* Debug */,")
    a(f"\t\t\t\t{ID_CONFIG_RELEASE_PROJECT} /* Release */,")
    a("\t\t\t);")
    a("\t\t\tdefaultConfigurationIsVisible = 0;")
    a("\t\t\tdefaultConfigurationName = Release;")
    a("\t\t};")
    a(f"\t\t{ID_TARGET_CONFIG_LIST} /* Build configuration list for PBXNativeTarget \"{TARGET_NAME}\" */ = {{")
    a("\t\t\tisa = XCConfigurationList;")
    a("\t\t\tbuildConfigurations = (")
    a(f"\t\t\t\t{ID_CONFIG_DEBUG_TARGET} /* Debug */,")
    a(f"\t\t\t\t{ID_CONFIG_RELEASE_TARGET} /* Release */,")
    a("\t\t\t);")
    a("\t\t\tdefaultConfigurationIsVisible = 0;")
    a("\t\t\tdefaultConfigurationName = Release;")
    a("\t\t};")
    a("/* End XCConfigurationList section */")
    a("")

    a("\t};")
    a(f"\trootObject = {ID_PROJECT} /* Project object */;")
    a("}")

    content = "\n".join(lines) + "\n"
    os.makedirs(os.path.dirname(PBXPROJ_PATH), exist_ok=True)
    with open(PBXPROJ_PATH, "w", encoding="utf-8", newline="\n") as f:
        f.write(content)

    write_scheme(ID_TARGET)
    print(f"Wrote {PBXPROJ_PATH} ({len(content)} bytes)")
    print(f"Wrote {SCHEME_PATH}")


def write_scheme(target_id):
    os.makedirs(os.path.dirname(SCHEME_PATH), exist_ok=True)
    scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{target_id}"
               BuildableName = "{TARGET_NAME}.app"
               BlueprintName = "{TARGET_NAME}"
               ReferencedContainer = "container:{TARGET_NAME}.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "{TARGET_NAME}.app"
            BlueprintName = "{TARGET_NAME}"
            ReferencedContainer = "container:{TARGET_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "{TARGET_NAME}.app"
            BlueprintName = "{TARGET_NAME}"
            ReferencedContainer = "container:{TARGET_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
'''
    with open(SCHEME_PATH, "w", encoding="utf-8", newline="\n") as f:
        f.write(scheme)


if __name__ == "__main__":
    main()
