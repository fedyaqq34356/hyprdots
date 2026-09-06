#!/usr/bin/env python3
"""Put LibreOffice's document colours on the wallpaper palette.

The window chrome comes from GTK and is already themed; what GTK cannot reach is
the page itself — the paper, the area around it, the text grid, the shading
behind fields and index entries. Those live in LibreOffice's own registry, which
it rewrites in full every time it exits. So this patches the handful of keys it
owns and leaves the rest of the file exactly as found: settings made by hand
survive, and a new wallpaper only moves the colours.

Nothing is written while LibreOffice is running — the copy in memory would be
flushed over the top on exit, and the change would look like it never happened.

Run by matugen's post_hook; reads the JSON that matugen just wrote.
"""

import json
import os
import subprocess
import sys
import xml.etree.ElementTree as ET

HOME = os.path.expanduser("~")
SOURCE = os.path.join(HOME, ".config/matugen/out/libreoffice-source.json")
REG = os.path.join(HOME, ".config/libreoffice/4/user/registrymodifications.xcu")

OOR = "http://openoffice.org/2001/registry"
XS = "http://www.w3.org/2001/XMLSchema"
XSI = "http://www.w3.org/2001/XMLSchema-instance"

SCHEMES = "/org.openoffice.Office.UI/ColorScheme/ColorSchemes"
SCHEME = (SCHEMES + "/org.openoffice.Office.UI:ColorScheme['LibreOffice']")
UI = "/org.openoffice.Office.UI/ColorScheme"
MISC = "/org.openoffice.Office.Common/Misc"
APPEARANCE = "/org.openoffice.Office.Common/Appearance"

AUTO = "-1"

def to_int(hex_colour):
    return str(int(hex_colour.lstrip("#"), 16))

def mix(a, b, t):
    """Blend two #rrggbb colours, t = how much of b."""
    a = a.lstrip("#")
    b = b.lstrip("#")
    out = []
    for i in (0, 2, 4):
        ca = int(a[i:i + 2], 16)
        cb = int(b[i:i + 2], 16)
        out.append(round(ca + (cb - ca) * t))
    return "#" + "".join("%02x" % c for c in out)

def running():
    for name in ("soffice.bin", "soffice"):
        if subprocess.run(["pgrep", "-x", name],
                          stdout=subprocess.DEVNULL,
                          stderr=subprocess.DEVNULL).returncode == 0:
            return True
    return False

def load_tree():
    if os.path.exists(REG) and os.path.getsize(REG) > 0:
        try:
            ET.register_namespace("oor", OOR)
            ET.register_namespace("xs", XS)
            ET.register_namespace("xsi", XSI)
            tree = ET.parse(REG)
            return tree, tree.getroot()
        except ET.ParseError:
            pass

    ET.register_namespace("oor", OOR)
    ET.register_namespace("xs", XS)
    ET.register_namespace("xsi", XSI)
    root = ET.Element("{%s}items" % OOR)
    return ET.ElementTree(root), root

def find_item(root, path):
    for candidate in root.findall("item"):
        if candidate.get("{%s}path" % OOR) == path:
            return candidate
    return None

def item_for(root, path):
    item = find_item(root, path)
    if item is None:
        item = ET.SubElement(root, "item")
        item.set("{%s}path" % OOR, path)
    return item

def set_prop(root, path, name, value):
    """Set one property in exactly the shape LibreOffice writes itself.

    No oor:type: for a property it already knows, LibreOffice omits the type,
    and an item carrying one it did not expect is dropped on load — silently,
    which is how the first version of this script came to have no effect at all.
    """
    item = item_for(root, path)

    prop = None
    for candidate in item.findall("prop"):
        if candidate.get("{%s}name" % OOR) == name:
            prop = candidate
            break
    if prop is None:
        prop = ET.SubElement(item, "prop")
        prop.set("{%s}name" % OOR, name)

    prop.set("{%s}op" % OOR, "fuse")
    for child in list(prop):
        prop.remove(child)
    ET.SubElement(prop, "value").text = value

def write_scheme(root, container, scheme, colours, visible):
    """Write the whole colour scheme as one item of nested nodes.

    A colour scheme is a member of a *set*, and a set member is not addressable
    by extending the item path — LibreOffice drops props aimed at a member it
    has not been told exists. It has to be written the way LibreOffice writes it
    itself: one item for the set, a node for the scheme, and a node per colour
    holding its Color, all fused in place.
    """
    item = find_item(root, container)
    if item is not None:
        root.remove(item)

    item = ET.SubElement(root, "item")
    item.set("{%s}path" % OOR, container)

    member = ET.SubElement(item, "node")
    member.set("{%s}name" % OOR, scheme)
    member.set("{%s}op" % OOR, "fuse")

    for name, value in colours.items():
        node = ET.SubElement(member, "node")
        node.set("{%s}name" % OOR, name)
        node.set("{%s}op" % OOR, "fuse")

        prop = ET.SubElement(node, "prop")
        prop.set("{%s}name" % OOR, "Color")
        prop.set("{%s}op" % OOR, "fuse")
        ET.SubElement(prop, "value").text = to_int(value)

        if name in visible:
            prop = ET.SubElement(node, "prop")
            prop.set("{%s}name" % OOR, "IsVisible")
            prop.set("{%s}op" % OOR, "fuse")
            ET.SubElement(prop, "value").text = "true"

def ensure_scheme(root, container, name):
    """A named colour scheme is a set element, not a property.

    Properties fused into a set member that does not exist go nowhere, so the
    member has to be declared first — the same `node oor:op="replace"` line
    LibreOffice writes when you save a scheme from the options dialog.
    """
    item = item_for(root, container)
    for node in item.findall("node"):
        if node.get("{%s}name" % OOR) == name:
            return
    node = ET.SubElement(item, "node")
    node.set("{%s}name" % OOR, name)
    node.set("{%s}op" % OOR, "replace")

XCD_OUT = os.path.join(HOME, ".config/matugen/out/libreoffice-matugen.xcd")
XCD_DEST = "/usr/lib/libreoffice/share/registry/matugen.xcd"

def write_xcd(colours, visible, paper, desk):
    """Emit the palette as a read-only registry layer.

    /usr/lib/libreoffice/share/registry is the first layer LibreOffice reads and
    the only one it never writes back, which is what makes it the right place
    for generated defaults. It needs root, so the file is written here and
    installed separately — see install_xcd() for the one command.
    """
    def esc(s):
        return s.replace("&", "&amp;").replace("<", "&lt;")

    rows = []
    for name, value in colours.items():
        vis = ('<prop oor:name="IsVisible"><value>true</value></prop>'
               if name in visible else "")
        rows.append(
            '<node oor:name="%s"><prop oor:name="Color"><value>%s</value>'
            '</prop>%s</node>' % (esc(name), to_int(value), vis))

    xcd = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<oor:data xmlns:oor="%s" xmlns:xs="%s">\n'
        '<oor:component-data oor:name="Common" oor:package="org.openoffice.Office">\n'
        '  <node oor:name="Appearance">\n'
        '    <prop oor:name="UseOnlyWhiteDocBackground"><value>false</value></prop>\n'
        '    <prop oor:name="ApplicationAppearance"><value>0</value></prop>\n'
        '  </node>\n'
        '  <node oor:name="Misc">\n'
        '    <prop oor:name="SymbolStyle"><value>sifr_dark</value></prop>\n'
        '  </node>\n'
        '</oor:component-data>\n'
        '<oor:component-data oor:name="UI" oor:package="org.openoffice.Office">\n'
        '  <node oor:name="ColorScheme">\n'
        '    <prop oor:name="CurrentColorScheme"><value>matugen</value></prop>\n'
        '    <node oor:name="ColorSchemes">\n'
        '      <node oor:name="matugen" oor:op="replace">\n'
        '        %s\n'
        '      </node>\n'
        '    </node>\n'
        '  </node>\n'
        '</oor:component-data>\n'
        '</oor:data>\n'
    ) % (OOR, XS, "\n        ".join(rows))

    os.makedirs(os.path.dirname(XCD_OUT), exist_ok=True)
    with open(XCD_OUT, "w") as fh:
        fh.write(xcd)

    install_xcd()

def install_xcd():
    """Copy the layer into place when that can happen without a prompt.

    A wallpaper change should never stop to ask for a password, so this only
    tries when sudo is already open, and says what to run otherwise.
    """
    try:
        with open(XCD_OUT) as fh:
            wanted = fh.read()
    except OSError:
        return

    try:
        with open(XCD_DEST) as fh:
            if fh.read() == wanted:
                return
    except OSError:
        pass

    if os.access(os.path.dirname(XCD_DEST), os.W_OK):
        import shutil
        shutil.copyfile(XCD_OUT, XCD_DEST)
        print("libreoffice: registry layer installed")
        return

    quiet = subprocess.run(["sudo", "-n", "true"],
                           stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL)
    if quiet.returncode == 0:
        subprocess.run(["sudo", "-n", "cp", XCD_OUT, XCD_DEST],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print("libreoffice: registry layer installed")
        return

    print("libreoffice: palette written to %s — install it with\n"
          "  sudo cp %s %s" % (XCD_OUT, XCD_OUT, XCD_DEST), file=sys.stderr)

def main():
    if not os.path.exists(SOURCE):
        print("no matugen source at " + SOURCE, file=sys.stderr)
        return 1

    with open(SOURCE) as fh:
        c = json.load(fh)

    if running():
        print("LibreOffice is running; colours will apply on the next matugen "
              "run after it closes", file=sys.stderr)
        return 0

    os.makedirs(os.path.dirname(REG), exist_ok=True)
    tree, root = load_tree()

    paper = mix(c["surface"], c["surfaceContainerHigh"], 0.55)
    desk = c["surface"]

    colours = {
        "DocColor": paper,
        "AppBackground": desk,
        "DocBoundaries": c["outlineFaint"],
        "TableBoundaries": c["outlineFaint"],
        "FontColor": c["onSurface"],
        "Links": c["primary"],
        "LinksVisited": c["tertiary"],
        "Spell": c["error"],
        "Grammar": c["tertiary"],
        "SmartTags": c["primary"],
        "Shadow": c["surfaceContainerHigh"],

        "WriterTextGrid": c["outlineFaint"],
        "WriterFieldShadings": mix(paper, c["primary"], 0.12),
        "WriterIdxShadings": mix(paper, c["tertiary"], 0.12),
        "WriterDirectCursor": c["primary"],
        "WriterSectionBoundaries": c["outlineFaint"],
        "WriterHeaderFooterMark": c["outline"],
        "WriterPageBreaks": c["outline"],
        "WriterNonPrintChars": c["outline"],

        "CalcGrid": c["outlineFaint"],
        "CalcCellFocus": c["primary"],
        "CalcPageBreak": c["primary"],
        "CalcPageBreakManual": c["primary"],
        "CalcPageBreakAutomatic": c["outline"],
        "CalcHiddenColRow": c["tertiary"],
        "CalcTextOverflow": c["error"],
        "CalcComments": c["tertiary"],
        "CalcDetective": c["primary"],
        "CalcDetectiveError": c["error"],
        "CalcReference": c["primary"],
        "CalcNotesBackground": mix(paper, c["tertiary"], 0.14),
        "CalcValue": c["primary"],
        "CalcFormula": c["tertiary"],
        "CalcText": c["onSurface"],
        "CalcProtectedBackground": mix(paper, c["surfaceContainerHigh"], 0.5),

        "DrawGrid": c["outlineFaint"],

        "WindowColor": c["surface"],
        "WindowTextColor": c["onSurface"],
        "BaseColor": paper,
        "ButtonColor": c["surfaceContainerHigh"],
        "ButtonTextColor": c["onSurface"],
        "AccentColor": c["primary"],
        "DisabledColor": c["surfaceContainer"],
        "DisabledTextColor": c["outline"],
        "ShadowColor": c["surfaceContainerLowest"],
        "SeparatorColor": c["outlineFaint"],
        "FaceColor": c["surfaceContainer"],
        "ActiveColor": c["primary"],
        "ActiveTextColor": c["onPrimary"],
        "ActiveBorderColor": c["outline"],
        "FieldColor": c["surfaceContainerLow"],
        "MenuBarColor": c["surfaceContainer"],
        "MenuBarTextColor": c["onSurface"],
        "MenuBarHighlightColor": c["primary"],
        "MenuBarHighlightTextColor": c["onPrimary"],
        "MenuColor": c["surfaceContainerHigh"],
        "MenuTextColor": c["onSurface"],
        "MenuHighlightColor": c["primary"],
        "MenuHighlightTextColor": c["onPrimary"],
        "MenuBorderColor": c["outlineFaint"],
        "InactiveColor": c["surfaceContainer"],
        "InactiveTextColor": c["onSurfaceDim"],
        "InactiveBorderColor": c["outlineFaint"],
    }

    visible = ["Links", "LinksVisited", "WriterFieldShadings",
               "WriterIdxShadings", "CalcHiddenColRow", "CalcTextOverflow"]

    write_xcd(colours, visible, paper, desk)

    set_prop(root, MISC, "SymbolStyle", "sifr_dark")

    tree.write(REG, encoding="UTF-8", xml_declaration=True)
    print("libreoffice: %d colours, paper %s on %s" % (len(colours), paper, desk))
    return 0

if __name__ == "__main__":
    sys.exit(main())
