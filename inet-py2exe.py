# -*- coding: utf-8 -*-

from distutils.core import setup
import py2exe, sys

if len(sys.argv) == 1:
    sys.argv.append('py2exe')

py2exe_options = {
    #'includes': ['encodings'],
    #'excludes': [],
    #'dll_excludes': ['USER32.dll', 'IMM32.dll'],
    'compressed': 1,
    'optimize': 2,
    'bundle_files': 0 # 0,1,2,3
}

setup(
    console = [{
        'script': 'inet.py',
        #'dest_base': 'inet',
        'product_name': 'inet',
        'icon_resources': [(0, 'inet.ico'),],
        'version': '3.1.3',
        'description': 'MyChrome Internet Module',
        'copyright': u'甲壳虫<jdchenjian@gmail.com>'
    }],
    #data_files = [('images', [r'c:\path\to\image.jpg'])],
    options = {'py2exe': py2exe_options},
    zipfile = None
)
