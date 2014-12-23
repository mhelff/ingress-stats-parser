ingress-stats-parser
====================

Script for OCR parsing of Ingress agent statistics screenshots

### Status
This project is in a early experimental status. Parsing of stats already looks fairly reliable, but needs more testing. See Testing on how to test and help.

### WTF?
This script is inspired by the fantastic agent-stats.com project.
Automated parsing of Ingress agent stats screens would useful for many Ingress related community projects like local competitions.
This project aims to get a reliable base for OCR on stats the agents provide to your project / database.

Be aware that this version is only tested on Ubuntu 14.04.

### How can i help?
* Fork and send in pull requests!

### Requirements

* Bash 4
* ImageMagick
* tesseract-ocr

### Testing
Basic test data is provided in the ingress-stats-parser-testdata repository. Clone a copy into your working copy of ingress-stats-parser. Use test.sh to validate the known results to your changes you applied to isp.sh.

Submitting more validated test files to ingress-stats-parser-testdata is highly appreciated!

### ToDo

* Cleanup of temp files
* Medal recognition
* dependency checks
* ... your ideas

