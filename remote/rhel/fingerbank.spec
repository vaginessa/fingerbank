Name:       fingerbank
Version:    1.0.0
Release:    1%{?dist}
BuildArch:  noarch
Summary:    An exhaustive profiling tool
Packager:   Inverse inc. <info@inverse.ca>
Group:      System Environment/Daemons
License:    GPL
URL:        http://www.fingerbank.org/

Source0:    https://support.inverse.ca/~dwuelfrath/fingerbank.tar.gz

BuildRoot:  %{_tmppath}/%{name}-root

Requires(post):     /sbin/chkconfig
Requires(preun):    /sbin/chkconfig

Requires(pre):      /usr/sbin/useradd, /usr/sbin/groupadd, /usr/bin/getent
Requires(postun):   /usr/sbin/userdel

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


%pre
/usr/bin/getent group fingerbank || /usr/sbin/groupadd -r fingerbank
/usr/bin/getent passwd fingerbank || /usr/sbin/useradd -r -d /usr/local/fingerbank -s /sbin/nologin -g fingerbank fingerbank


%prep
%setup -q


%build


%install
rm -rf %{buildroot}
%{__install} -d $RPM_BUILD_ROOT/usr/local/fingerbank
cp -r * $RPM_BUILD_ROOT/usr/local/fingerbank


%post
/usr/local/fingerbank/db/init_databases.pl
chown fingerbank.fingerbank /usr/local/fingerbank/db/fingerbank_Local.db
chmod 664 /usr/local/fingerbank/db/fingerbank_Local.db


%clean
rm -rf %{buildroot}


%postun
/usr/sbin/userdel fingerbank


%files
%defattr(664,fingerbank,fingerbank,775)
%dir                                /usr/local/fingerbank
                                    /usr/local/fingerbank/*
%attr(775,fingerbank,fingerbank)    /usr/local/fingerbank/db/init_databases.pl


%changelog
