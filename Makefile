PACKAGE=unattended-upgrades
VERSION=0.82.1ubuntu2.4.2
CONTROLROOT=./control-root
FAKEROOT=./data-root
DOCDIR=$(FAKEROOT)/usr/share/doc/$(PACKAGE)
SHAREDIR=$(FAKEROOT)/usr/share/$(PACKAGE)
MANDIR=$(FAKEROOT)/usr/share/man/man8
BINDIR=$(FAKEROOT)/usr/bin
EGGDIR=$(FAKEROOT)/usr/lib/python3/dist-packages/unattended_upgrades-0.1.egg-info
LOGROTATEDIR=$(FAKEROOT)/etc/logrotate.d
SLEEPDIR=$(FAKEROOT)/etc/pm/sleep.d
INITDIR=$(FAKEROOT)/etc/init.d
APTDIR=$(FAKEROOT)/etc/apt/apt.conf.d
DEB=$(PACKAGE)_$(VERSION)_amd64.deb

package: $(DEB)

signed-package: _gpgorigin $(DEB)
	ar r $(DEB) $<

_gpgorigin: $(DEB)
	-rm -f $@
	ar p $(DEB) debian-binary control.tar.gz data.tar.gz | gpg -abs -o _gpgorigin

$(DEB): tarballs debian-binary
	-rm -f $@
	ar rc $@ debian-binary control.tar.gz data.tar.gz
	lintian $@

$(DOCDIR):
	mkdir -p $@

$(DOCDIR)/changelog.gz: debian/changelog $(DOCDIR)
	cat $< | sed 's/PACKAGENAME/$(PACKAGE)/g' | gzip -9 > $@

$(DOCDIR)/copyright: debian/copyright $(DOCDIR)
	cp $< $@

$(DOCDIR)/README.md: README.md $(DOCDIR)
	cp $< $@

debian-binary:
	echo 2.0 > debian-binary

tarballs: data.tar.gz control.tar.gz

control.tar.gz: md5sums debian/control
	-rm -rf $(CONTROLROOT)
	-mkdir -p $(CONTROLROOT)
	install -m 644 debian/conffiles debian/control debian/templates md5sums $(CONTROLROOT)
	install -m 755 debian/config debian/postinst debian/postrm debian/prerm $(CONTROLROOT)
	cd $(CONTROLROOT) && tar -czf ../$@ --owner=root --group=root .

md5sums: install-deps
	(cd $(FAKEROOT) && md5sum `find -type f`) > $@
	chmod 0644 $@

data.tar.gz: install-deps \
             $(DOCDIR)/changelog.gz \
             $(DOCDIR)/copyright \
			 $(DOCDIR)/README.md
	find $(FAKEROOT) -type d | xargs chmod 0755
	find $(FAKEROOT) -type d | xargs chmod ug-s
	find $(FAKEROOT)/usr/share/doc -type f | xargs chmod 0644
	cd $(FAKEROOT) && tar -czf ../$@ --owner=root --group=root --mode=go-w *

.PHONY: clean install-clean install-deps $(LINTPROFILE)

clean: install-clean
	-rm -rf $(CONTROLROOT)
	-rm -f debian-binary *.tar.gz _gpgorigin md5sums
	-rm -f unattended*.deb
	rm -f man/*.gz

install-clean:
	-rm -rf $(FAKEROOT)

install-deps: install-clean	
	mkdir -p $(DOCDIR) $(SHAREDIR) $(MANDIR) $(BINDIR) $(EGGDIR) $(LOGROTATEDIR) $(SLEEPDIR) $(INITDIR) $(APTDIR)
	install -m 755 unattended-upgrade $(BINDIR)
	install -m 755 debian/unattended-upgrades.init $(INITDIR)/unattended-upgrades
	install -m 755 pm/sleep.d/10_unattended-upgrades-hibernate $(SLEEPDIR)
	install -m 755 unattended-upgrade-shutdown $(SHAREDIR)
	install -m 644 unattended_upgrades-0.1.egg-info/top_level.txt unattended_upgrades-0.1.egg-info/PKG-INFO unattended_upgrades-0.1.egg-info/dependency_links.txt unattended_upgrades-0.1.egg-info/SOURCES.txt $(EGGDIR)
	install -m 644 data/20auto-upgrades data/20auto-upgrades-disabled $(SHAREDIR)
	cat man/unattended-upgrade.8 | gzip -9 > man/unattended-upgrade.8.gz
	install -m 644 man/unattended-upgrade.8.gz $(MANDIR)
	install -m 644 data/logrotate.d/unattended-upgrades $(LOGROTATEDIR)
	install -m 644 data/50unattended-upgrades.Ubuntu $(APTDIR)/50unattended-upgrades
	
	
