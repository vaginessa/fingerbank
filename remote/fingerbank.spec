Name:	 	fingerbank
Version:	0.42
Release:	1
Summary:	An extensive profiling tool

Group:		System Environment/Daemons
License:	GPL
URL:		http://fingerbank.org
Source0:	https://support.inverse.ca/~dwuelfrath/fingerbank.tar.gz
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

BuildRequires:	
Requires:   perl
Requires:	perl(Catalyst::Runtime)
Requires:   perl(aliased)
Requires:   perl(MooseX::Types::LoadableClass)
Requires:   perl(Catalyst::Plugin::Static::Simple)
Requires:   perl(Catalust::Plugin::ConfigLoader)
Requires:   perl(Config::General)
Requires:   perl(Readonly)
Requires:   perl(Log::Log4perl)
Requires:   perl(Catalyst::Model::DBIC::Schema)
Requires:   perl(Catalyst::Action::REST)
Requires:   perl(DBD::SQLite)
Requires:   perl(LWP::Protocol::https)

%description


%prep
%setup -q


%build
%configure
make %{?_smp_mflags}


%install
rm -rf %{buildroot}
make install DESTDIR=%{buildroot}


%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%doc



%changelog

