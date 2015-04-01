Name:       fingerbank
Version:    1.42
Release:    1%{?dist}
Summary:    An exhaustive profiling tool
Packager:   Inverse inc. <info@inverse.ca>
Group:      System Environment/Daemons
License:    GPL
URL:        http://www.fingerbank.org/

Source0:    https://support.inverse.ca/~dwuelfrath/fingerbank.tar.gz

BuildRoot:  %{_tmppath}/%{name}-root

Requires(post):     /sbin/chkconfig
Requires(preun):    /sbin/chkconfig

Requires:   perl
Requires:   perl(Catalyst::Runtime)
Requires:   perl(aliased)
Requires:   perl(MooseX::Types::LoadableClass)
Requires:   perl(Catalyst::Plugin::Static::Simple)
Requires:   perl(Catalyst::Plugin::ConfigLoader)
Requires:   perl(Config::General)
Requires:   perl(Readonly)
Requires:   perl(Log::Log4perl)
Requires:   perl(Catalyst::Model::DBIC::Schema)
Requires:   perl(Catalyst::Action::REST)
Requires:   perl(DBD::SQLite)
Requires:   perl(LWP::Protocol::https)

%description
Fingerbank


%prep
%setup -q


%build


%install
rm -rf %{buildroot}
%{__install} -d $RPM_BUILD_ROOT/usr/local/fingerbank
cp -r * $RPM_BUILD_ROOT/usr/local/fingerbank

%post
/usr/local/fingerbank/db/init_databases.pl

%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%dir                    /usr/local/fingerbank
                        /usr/local/fingerbank/*




%changelog
