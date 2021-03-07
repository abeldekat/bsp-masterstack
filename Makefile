# bsp-masterstack

VERSION = 0.0.1

PREFIX = /usr/local
MANPREFIX = ${PREFIX}/share/man
SRCPREFIX = ${PREFIX}/lib

BINARY_PATH = ${DESTDIR}${PREFIX}/bin
MAN_PATH = ${DESTDIR}${MANPREFIX}/man1
SRC_PATH = ${DESTDIR}${SRCPREFIX}/bsp-masterstack

MANPAGE = ${MAN_PATH}/bsp-masterstack.1

uninstall:
	rm -f ${BINARY_PATH}/bsp-masterstack ${MAN_PATH}/bsp-masterstack.1
	rm -rf ${SRC_PATH}
	echo "Removed bsp-masterstack source files"

install:
	mkdir -p ${BINARY_PATH} ${SRC_PATH} ${MAN_PATH}
	cp -rf src/* ${SRC_PATH}/ # Source files
	cp src/bsp-masterstack.sh bsp-masterstack.sh.tmp
	sed "s|{{VERSION}}|${VERSION}|g" bsp-masterstack.sh.tmp > ${SRC_PATH}/bsp-masterstack.sh # Update version
	cp -f ${SRC_PATH}/bsp-masterstack.sh bsp-masterstack.sh.tmp
	sed "s|{{SOURCE_PATH}}|${SRC_PATH}|g" bsp-masterstack.sh.tmp > ${SRC_PATH}/bsp-masterstack.sh # Update source path
	rm bsp-masterstack.sh.tmp
	sed "s|{{VERSION}}|${VERSION}|g" bsp-masterstack.1 > ${MANPAGE} # Manpage
	chmod 644 ${MANPAGE} # Manpage permission
	chmod 755 ${SRC_PATH}/adapters/*.sh
	chmod 755 ${SRC_PATH}/listeners/*.sh
	chmod 755 ${SRC_PATH}/bsp-masterstack.sh
	ln -sf ${SRC_PATH}/bsp-masterstack.sh ${BINARY_PATH}/bsp-masterstack # Create bin
	echo "Installed bsp-masterstack"

.PHONY: install uninstall
