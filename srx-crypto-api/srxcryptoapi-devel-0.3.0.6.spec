%global _enable_debug_package 0
%global debug_package %{nil}
%global __os_install_post /usr/lib/rpm/brp-compress %{nil}

%define package_num  0
%define major_ver    3
%define minor_ver    0
%define update_num   6
%define lib_ver_info 3.0.0
%define srxdir       srx

%define lib_version_info %{lib_ver_info}
%define package_version %{package_num}.%{major_ver}.%{minor_ver}.%{update_num}
%define version %{package_version}
%define core_name srxcryptoapi
%define name %{core_name}-devel
%define _unpackaged_files_terminate_build 0

Name:%{name}
Version:%{version}
Release:1%{?dist}
Summary:SRx Crypto API - developers package

Group:Security Libraries
License:https://www.nist.gov/director/copyright-fair-use-and-licensing-statements-srd-data-and-software
URL://https://github.com/usnistgov/NIST-BGP-SRx
Vendor:National Institute of Standards and Technology (NIST)
Distribution:NIST BGP-SRx Software Suite
Packager: BGP-SRx Team <itrg-contact@list.nist.gov>
Source0:%{core_name}-%{version}.tar.gz
BuildRoot:/tmp/rpm/%{core_name}-%{version}
#Prefix: %{_prefix}
#Prefix: %{_sysconfdir}

BuildRequires:automake	
Requires: %{core_name} = %{version}
  
%description
The SRxCryptoAPI developers package

%prep
%setup -q -n %{core_name}-%{version}

%build

%install
# install the header file
mkdir -p $RPM_BUILD_ROOT/%{_includedir}/%{srxdir}
cp %{srxdir}/srxcryptoapi.h $RPM_BUILD_ROOT/%{_includedir}/%{srxdir}

# Install the API tester and README file
#mkdir -p $RPM_BUILD_ROOT/%{_usrsrc}/srx-crypto-api
#cp srx_api_test.c $RPM_BUILD_ROOT/%{_usrsrc}/srx-crypto-api
#cp README $RPM_BUILD_ROOT/%{_usrsrc}/srx-crypto-api


%clean
rm -rf $RPM_BUILD_ROOT

%post

%preun

%postun
if [ "x$(ls -A %{_includedir}/%{srxdir})" = "x" ] ; then
  rmdir %{_includedir}/%{srxdir}
fi 

%files
#%defattr(644,root,root,755)
%defattr(-,root,root,-)
%{_includedir}/%{srxdir}/srxcryptoapi.h
#%{_usrsrc}/srx-crypto-api/srx_api_test.c
#%{_usrsrc}/srx-crypto-api/README
