#!/usr/bin/env python3
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def hid(name: str) -> str:
    return hashlib.sha1(name.encode()).hexdigest()[:24].upper()


def pbx(*parts: str) -> str:
    return "".join(parts)


app_swifts = sorted((ROOT / "Asistan").rglob("*.swift"))
widget_swifts = sorted((ROOT / "AsistanWidgets").rglob("*.swift"))
shared_swifts = sorted((ROOT / "Shared").rglob("*.swift"))

app_sources = app_swifts + shared_swifts
widget_sources = widget_swifts + shared_swifts

ids = {
    "project": hid("project"),
    "app_target": hid("app_target"),
    "widget_target": hid("widget_target"),
    "app_sources": hid("app_sources"),
    "app_resources": hid("app_resources"),
    "app_frameworks": hid("app_frameworks"),
    "app_embed": hid("app_embed"),
    "widget_sources": hid("widget_sources"),
    "widget_resources": hid("widget_resources"),
    "widget_frameworks": hid("widget_frameworks"),
    "main_group": hid("main_group"),
    "asistan_group": hid("asistan_group"),
    "widget_group": hid("widget_group"),
    "shared_group": hid("shared_group"),
    "products_group": hid("products_group"),
    "app_product": hid("app_product"),
    "widget_product": hid("widget_product"),
    "app_debug": hid("app_debug"),
    "app_release": hid("app_release"),
    "widget_debug": hid("widget_debug"),
    "widget_release": hid("widget_release"),
    "proj_debug": hid("proj_debug"),
    "proj_release": hid("proj_release"),
    "app_configs": hid("app_configs"),
    "widget_configs": hid("widget_configs"),
    "proj_configs": hid("proj_configs"),
    "assets": hid("assets"),
    "assets_build": hid("assets_build"),
    "app_plist": hid("app_plist"),
    "app_entitlements": hid("app_entitlements"),
    "widget_plist": hid("widget_plist"),
    "widget_entitlements": hid("widget_entitlements"),
    "package": hid("package"),
    "supabase_product": hid("supabase_product"),
    "supabase_build": hid("supabase_build"),
    "widget_embed_build": hid("widget_embed_build"),
    "widgetkit_build": hid("widgetkit_build"),
    "widgetkit_ref": hid("widgetkit_ref"),
}

file_refs = {}
build_files = {}
for path in app_sources:
    rel = path.relative_to(ROOT).as_posix()
    file_refs[rel] = hid(f"ref:{rel}")
    build_files[rel] = hid(f"build:app:{rel}")
for path in widget_sources:
    rel = path.relative_to(ROOT).as_posix()
    file_refs[rel] = hid(f"ref:{rel}")
    build_files[f"widget:{rel}"] = hid(f"build:widget:{rel}")

# groups by folder under Asistan
asistan_dirs = {}
for path in app_swifts:
    parent = path.parent.relative_to(ROOT / "Asistan").as_posix()
    asistan_dirs.setdefault(parent, []).append(path)

lines = [
    "// !$*UTF8*$!",
    "{",
    "\tarchiveVersion = 1;",
    "\tclasses = {",
    "\t};",
    "\tobjectVersion = 56;",
    "\tobjects = {",
    "",
    "/* Begin PBXBuildFile section */",
    f"\t\t{ids['assets_build']} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {ids['assets']} /* Assets.xcassets */; }};",
    f"\t\t{ids['supabase_build']} /* Supabase in Frameworks */ = {{isa = PBXBuildFile; productRef = {ids['supabase_product']} /* Supabase */; }};",
    f"\t\t{ids['widgetkit_build']} /* WidgetKit.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {ids['widgetkit_ref']} /* WidgetKit.framework */; }};",
]
for path in app_sources:
    rel = path.relative_to(ROOT).as_posix()
    name = path.name
    lines.append(
        f"\t\t{build_files[rel]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[rel]} /* {name} */; }};"
    )
for path in widget_sources:
    rel = path.relative_to(ROOT).as_posix()
    name = path.name
    lines.append(
        f"\t\t{build_files[f'widget:{rel}']} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[rel]} /* {name} */; }};"
    )
lines += [
    "/* End PBXBuildFile section */",
    "",
    "/* Begin PBXCopyFilesBuildPhase section */",
    f"\t\t{ids['app_embed']} /* Embed Foundation Extensions */ = {{",
    "\t\t\tisa = PBXCopyFilesBuildPhase;",
    "\t\t\tbuildActionMask = 2147483647;",
    "\t\t\tdstPath = \"\";",
    "\t\t\tdstSubfolderSpec = 13;",
    "\t\t\tfiles = (",
    f"\t\t\t\t{ids['widget_embed_build']} /* AsistanWidgets.appex in Embed Foundation Extensions */,",
    "\t\t\t);",
    "\t\t\tname = \"Embed Foundation Extensions\";",
    "\t\t\trunOnlyForDeploymentPostprocessing = 0;",
    "\t\t};",
    "/* End PBXCopyFilesBuildPhase section */",
    "",
    "/* Begin PBXFileReference section */",
    f"\t\t{ids['app_product']} /* Asistan.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Asistan.app; sourceTree = BUILT_PRODUCTS_DIR; }};",
    f"\t\t{ids['widget_product']} /* AsistanWidgets.appex */ = {{isa = PBXFileReference; explicitFileType = \"wrapper.app-extension\"; includeInIndex = 0; path = AsistanWidgets.appex; sourceTree = BUILT_PRODUCTS_DIR; }};",
    f"\t\t{ids['assets']} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }};",
    f"\t\t{ids['app_plist']} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};",
    f"\t\t{ids['app_entitlements']} /* Asistan.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = Asistan.entitlements; sourceTree = \"<group>\"; }};",
    f"\t\t{ids['widget_plist']} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};",
    f"\t\t{ids['widget_entitlements']} /* AsistanWidgets.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = AsistanWidgets.entitlements; sourceTree = \"<group>\"; }};",
    f"\t\t{ids['widgetkit_ref']} /* WidgetKit.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = WidgetKit.framework; path = System/Library/Frameworks/WidgetKit.framework; sourceTree = SDKROOT; }};",
]
for path in sorted(set(app_sources + widget_sources), key=lambda p: p.as_posix()):
    rel = path.relative_to(ROOT).as_posix()
    if rel.startswith("Asistan/"):
        local = path.relative_to(ROOT / "Asistan").as_posix()
    elif rel.startswith("AsistanWidgets/"):
        local = path.relative_to(ROOT / "AsistanWidgets").as_posix()
    elif rel.startswith("Shared/"):
        local = path.relative_to(ROOT / "Shared").as_posix()
    else:
        local = path.name
    lines.append(
        f"\t\t{file_refs[rel]} /* {path.name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {local}; sourceTree = \"<group>\"; }};"
    )
lines += [
    "/* End PBXFileReference section */",
    "",
    "/* Begin PBXFrameworksBuildPhase section */",
    f"\t\t{ids['app_frameworks']} /* Frameworks */ = {{",
    "\t\t\tisa = PBXFrameworksBuildPhase;",
    "\t\t\tbuildActionMask = 2147483647;",
    "\t\t\tfiles = (",
    f"\t\t\t\t{ids['supabase_build']} /* Supabase in Frameworks */,",
    "\t\t\t);",
    "\t\t\trunOnlyForDeploymentPostprocessing = 0;",
    "\t\t};",
    f"\t\t{ids['widget_frameworks']} /* Frameworks */ = {{",
    "\t\t\tisa = PBXFrameworksBuildPhase;",
    "\t\t\tbuildActionMask = 2147483647;",
    "\t\t\tfiles = (",
    f"\t\t\t\t{ids['widgetkit_build']} /* WidgetKit.framework in Frameworks */,",
    "\t\t\t);",
    "\t\t\trunOnlyForDeploymentPostprocessing = 0;",
    "\t\t};",
    "/* End PBXFrameworksBuildPhase section */",
    "",
    "/* Begin PBXGroup section */",
    f"\t\t{ids['main_group']} = {{",
    "\t\t\tisa = PBXGroup;",
    "\t\t\tchildren = (",
    f"\t\t\t\t{ids['asistan_group']} /* Asistan */,",
    f"\t\t\t\t{ids['widget_group']} /* AsistanWidgets */,",
    f"\t\t\t\t{ids['shared_group']} /* Shared */,",
    f"\t\t\t\t{ids['products_group']} /* Products */,",
    "\t\t\t);",
    "\t\t\tsourceTree = \"<group>\";",
    "\t\t};",
    f"\t\t{ids['products_group']} /* Products */ = {{",
    "\t\t\tisa = PBXGroup;",
    "\t\t\tchildren = (",
    f"\t\t\t\t{ids['app_product']} /* Asistan.app */,",
    f"\t\t\t\t{ids['widget_product']} /* AsistanWidgets.appex */,",
    "\t\t\t);",
    "\t\t\tname = Products;",
    "\t\t\tsourceTree = \"<group>\";",
    "\t\t};",
]

asistan_children = [
    f"\t\t\t\t{ids['assets']} /* Assets.xcassets */,",
    f"\t\t\t\t{ids['app_plist']} /* Info.plist */,",
    f"\t\t\t\t{ids['app_entitlements']} /* Asistan.entitlements */,",
]
for path in sorted(app_swifts, key=lambda p: p.as_posix()):
    rel = path.relative_to(ROOT).as_posix()
    asistan_children.append(f"\t\t\t\t{file_refs[rel]} /* {path.name} */,")

lines += [
    f"\t\t{ids['asistan_group']} /* Asistan */ = {{",
    "\t\t\tisa = PBXGroup;",
    "\t\t\tchildren = (",
    *asistan_children,
    "\t\t\t);",
    "\t\t\tpath = Asistan;",
    "\t\t\tsourceTree = \"<group>\";",
    "\t\t};",
]

widget_children = [
    f"\t\t\t\t{ids['widget_plist']} /* Info.plist */,",
    f"\t\t\t\t{ids['widget_entitlements']} /* AsistanWidgets.entitlements */,",
]
for path in widget_swifts:
    rel = path.relative_to(ROOT).as_posix()
    widget_children.append(f"\t\t\t\t{file_refs[rel]} /* {path.name} */,")

shared_children = []
for path in shared_swifts:
    rel = path.relative_to(ROOT).as_posix()
    shared_children.append(f"\t\t\t\t{file_refs[rel]} /* {path.name} */,")

lines += [
    f"\t\t{ids['widget_group']} /* AsistanWidgets */ = {{",
    "\t\t\tisa = PBXGroup;",
    "\t\t\tchildren = (",
    *widget_children,
    "\t\t\t);",
    "\t\t\tpath = AsistanWidgets;",
    "\t\t\tsourceTree = \"<group>\";",
    "\t\t};",
    f"\t\t{ids['shared_group']} /* Shared */ = {{",
    "\t\t\tisa = PBXGroup;",
    "\t\t\tchildren = (",
    *shared_children,
    "\t\t\t);",
    "\t\t\tpath = Shared;",
    "\t\t\tsourceTree = \"<group>\";",
    "\t\t};",
    "/* End PBXGroup section */",
    "",
    "/* Begin PBXNativeTarget section */",
    f"\t\t{ids['app_target']} /* Asistan */ = {{",
    "\t\t\tisa = PBXNativeTarget;",
    "\t\t\tbuildConfigurationList = %s /* Build configuration list for PBXNativeTarget \"Asistan\" */;" % ids["app_configs"],
    "\t\t\tbuildPhases = (",
    f"\t\t\t\t{ids['app_sources']} /* Sources */,",
    f"\t\t\t\t{ids['app_frameworks']} /* Frameworks */,",
    f"\t\t\t\t{ids['app_resources']} /* Resources */,",
    "\t\t\t);",
    "\t\t\tbuildRules = (",
    "\t\t\t);",
    "\t\t\tdependencies = (",
    "\t\t\t);",
    "\t\t\tname = Asistan;",
    "\t\t\tpackageProductDependencies = (",
    f"\t\t\t\t{ids['supabase_product']} /* Supabase */,",
    "\t\t\t);",
    "\t\t\tproductName = Asistan;",
    f"\t\t\tproductReference = {ids['app_product']} /* Asistan.app */;",
    "\t\t\tproductType = \"com.apple.product-type.application\";",
    "\t\t};",
    f"\t\t{ids['widget_target']} /* AsistanWidgets */ = {{",
    "\t\t\tisa = PBXNativeTarget;",
    "\t\t\tbuildConfigurationList = %s /* Build configuration list for PBXNativeTarget \"AsistanWidgets\" */;" % ids["widget_configs"],
    "\t\t\tbuildPhases = (",
    f"\t\t\t\t{ids['widget_sources']} /* Sources */,",
    f"\t\t\t\t{ids['widget_frameworks']} /* Frameworks */,",
    f"\t\t\t\t{ids['widget_resources']} /* Resources */,",
    "\t\t\t);",
    "\t\t\tbuildRules = (",
    "\t\t\t);",
    "\t\t\tdependencies = (",
    "\t\t\t);",
    "\t\t\tname = AsistanWidgets;",
    "\t\t\tproductName = AsistanWidgets;",
    f"\t\t\tproductReference = {ids['widget_product']} /* AsistanWidgets.appex */;",
    "\t\t\tproductType = \"com.apple.product-type.app-extension\";",
    "\t\t};",
    "/* End PBXNativeTarget section */",
    "",
    "/* Begin PBXProject section */",
    f"\t\t{ids['project']} /* Project object */ = {{",
    "\t\t\tisa = PBXProject;",
    "\t\t\tattributes = {",
    "\t\t\t\tBuildIndependentTargetsInParallel = 1;",
    "\t\t\t\tLastSwiftUpdateCheck = 2600;",
    "\t\t\t\tLastUpgradeCheck = 2600;",
    "\t\t\t};",
    f"\t\t\tbuildConfigurationList = {ids['proj_configs']} /* Build configuration list for PBXProject \"Asistan\" */;",
    "\t\t\tcompatibilityVersion = \"Xcode 14.0\";",
    "\t\t\tdevelopmentRegion = tr;",
    "\t\t\thasScannedForEncodings = 0;",
    "\t\t\tknownRegions = (",
    "\t\t\t\ttr,",
    "\t\t\t\ten,",
    "\t\t\t\tBase,",
    "\t\t\t);",
    f"\t\t\tmainGroup = {ids['main_group']};",
    "\t\t\tpackageReferences = (",
    f"\t\t\t\t{ids['package']} /* XCRemoteSwiftPackageReference \"supabase-swift\" */,",
    "\t\t\t);",
    f"\t\t\tproductRefGroup = {ids['products_group']} /* Products */;",
    "\t\t\tprojectDirPath = \"\";",
    "\t\t\tprojectRoot = \"\";",
    "\t\t\ttargets = (",
    f"\t\t\t\t{ids['app_target']} /* Asistan */,",
    f"\t\t\t\t{ids['widget_target']} /* AsistanWidgets */,",
    "\t\t\t);",
    "\t\t};",
    "/* End PBXProject section */",
    "",
    "/* Begin PBXResourcesBuildPhase section */",
    f"\t\t{ids['app_resources']} /* Resources */ = {{",
    "\t\t\tisa = PBXResourcesBuildPhase;",
    "\t\t\tbuildActionMask = 2147483647;",
    "\t\t\tfiles = (",
    f"\t\t\t\t{ids['assets_build']} /* Assets.xcassets in Resources */,",
    "\t\t\t);",
    "\t\t\trunOnlyForDeploymentPostprocessing = 0;",
    "\t\t};",
    f"\t\t{ids['widget_resources']} /* Resources */ = {{",
    "\t\t\tisa = PBXResourcesBuildPhase;",
    "\t\t\tbuildActionMask = 2147483647;",
    "\t\t\tfiles = (",
    "\t\t\t);",
    "\t\t\trunOnlyForDeploymentPostprocessing = 0;",
    "\t\t};",
    "/* End PBXResourcesBuildPhase section */",
    "",
    "/* Begin PBXSourcesBuildPhase section */",
    f"\t\t{ids['app_sources']} /* Sources */ = {{",
    "\t\t\tisa = PBXSourcesBuildPhase;",
    "\t\t\tbuildActionMask = 2147483647;",
    "\t\t\tfiles = (",
]
for path in app_sources:
    rel = path.relative_to(ROOT).as_posix()
    lines.append(f"\t\t\t\t{build_files[rel]} /* {path.name} in Sources */,")
lines += [
    "\t\t\t);",
    "\t\t\trunOnlyForDeploymentPostprocessing = 0;",
    "\t\t};",
    f"\t\t{ids['widget_sources']} /* Sources */ = {{",
    "\t\t\tisa = PBXSourcesBuildPhase;",
    "\t\t\tbuildActionMask = 2147483647;",
    "\t\t\tfiles = (",
]
for path in widget_sources:
    rel = path.relative_to(ROOT).as_posix()
    lines.append(f"\t\t\t\t{build_files[f'widget:{rel}']} /* {path.name} in Sources */,")
lines += [
    "\t\t\t);",
    "\t\t\trunOnlyForDeploymentPostprocessing = 0;",
    "\t\t};",
    "/* End PBXSourcesBuildPhase section */",
    "",
    "/* Begin XCBuildConfiguration section */",
]

common_proj = """
				ALWAYS_SEARCH_USER_PATHS = NO;
				ARCHS = arm64;
				ONLY_ACTIVE_ARCH = YES;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_NO_COMMON_BLOCKS = YES;
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				SDKROOT = macosx;
				SWIFT_VERSION = 5.0;
"""

app_settings = """
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_ENTITLEMENTS = Asistan/Asistan.entitlements;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_HARDENED_RUNTIME = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = Asistan/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/../Frameworks";
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				MARKETING_VERSION = 1.0.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.daghan.asistan;
				PRODUCT_NAME = Asistan;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
"""

widget_settings = """
				CODE_SIGN_ENTITLEMENTS = AsistanWidgets/AsistanWidgets.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_HARDENED_RUNTIME = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = AsistanWidgets/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/../Frameworks @executable_path/../../../../Frameworks";
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				MARKETING_VERSION = 1.0.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.daghan.asistan.widgets;
				PRODUCT_NAME = AsistanWidgets;
				SKIP_INSTALL = YES;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
"""

lines += [
    f"\t\t{ids['proj_debug']} /* Debug */ = {{",
    "\t\t\tisa = XCBuildConfiguration;",
    "\t\t\tbuildSettings = {",
    common_proj,
    "\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;",
    "\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";",
    "\t\t\t};",
    "\t\t\tname = Debug;",
    "\t\t};",
    f"\t\t{ids['proj_release']} /* Release */ = {{",
    "\t\t\tisa = XCBuildConfiguration;",
    "\t\t\tbuildSettings = {",
    common_proj,
    "\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-O\";",
    "\t\t\t};",
    "\t\t\tname = Release;",
    "\t\t};",
    f"\t\t{ids['app_debug']} /* Debug */ = {{",
    "\t\t\tisa = XCBuildConfiguration;",
    "\t\t\tbuildSettings = {",
    app_settings,
    "\t\t\t};",
    "\t\t\tname = Debug;",
    "\t\t};",
    f"\t\t{ids['app_release']} /* Release */ = {{",
    "\t\t\tisa = XCBuildConfiguration;",
    "\t\t\tbuildSettings = {",
    app_settings,
    "\t\t\t};",
    "\t\t\tname = Release;",
    "\t\t};",
    f"\t\t{ids['widget_debug']} /* Debug */ = {{",
    "\t\t\tisa = XCBuildConfiguration;",
    "\t\t\tbuildSettings = {",
    widget_settings,
    "\t\t\t};",
    "\t\t\tname = Debug;",
    "\t\t};",
    f"\t\t{ids['widget_release']} /* Release */ = {{",
    "\t\t\tisa = XCBuildConfiguration;",
    "\t\t\tbuildSettings = {",
    widget_settings,
    "\t\t\t};",
    "\t\t\tname = Release;",
    "\t\t};",
    "/* End XCBuildConfiguration section */",
    "",
    "/* Begin XCConfigurationList section */",
    f"\t\t{ids['proj_configs']} /* Build configuration list for PBXProject \"Asistan\" */ = {{",
    "\t\t\tisa = XCConfigurationList;",
    "\t\t\tbuildConfigurations = (",
    f"\t\t\t\t{ids['proj_debug']} /* Debug */,",
    f"\t\t\t\t{ids['proj_release']} /* Release */,",
    "\t\t\t);",
    "\t\t\tdefaultConfigurationIsVisible = 0;",
    "\t\t\tdefaultConfigurationName = Release;",
    "\t\t};",
    f"\t\t{ids['app_configs']} /* Build configuration list for PBXNativeTarget \"Asistan\" */ = {{",
    "\t\t\tisa = XCConfigurationList;",
    "\t\t\tbuildConfigurations = (",
    f"\t\t\t\t{ids['app_debug']} /* Debug */,",
    f"\t\t\t\t{ids['app_release']} /* Release */,",
    "\t\t\t);",
    "\t\t\tdefaultConfigurationIsVisible = 0;",
    "\t\t\tdefaultConfigurationName = Release;",
    "\t\t};",
    f"\t\t{ids['widget_configs']} /* Build configuration list for PBXNativeTarget \"AsistanWidgets\" */ = {{",
    "\t\t\tisa = XCConfigurationList;",
    "\t\t\tbuildConfigurations = (",
    f"\t\t\t\t{ids['widget_debug']} /* Debug */,",
    f"\t\t\t\t{ids['widget_release']} /* Release */,",
    "\t\t\t);",
    "\t\t\tdefaultConfigurationIsVisible = 0;",
    "\t\t\tdefaultConfigurationName = Release;",
    "\t\t};",
    "/* End XCConfigurationList section */",
    "",
    "/* Begin XCRemoteSwiftPackageReference section */",
    f"\t\t{ids['package']} /* XCRemoteSwiftPackageReference \"supabase-swift\" */ = {{",
    "\t\t\tisa = XCRemoteSwiftPackageReference;",
    "\t\t\trepositoryURL = \"https://github.com/supabase/supabase-swift\";",
    "\t\t\trequirement = {",
    "\t\t\t\tkind = upToNextMajorVersion;",
    "\t\t\t\tminimumVersion = 2.31.0;",
    "\t\t\t};",
    "\t\t};",
    "/* End XCRemoteSwiftPackageReference section */",
    "",
    "/* Begin XCSwiftPackageProductDependency section */",
    f"\t\t{ids['supabase_product']} /* Supabase */ = {{",
    "\t\t\tisa = XCSwiftPackageProductDependency;",
    f"\t\t\tpackage = {ids['package']} /* XCRemoteSwiftPackageReference \"supabase-swift\" */;",
    "\t\t\tproductName = Supabase;",
    "\t\t};",
    "/* End XCSwiftPackageProductDependency section */",
    "\t};",
    f"\trootObject = {ids['project']} /* Project object */;",
    "}",
]

proj_dir = ROOT / "Asistan.xcodeproj"
proj_dir.mkdir(exist_ok=True)
(proj_dir / "project.pbxproj").write_text("\n".join(lines) + "\n")

scheme_dir = proj_dir / "xcshareddata" / "xcschemes"
scheme_dir.mkdir(parents=True, exist_ok=True)
scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2600" version="1.7">
   <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ids['app_target']}" BuildableName="Asistan.app" BlueprintName="Asistan" ReferencedContainer="container:Asistan.xcodeproj"></BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"></TestAction>
   <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ids['app_target']}" BuildableName="Asistan.app" BlueprintName="Asistan" ReferencedContainer="container:Asistan.xcodeproj"></BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ids['app_target']}" BuildableName="Asistan.app" BlueprintName="Asistan" ReferencedContainer="container:Asistan.xcodeproj"></BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration="Debug"></AnalyzeAction>
   <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"></ArchiveAction>
</Scheme>
"""
(scheme_dir / "Asistan.xcscheme").write_text(scheme)
print(f"Wrote {proj_dir / 'project.pbxproj'}")
print(f"App sources: {len(app_sources)}  Widget sources: {len(widget_sources)}")
print(f"App target id: {ids['app_target']}")
