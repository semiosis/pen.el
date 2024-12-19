"""Allow VisiData to open TOML files."""

__version__ = "0.1"

from visidata import (
    asyncthread,
    vd,
    ColumnItem,
    deduceType,
    VisiData,
    PythonSheet,
)

try:
    # This will work in Python 3.11+
    import tomllib
except ModuleNotFoundError:
    # Fallback for Python 3.10 and below
    import tomli as tomllib


@VisiData.api
def open_toml(vd, p):
    return TomlSheet(p.name, source=p)


class TomlSheet(PythonSheet):
    """A Sheet representing the top level of a loaded TOML file.

    This is an intentionally minimal loader with cues taken from
    VisiData built-in JSON and Python object sheet types.
    """

    rowtype = "values"  # rowdef: dict values, possibly nested

    @asyncthread
    def reload(self):
        """Loading a TOML file produces a single dict. Use
        its keys as column headings, and populate a single
        row.
        """
        self.columns = []
        self.rows = []

        data = tomllib.load(self.source.open_bytes())
        for k, v in data.items():
            self.addColumn(ColumnItem(k, type=deduceType(v)))
        self.addRow(data)


vd.addGlobals(vd.getGlobals())