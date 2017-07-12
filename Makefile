# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

COUCHDIR=../couchdb
DEBCHANGELOG="Automatically generated package from upstreasm."
ERLANG_VERSION=18.3

export DEBFULLNAME="CouchDB Developers"
export DEBEMAIL="dev@couchdb.apache.org"

# Debian default
debian: find-couch-dist copy-debian update-changelog dpkg lintian

# Debian 8
jessie: debian

# Ubuntu 12.04
precise: find-couch-dist copy-debian precise-prep dpkg lintian

precise-prep:
	sed -i '/dh-systemd/d' $(DISTDIR)/debian/control
	sed -i '/init-system-helpers/d' $(DISTDIR)/debian/control
	sed -i 's/ --with=systemd//' $(DISTDIR)/debian/rules

# Ubuntu 14.04
# Need to work around missing erlang-* pkgs for 1:18.3-1
trusty: find-couch-dist copy-debian trusty-fix-control update-changelog dpkg lintian

# Ubuntu 16.04
xenial: debian

# RPM default
centos: find-couch-dist link-couch-dist build-rpm

centos6: make-rpmbuild install-js185 centos

centos7: make-rpmbuild centos

# ######################################
get-couch:
	mkdir -p $(COUCHDIR)
	git clone https://github.com/apache/couchdb

build-couch:
	cd $(COUCHDIR) && make dist

# ######################################
find-couch-dist:
	$(eval ORIGDISTDIR := $(shell cd $(COUCHDIR) && find . -type d -name apache-couchdb-\*))
	$(eval NEWDIR := $(shell echo $(ORIGDISTDIR) | sed 's/.\/apache-couchdb/couchdb/'))
	mv $(COUCHDIR)/$(ORIGDISTDIR) $(COUCHDIR)/$(NEWDIR)
	$(eval DISTDIR := $(shell readlink -f $(COUCHDIR)/$(NEWDIR)))

copy-debian:
	rm -rf $(DISTDIR)/debian
	cp -R debian $(DISTDIR)

trusty-fix-control:
	sed -i '/erlang-*/d' $(DISTDIR)/debian/control

update-changelog:
	cd $(DISTDIR) && dch -d $(DEBCHANGELOG)

dpkg:
	cd $(DISTDIR) && dpkg-buildpackage -b -us -uc

lintian:
	cd $(DISTDIR)/.. && lintian --profile couchdb couch*deb

# ######################################
link-couch-dist:
	rm -rf ~/rpmbuild/BUILD
	ln -s $(DISTDIR) ~/rpmbuild/BUILD

make-rpmbuild:
	rm -rf ~/rpmbuild
	mkdir -p ~/rpmbuild
	cp -R rpm/* ~/rpmbuild

build-rpm:
	cd ~/rpmbuild && rpmbuild --verbose -bb SPECS/couchdb.spec --define "erlang_version $(ERLANG_VERSION)"

# ######################################
make-js185:
	spectool -g -R rpm/SPECS/js-1.8.5.spec
	cd ~/rpmbuild && rpmbuild --verbose -bb SPECS/js-1.8.5.spec

install-js185:
	sudo rpm -i ~/rpmbuild/RPMS/x86_64/js-1*
	sudo rpm -i ~/rpmbuild/RPMS/x86_64/js-devel*