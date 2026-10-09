import xml.etree.ElementTree as E
import sys
p=E.parse('build/package.xml')
sys.exit(0 if p.findall('.//{http://soap.sforce.com/2006/04/metadata}members') else 1)
