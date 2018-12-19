from cx_Freeze import setup, Executable

base = None
executables = [Executable("Python_ESS.py", base="WIN32GUI")]

packages = ["idna"]
options = {
    'build_exe': {
        'packages':packages,
    },
}

setup(
    name = "Python_ESS.py",
    options = options,
    version = "3.6.5",
    description = 'YOUR_PROGRAM_DESCRIPTION',
    executables = executables
)