#!/usr/bin/env python3
"""Generates Aetheria.xcodeproj/project.pbxproj from the files on disk.

Run from the repository root:
    python3 tools/generate_project.py

The script scans the Aetheria/ folder and builds a valid Xcode project:
  - all *.swift files -> Sources build phase
  - all *.json files + Assets.xcassets -> Resources build phase
  - Info.plist referenced via INFOPLIST_FILE
  - system frameworks (SpriteKit, SwiftUI, AVFoundation, GameController)

Object IDs are deterministic (SHA-1 of a stable key), so re-running the
script produces a minimal diff.
"""

import hashlib
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP_NAME = "Aetheria"
PROJ_DIR = os.path.join(ROOT, f"{APP_NAME}.xcodeproj")
SRC_DIR = os.path.join(ROOT, APP_NAME)

# ---------------------------------------------------------------- IDs

_used_ids: set = set()


def gid(key: str) -> str:
    """Deterministic 24-char hex object id, unique within this run."""
    digest = hashlib.sha1(key.encode("utf-8")).hexdigest()[:24].upper()
    salt = 0
    while digest in _used_ids:
        salt += 1
        digest = hashlib.sha1(f"{key}#{salt}".encode("utf-8")).hexdigest()[:24].upper()
    _used_ids.add(digest)
    return digest


# ------------------------------------------------------------- model

class Obj:
    def __init__(self, isa: str, comment: str = "", **props):
        self.isa = isa
        self.comment = comment
        self.props = props


objects: dict = {}      # id -> Obj
comments: dict = {}     # id -> comment (for references)


def add(key: str, obj: Obj) -> str:
    oid = gid(key)
    objects[oid] = obj
    comments[oid] = obj.comment
    return oid


# ------------------------------------------------------- value format

_ATOM = re.compile(r"^[A-Za-z0-9_.$/,*]+$")


def q(value) -> str:
    if isinstance(value, bool):
        return "YES" if value else "NO"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, ID):
        return f"{value.oid} /* {value.comment} */"
    if isinstance(value, list):
        if not value:
            return "()"
        inner = "".join(f"\n\t\t\t\t{v}," if False else f"{q(v)}," for v in value)
        return f"({inner})"
    if isinstance(value, dict):
        if not value:
            return "{}"
        inner = "".join(f"{q(k)} = {q(v)};" for k, v in value.items())
        return f"{{{inner}}}"
    s = str(value)
    if s in ("YES", "NO") or _ATOM.match(s):
        return s
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


class ID:
    def __init__(self, oid: str):
        self.oid = oid

    @property
    def comment(self) -> str:
        return comments.get(self.oid, "")


# Pretty printer that keeps the file readable and diff-friendly.
def emit_value(value, indent: str) -> str:
    pad = indent + "\t"
    if isinstance(value, bool):
        return "YES" if value else "NO"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, ID):
        return f"{value.oid} /* {value.comment} */"
    if isinstance(value, list):
        if not value:
            return "()"
        lines = "".join(f"{pad}{emit_value(v, pad)},\n" for v in value)
        return f"(\n{lines}{indent})"
    if isinstance(value, dict):
        if not value:
            return "{}"
        lines = "".join(
            f"{pad}{emit_value(k, pad)} = {emit_value(v, pad)};\n"
            for k, v in value.items()
        )
        return f"{{\n{lines}{indent}}}"
    s = str(value)
    if s in ("YES", "NO") or _ATOM.match(s):
        return s
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


# ------------------------------------------------------------- scan

SWIFT_FILES: list = []     # rel paths like Aetheria/App/Foo.swift
RESOURCE_FILES: list = []  # json files
HAS_XCASSETS = False
HAS_INFOPLIST = False


def scan():
    global HAS_XCASSETS, HAS_INFOPLIST
    for dirpath, dirnames, filenames in os.walk(SRC_DIR):
        # Treat .xcassets as a single opaque reference.
        for d in list(dirnames):
            if d.endswith(".xcassets"):
                dirnames.remove(d)
                HAS_XCASSETS = True
        rel_dir = os.path.relpath(dirpath, ROOT)
        for f in sorted(filenames):
            if f.startswith("."):
                continue
            rel = os.path.join(rel_dir, f)
            if f.endswith(".swift"):
                SWIFT_FILES.append(rel)
            elif f.endswith(".json"):
                RESOURCE_FILES.append(rel)
            elif f == "Info.plist":
                HAS_INFOPLIST = True
    SWIFT_FILES.sort()
    RESOURCE_FILES.sort()


# ------------------------------------------------------------ build

def build():
    global objects, comments, _used_ids
    objects = {}
    comments = {}
    _used_ids = set()

    # ---- file references + build files for sources
    source_build_files = []
    for rel in SWIFT_FILES:
        name = os.path.basename(rel)
        ref = add(f"fileref:{rel}", Obj(
            "PBXFileReference", name,
            lastKnownFileType="sourcecode.swift", path=name, sourceTree="<group>",
        ))
        bf = add(f"buildfile:{rel}", Obj("PBXBuildFile", f"{name} in Sources", fileRef=ID(ref)))
        source_build_files.append(ID(bf))

    # ---- file references + build files for json resources
    resource_build_files = []
    for rel in RESOURCE_FILES:
        name = os.path.basename(rel)
        ref = add(f"fileref:{rel}", Obj(
            "PBXFileReference", name,
            lastKnownFileType="text.json", path=name, sourceTree="<group>",
        ))
        bf = add(f"buildfile:{rel}", Obj("PBXBuildFile", f"{name} in Resources", fileRef=ID(ref)))
        resource_build_files.append(ID(bf))

    # ---- asset catalog
    if HAS_XCASSETS:
        ref = add("fileref:Assets.xcassets", Obj(
            "PBXFileReference", "Assets.xcassets",
            lastKnownFileType="folder.assetcatalog", path="Assets.xcassets", sourceTree="<group>",
        ))
        bf = add("buildfile:Assets.xcassets", Obj(
            "PBXBuildFile", "Assets.xcassets in Resources", fileRef=ID(ref)))
        resource_build_files.append(ID(bf))
        assets_ref = ID(ref)
    else:
        assets_ref = None

    # ---- Info.plist reference (not in any phase)
    if HAS_INFOPLIST:
        plist_ref = ID(add("fileref:Info.plist", Obj(
            "PBXFileReference", "Info.plist",
            lastKnownFileType="text.plist.xml", path="Info.plist", sourceTree="<group>",
        )))
    else:
        plist_ref = None

    # ---- system frameworks
    frameworks_group_children = []
    frameworks_build_files = []
    for fw in ["SpriteKit.framework", "SwiftUI.framework", "AVFoundation.framework", "GameController.framework"]:
        ref = add(f"fileref:sys:{fw}", Obj(
            "PBXFileReference", fw,
            lastKnownFileType="wrapper.framework", path=fw, sourceTree="SDKROOT",
        ))
        frameworks_group_children.append(ID(ref))
        bf = add(f"buildfile:sys:{fw}", Obj("PBXBuildFile", f"{fw} in Frameworks", fileRef=ID(ref)))
        frameworks_build_files.append(ID(bf))
    frameworks_group = ID(add("group:Frameworks", Obj(
        "PBXGroup", "Frameworks", children=frameworks_group_children,
        name="Frameworks", sourceTree="<group>",
    )))

    # ---- groups mirroring folders
    # collect dirs
    dirs: dict = {}  # rel_dir -> {"subdirs": set, "files": [refId...]}

    # NOTE: basenames must be unique across the project (we enforce below).
    by_name: dict = {}
    for oid, o in objects.items():
        if o.isa == "PBXFileReference" and o.props.get("sourceTree") == "<group>":
            by_name.setdefault(o.comment, []).append(oid)
    dupes = {k: v for k, v in by_name.items() if len(v) > 1}
    if dupes:
        print(f"ERROR: duplicate file basenames are not supported: {sorted(dupes)}")
        sys.exit(1)

    def ref_id_for(rel: str) -> ID:
        return ID(by_name[os.path.basename(rel)][0])

    # group ids bottom-up
    group_ids: dict = {}

    def ensure_dir(rel_dir: str):
        if rel_dir in dirs:
            return
        dirs[rel_dir] = {"subdirs": set(), "files": []}
        parent = os.path.dirname(rel_dir)
        if parent and parent != rel_dir and rel_dir != APP_NAME:
            ensure_dir(parent)
            dirs[parent]["subdirs"].add(rel_dir)

    ensure_dir(APP_NAME)
    for rel in SWIFT_FILES + RESOURCE_FILES:
        d = os.path.dirname(rel)
        ensure_dir(d)
        if d != APP_NAME:
            pass
        dirs[d]["files"].append(ref_id_for(rel))

    # create groups deepest-first
    for rel_dir in sorted(dirs, key=lambda p: p.count(os.sep), reverse=True):
        if rel_dir == APP_NAME:
            continue
        name = os.path.basename(rel_dir)
        children = sorted(
            [ID(group_ids[s]) for s in dirs[rel_dir]["subdirs"]],
            key=lambda i: comments[i.oid],
        ) + sorted(dirs[rel_dir]["files"], key=lambda i: comments[i.oid])
        group_ids[rel_dir] = add(f"group:{rel_dir}", Obj(
            "PBXGroup", name, children=children, path=name, sourceTree="<group>",
        ))

    # root Aetheria group
    app_children = (
        sorted([ID(group_ids[s]) for s in dirs[APP_NAME]["subdirs"]],
               key=lambda i: comments[i.oid])
        + sorted(dirs[APP_NAME]["files"], key=lambda i: comments[i.oid])
    )
    if assets_ref is not None:
        app_children.append(assets_ref)
    if plist_ref is not None:
        app_children.append(plist_ref)
    app_group = ID(add("group:Aetheria", Obj(
        "PBXGroup", APP_NAME, children=app_children, path=APP_NAME, sourceTree="<group>",
    )))

    # ---- product + phases + target
    app_ref = ID(add("fileref:product", Obj(
        "PBXFileReference", f"{APP_NAME}.app",
        explicitFileType="wrapper.application", includeInIndex=0,
        path=f"{APP_NAME}.app", sourceTree="BUILT_PRODUCTS_DIR",
    )))
    products_group = ID(add("group:Products", Obj(
        "PBXGroup", "Products", children=[app_ref], name="Products", sourceTree="<group>",
    )))
    main_group = ID(add("group:main", Obj(
        "PBXGroup", "main", children=[app_group, frameworks_group, products_group],
        sourceTree="<group>",
    )))

    sources_phase = ID(add("phase:sources", Obj(
        "PBXSourcesBuildPhase", "Sources",
        buildActionMask=2147483647, files=source_build_files,
        runOnlyForDeploymentPostprocessing=0,
    )))
    frameworks_phase = ID(add("phase:frameworks", Obj(
        "PBXFrameworksBuildPhase", "Frameworks",
        buildActionMask=2147483647, files=frameworks_build_files,
        runOnlyForDeploymentPostprocessing=0,
    )))
    resources_phase = ID(add("phase:resources", Obj(
        "PBXResourcesBuildPhase", "Resources",
        buildActionMask=2147483647, files=resource_build_files,
        runOnlyForDeploymentPostprocessing=0,
    )))

    target_debug = add("config:target:Debug", Obj(
        "XCBuildConfiguration", "Debug",
        baseConfigurationReference=None, buildSettings={
            "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
            "CODE_SIGN_STYLE": "Automatic",
            "CURRENT_PROJECT_VERSION": "1",
            "ENABLE_PREVIEWS": "YES",
            "GENERATE_INFOPLIST_FILE": "NO",
            "INFOPLIST_FILE": f"{APP_NAME}/Info.plist",
            "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
            "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
            "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
            "MARKETING_VERSION": "1.0.0",
            "PRODUCT_BUNDLE_IDENTIFIER": "com.ggbb.aetheria",
            "PRODUCT_NAME": "$(TARGET_NAME)",
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
            "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
            "SWIFT_VERSION": "5.0",
            "TARGETED_DEVICE_FAMILY": "1,2",
        }, name="Debug",
    ))
    # remove None baseConfigurationReference entries later at emit
    target_release = add("config:target:Release", Obj(
        "XCBuildConfiguration", "Release",
        buildSettings={
            "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
            "CODE_SIGN_STYLE": "Automatic",
            "CURRENT_PROJECT_VERSION": "1",
            "ENABLE_PREVIEWS": "YES",
            "GENERATE_INFOPLIST_FILE": "NO",
            "INFOPLIST_FILE": f"{APP_NAME}/Info.plist",
            "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
            "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
            "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
            "MARKETING_VERSION": "1.0.0",
            "PRODUCT_BUNDLE_IDENTIFIER": "com.ggbb.aetheria",
            "PRODUCT_NAME": "$(TARGET_NAME)",
            "SWIFT_COMPILATION_MODE": "wholemodule",
            "SWIFT_OPTIMIZATION_LEVEL": "-O",
            "SWIFT_VERSION": "5.0",
            "TARGETED_DEVICE_FAMILY": "1,2",
        }, name="Release",
    ))
    target_config_list = ID(add("configlist:target", Obj(
        "XCConfigurationList", f"Build configuration list for PBXNativeTarget \"{APP_NAME}\"",
        buildConfigurations=[ID(target_debug), ID(target_release)],
        defaultConfigurationIsVisible=0, defaultConfigurationName="Release",
    )))

    target = ID(add("target:app", Obj(
        "PBXNativeTarget", APP_NAME,
        buildConfigurationList=target_config_list,
        buildPhases=[sources_phase, frameworks_phase, resources_phase],
        buildRules=[], dependencies=[], name=APP_NAME,
        productName=APP_NAME, productReference=app_ref,
        productType="com.apple.product-type.application",
    )))

    project_debug = add("config:project:Debug", Obj(
        "XCBuildConfiguration", "Debug",
        buildSettings={
            "ALWAYS_SEARCH_USER_PATHS": "NO",
            "CLANG_ANALYZER_NONNULL": "YES",
            "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
            "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
            "CLANG_ENABLE_OBJC_WEAK": "YES",
            "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
            "GCC_C_LANGUAGE_STANDARD": "gnu11",
            "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
            "ONLY_ACTIVE_ARCH": "YES",
            "SDKROOT": "iphoneos",
            "SWIFT_VERSION": "5.0",
        }, name="Debug",
    ))
    project_release = add("config:project:Release", Obj(
        "XCBuildConfiguration", "Release",
        buildSettings={
            "ALWAYS_SEARCH_USER_PATHS": "NO",
            "CLANG_ANALYZER_NONNULL": "YES",
            "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
            "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
            "CLANG_ENABLE_OBJC_WEAK": "YES",
            "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
            "GCC_C_LANGUAGE_STANDARD": "gnu11",
            "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
            "SDKROOT": "iphoneos",
            "SWIFT_VERSION": "5.0",
        }, name="Release",
    ))
    project_config_list = ID(add("configlist:project", Obj(
        "XCConfigurationList", "Build configuration list for PBXProject",
        buildConfigurations=[ID(project_debug), ID(project_release)],
        defaultConfigurationIsVisible=0, defaultConfigurationName="Release",
    )))

    project = add("project", Obj(
        "PBXProject", "Project object",
        attributes={
            "LastSwiftUpdateCheck": "1600",
            "LastUpgradeCheck": "1600",
            "TargetAttributes": {target.oid: {"CreatedOnToolsVersion": "16.0"}},
        },
        buildConfigurationList=project_config_list,
        compatibilityVersion="Xcode 14.0",
        developmentRegion="en",
        hasScannedForEncodings=0,
        knownRegions=["en", "Base"],
        mainGroup=main_group,
        productRefGroup=products_group,
        projectDirPath="",
        targets=[target],
    ))
    return project


SECTION_ORDER = [
    "PBXBuildFile", "PBXFileReference", "PBXFrameworksBuildPhase", "PBXGroup",
    "PBXNativeTarget", "PBXProject", "PBXResourcesBuildPhase",
    "PBXSourcesBuildPhase", "XCBuildConfiguration", "XCConfigurationList",
]


def emit(root_id: str) -> str:
    lines = ["// !$*UTF8*$!", "{", "\tarchiveVersion = 1;",
             "\tclasses = {", "\t};", "\tobjectVersion = 56;", "\tobjects = {"]
    by_isa: dict = {}
    for oid, o in objects.items():
        by_isa.setdefault(o.isa, []).append(oid)
    for isa in SECTION_ORDER:
        oids = sorted(by_isa.get(isa, []))
        if not oids:
            continue
        lines.append(f"\n/* Begin {isa} section */")
        for oid in oids:
            o = objects[oid]
            lines.append(f"\t\t{oid} /* {o.comment} */ = {{")
            lines.append(f"\t\t\tisa = {isa};")
            for k in sorted(o.props):
                v = o.props[k]
                if v is None:
                    continue
                lines.append(f"\t\t\t{k} = {emit_value(v, chr(9) * 3)};")
            lines.append("\t\t};")
        lines.append(f"/* End {isa} section */")
    lines.append("\t};")
    lines.append(f"\trootObject = {root_id} /* Project object */;")
    lines.append("}")
    return "\n".join(lines) + "\n"


def validate(text: str) -> bool:
    ok = True
    defined = set(objects.keys())
    for m in re.finditer(r"\b[0-9A-F]{24}\b", text):
        if m.group(0) not in defined:
            print(f"ERROR: dangling reference {m.group(0)}")
            ok = False
    if text.count("{") != text.count("}"):
        print("ERROR: unbalanced braces")
        ok = False
    if text.count("(") != text.count(")"):
        print("ERROR: unbalanced parens")
        ok = False
    for rel in SWIFT_FILES + RESOURCE_FILES:
        if not os.path.isfile(os.path.join(ROOT, rel)):
            print(f"ERROR: missing file {rel}")
            ok = False
    if HAS_INFOPLIST and not os.path.isfile(os.path.join(SRC_DIR, "Info.plist")):
        print("ERROR: Info.plist flag set but file missing")
        ok = False
    return ok


def main():
    scan()
    print(f"Swift sources: {len(SWIFT_FILES)}, JSON resources: {len(RESOURCE_FILES)}, "
          f"xcassets: {HAS_XCASSETS}, Info.plist: {HAS_INFOPLIST}")
    if not SWIFT_FILES:
        print("ERROR: no Swift files found — nothing to do.")
        sys.exit(1)
    root_id = build()
    text = emit(root_id)
    if not validate(text):
        sys.exit(1)
    os.makedirs(PROJ_DIR, exist_ok=True)
    with open(os.path.join(PROJ_DIR, "project.pbxproj"), "w", encoding="utf-8") as f:
        f.write(text)
    print(f"Wrote {os.path.join(PROJ_DIR, 'project.pbxproj')} ({len(objects)} objects)")


if __name__ == "__main__":
    main()
