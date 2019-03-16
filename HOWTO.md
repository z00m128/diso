How to build DISO:

Requirements
============

- Linux / Unix with bash compatible shell
- all common system progs (grep, cat, etc...)
- all common build requirements (libc, libstdc++, g++, make, etc...)
- genisoimage or any compatible tool
- macroassembler AS 1.42 (latest beta) at least (http://john.ccac.rwth-aachen.de:8000/as/)
- zxspectrum utils (https://sourceforge.net/projects/zxspectrumutils/)


Build DEMFIR
============

- download this repository
- extract included DEMFIR source somewhere outside diso folder and enter to it
- check config.a80 and select features you want
- run 'make' and build is done automatically

Warning, this is most recent, but unstable version of DEMFIR. For stable release go to http://demfir.sourceforge.net/.


Build DISO
==========

- go to diso folder
- erase unncessary files (only thing you need are folders 'demos', 'firmwares', 'games', 'utilities' and 'work')
- run command: 'genisoimage -U -V "DISO" -G [path to]demfir81123_R.bin -o ../diso.iso .' and you will get diso.iso image in parent folder


Use DISO
========

- burn the iso image to CD, RW or store it to FAT formatted CF, SD, HDD
- insert the medium into DEMFIR
- enjoy

