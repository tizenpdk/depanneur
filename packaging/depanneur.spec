Name:           depanneur
Summary:        Manages and executes the builds using the obs-build script.
Version:        0.12
Release:        1
License:        GPL-2.0+
Group:          Development/Tools
Source0:        %{name}_%{version}.tar.gz

Requires:       createrepo >= 0.9.8
Requires:       perl(YAML)
Requires:       perl(JSON)
Requires:       perl(HTML::Template)
Requires:       tizen-build >= 20140227
Requires:       tizen-build-initvm-i586 >= 20140227
%ifarch         x86_64
Requires:       tizen-build-initvm-x86_64 >= 20140227
%endif

%if 0%{?suse_version}
BuildRequires:  sudo
%endif
Autoreq:        0
%description
The depanneur tool goes through local Git trees and evaluates packaging
meta-data to determine packages needed and the build order; it then starts
the build process and populates a local repository with the generated
binaries; the generated binaries are then used to build the remaining
packages in the queue.

The tool can build one package or multiple packages at a time, making it
possible to build hundreds of packages on a single computer with enough
power in a matter of hours. Depanneur supports two build modes: traditional
build mode and incremental build mode.

%prep
%setup -q

%install
%make_install

%files
%defattr(-,root,root,-)
%dir %{_datadir}/depanneur
%{_bindir}/depanneur
%{_sysconfdir}/sudoers.d/gbs
%{_datadir}/depanneur/build-report.tmpl
