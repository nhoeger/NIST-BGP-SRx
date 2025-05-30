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
%define name srxcryptoapi
%if "no" == "no"
  %define _unpackaged_files_terminate_build 0
  %define la_lib_switch --without-la-lib
%else
  %define la_lib_switch --with-la-lib
%endif
%if "bgpsec_openssl" == ""
  %define bgpsec_openssl_switch --without-bgpsec-openssl
%else
  %define bgpsec_openssl_switch --with-bgpsec-openssl
%endif
%if "crypto_testlib" == ""
  %define testlib_switch --without-testlib
%else
  %define testlib_switch --with-testlib
%endif


Name:%{name}
Version:%{version}
Release:1%{?dist}
Summary:SRx Crypto API for BGPsec speakers

Group:Security Libraries
License:https://www.nist.gov/director/copyright-fair-use-and-licensing-statements-srd-data-and-software
URL:https://github.com/usnistgov/NIST-BGP-SRx
Source0:%{name}-%{version}.tar.gz
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Prefix: %{_prefix}
Prefix: %{_sysconfdir}

BuildRequires:automake	
Requires:glibc libconfig >= 1.3 openssl >= 1.0.1e


%description
SRxCryptoAPI is free software that manages Cryptography plug ins for BGPsec
path processing.

This Software is a wrapper that allows to configure crypto implementations 
which can be used by software packages such as QuaggaSRx (quaggasrx) and 
SRX-Server (srx) to switch cryptography implementations.

This wrapper allows to switch implementations without the need of recompiling 
QuaggaSRx or SRx-Server. Future versions of both mentioned packages require this
API.

This software package Contains the following modules:
 - The SRx Crypto API itself
 - An OpenSSL based BGPsec path processing plugin
 - A Test library
 - Key generation tool using OpenSSL 


%prep
%setup -q


%build
%configure --prefix=/usr --sysconfdir=/etc %{bgpsec_openssl_switch} %{testlib_switch} %{la_lib_switch}
make %{?_smp_mflags}
#strip --strip-unneeded binary_name

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT


%clean
rm -rf $RPM_BUILD_ROOT

%pre
if [ -e %{_sysconfdir}/qsrx-router-key.conf ] ; then
  mv -f %{_sysconfdir}/qsrx-router-key.conf %{_sysconfdir}/qsrx-router-key.curr
fi 
if [ -e %{_sysconfdir}/srxcryptoapi.conf ]; then
  mv -f %{_sysconfdir}/srxcryptoapi.conf %{_sysconfdir}/srxcryptoapi.curr
fi


%post
if [ -e %{_sysconfdir}/qsrx-router-key.curr ]; then
  mv -f %{_sysconfdir}/qsrx-router-key.conf %{_sysconfdir}/qsrx-router-key.conf.rpmnew
  mv -f %{_sysconfdir}/qsrx-router-key.curr %{_sysconfdir}/qsrx-router-key.conf
fi
if [ -e %{_sysconfdir}/srxcryptoapi.curr ]; then
  mv -f %{_sysconfdir}/srxcryptoapi.conf %{_sysconfdir}/srxcryptoapi.rpmnew
  mv -f %{_sysconfdir}/srxcryptoapi.curr %{_sysconfdir}/srxcryptoapi.conf
fi
ldconfig

%preun
# In case no .rpmnew found, it indicates the configuration file was installed
# using this script. Here move the configuration file into .rpmsafe 
if [ ! -e %{_sysconfdir}/srxcryptoapi.conf.rpmnew ]; then
  if [ -e %{_sysconfdir}/srxcryptoapi.conf ]; then
    mv -f %{_sysconfdir}/srxcryptoapi.conf %{_sysconfdir}/srxcryptoapi.conf.rpmsafe
  fi
fi
if [ ! -e %{_sysconfdir}/qsrx-router-key.conf.rpmnew ]; then
  if [ -e %{_sysconfdir}/qsrx-router-key.conf ]; then
    mv -f %{_sysconfdir}/qsrx-router-key.conf %{_sysconfdir}/qsrx-router-key.conf.rpmsafe
  fi
fi

%postun
# in case a .rpmnew exists remove it.
if [ -e %{_sysconfdir}/qsrx-router-key.conf.rpmnew ]; then
  rm -f %{_sysconfdir}/qsrx-router-key.conf.rpmnew
fi
if [ -e %{_sysconfdir}/srxcryptoapi.conf.rpmnew ]; then
  rm -f %{_sysconfdir}/srxcryptoapi.conf.rpmnew
fi
# below will result in an error if srxdir is not empty and that is fine as long 
# as nothing is printed out.
rmdir %{_libdir}/%{srxdir}/
ldconfig

%files
%defattr(-,root,root,-)
%doc
%{_sysconfdir}/ld.so.conf.d/srxcryptoapi_lib64.conf
%{_sysconfdir}/srxcryptoapi.conf
%{_sysconfdir}/qsrx-router-key.conf
# The Header file is part of the devel package
#%{_includedir}/%{srxdir}/srxcryptoapi.h
%{_libdir}/%{srxdir}/libSRxCryptoAPI.so.%{lib_version_info}
%{_libdir}/%{srxdir}/libSRxCryptoAPI.so.%{major_ver}
%{_libdir}/%{srxdir}/libSRxCryptoAPI.so
%if "no" == "yes"
  %{_libdir}/%{srxdir}/libSRxCryptoAPI.la
  %{_libdir}/%{srxdir}/libSRxCryptoAPI.a
%endif
%if "bgpsec_openssl" != ""
  %{_libdir}/%{srxdir}/libSRxBGPSecOpenSSL.so.%{lib_version_info}
  %{_libdir}/%{srxdir}/libSRxBGPSecOpenSSL.so.%{major_ver}
  %{_libdir}/%{srxdir}/libSRxBGPSecOpenSSL.so
%endif
%if "no" == "yes" && "bgpsec_openssl" != ""
  %{_libdir}/%{srxdir}/libSRxBGPSecOpenSSL.la
  %{_libdir}/%{srxdir}/libSRxBGPSecOpenSSL.a
%endif
%if "crypto_testlib" != ""
  %{_libdir}/%{srxdir}/libSRxCryptoTestlib.so.%{lib_version_info}
  %{_libdir}/%{srxdir}/libSRxCryptoTestlib.so.%{major_ver}
  %{_libdir}/%{srxdir}/libSRxCryptoTestlib.so
%endif
%if "no" == "yes" && "crypto_testlib" != ""
  %{_libdir}/%{srxdir}/libSRxCryptoTestlib.la
  %{_libdir}/%{srxdir}/libSRxCryptoTestlib.a
%endif
%{_sbindir}/srx_crypto_tester
%{_sbindir}/qsrx-make-cert
%{_sbindir}/qsrx-make-key
%{_sbindir}/qsrx-publish
%{_sbindir}/qsrx-view-cert
%{_sbindir}/qsrx-view-csr
%{_sbindir}/qsrx-view-subject
