# This class adds a "denydeps" QA test.
#
# This is intended to ensure that a given dependency is _not_ part of a
# given packagegroup. The use case that brought this about was python3;
# we want to offer a small "base" packagegroup, where the disk usage of
# python3 is undesirable-- but we want to make python available in other
# packagegroups, so removing python from ``DISTRO_FEATURES`` or marking
# it as a ``RCONFLICT`` with the packagegroup is also undesirable.
#
# To use this class:
# * ``inherit qa-denydeps``
# * Define package dependencies that should throw QA errors using
#   the ``RDENYDEPENDS_${PN}`` variable.

inherit insane

# this is a postfunc of do_package_qa instead of being added to
# ALL_QA/ERROR_QA as a QAPKGTEST, because otherwise getting insane.bbclass
# to evaluate QAPKGTESTs declared outside of it is troublesome.
do_package_qa[postfuncs] =+ " package_qa_check_denydeps"
python package_qa_check_denydeps() {
    import oe.packagedata

    def check_deps(package, denylist, visited={}, path=None):
        if path is None:
            path = [package]
        if package in denylist:
            bb.error(package + " in RDENYDEPENDS but found via " + repr(path))
            return False
        if package in visited:
            return True

        visited[package] = True

        pkgdata = oe.packagedata.read_subpkgdata(package, d)

        if ('RDEPENDS_' + package) not in pkgdata:
            return True

        rdepends = bb.utils.explode_deps(pkgdata['RDEPENDS_' + package] or "")

        for rdepend in rdepends:
            if not check_deps(rdepend, denylist, visited, path + [rdepend]):
                return False

        return True

    packages = (d.getVar('PACKAGES') or "").split()
    for package in packages:
        denylist = (d.getVar('RDENYDEPENDS_' + package) or "").split()
        if len(denylist) > 0:
            check_deps(package, denylist)
}
