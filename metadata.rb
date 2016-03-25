name             't3-tinc'
maintainer       'Michael Stucki'
maintainer_email 'michael.stucki@typo3.org'
license          'Apache 2.0'
description      'Tinc Virtual Private Network'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.0.4'

supports         'debian'

depends          't3-base', '~> 0.2'

depends          'openssl', '= 4.4.0'
