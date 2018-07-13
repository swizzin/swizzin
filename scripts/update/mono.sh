#!/bin/bash
#Have I mentioned I hate mono?

if [[ -f /install/.sonarr.lock ]] || [[ -f /install/.radarr.lock ]] || [[ -f /install/.jackett.lock ]]; then
  version=$(lsb_release -cs)
  distro=$(lsb_release -is)
  master=$(cat /root/.master.info | cut -d : -f1)
  sonarr=$(systemctl is-active sonarr@$master)
  radarr=$(systemctl is-active radarr)
  jackett=$(systemctl is-active jackett@$master)

if [[ -f /etc/apt/sources.list.d/mono-xamarin.list ]]; then
  if grep -q "5.8" /etc/apt/sources.list.d/mono-xamarin.list; then
    :
  else
    echo "deb https://download.mono-project.com/repo/debian wheezy/snapshots/5.8/. main" > /etc/apt/sources.list.d/mono-xamarin.list
    echo "Upgrading to mono 5.8 snapshot"
    #version=wheezy
    #PACKAGES=(ca-certificates-mono libmono-2.0-1 libmono-2.0-dev libmono-accessibility4.0-cil libmono-cairo4.0-cil
    #  libmono-cecil-private-cil libmono-cil-dev libmono-codecontracts4.0-cil
    #  libmono-compilerservices-symbolwriter4.0-cil libmono-corlib4.5-cil libmono-cscompmgd0.0-cil
    #  libmono-csharp4.0c-cil libmono-custommarshalers4.0-cil libmono-data-tds4.0-cil libmono-db2-1.0-cil
    #  libmono-debugger-soft4.0a-cil libmono-http4.0-cil libmono-i18n-cjk4.0-cil libmono-i18n-mideast4.0-cil
    #  libmono-i18n-other4.0-cil libmono-i18n-rare4.0-cil libmono-i18n-west4.0-cil libmono-i18n4.0-all
    #  libmono-i18n4.0-cil libmono-ldap4.0-cil libmono-management4.0-cil libmono-messaging-rabbitmq4.0-cil
    #  libmono-messaging4.0-cil libmono-microsoft-build-engine4.0-cil libmono-microsoft-build-framework4.0-cil
    #  libmono-microsoft-build-tasks-v4.0-4.0-cil libmono-microsoft-build-utilities-v4.0-4.0-cil
    #  libmono-microsoft-build4.0-cil libmono-microsoft-csharp4.0-cil libmono-microsoft-visualc10.0-cil
    #  libmono-microsoft-web-infrastructure1.0-cil libmono-oracle4.0-cil libmono-parallel4.0-cil
    #  libmono-peapi4.0a-cil libmono-posix4.0-cil libmono-profiler libmono-rabbitmq4.0-cil
    #  libmono-relaxng4.0-cil libmono-security4.0-cil libmono-sharpzip4.84-cil libmono-simd4.0-cil
    #  libmono-smdiagnostics0.0-cil libmono-sqlite4.0-cil libmono-system-componentmodel-composition4.0-cil
    #  libmono-system-componentmodel-dataannotations4.0-cil libmono-system-configuration-install4.0-cil
    #  libmono-system-configuration4.0-cil libmono-system-core4.0-cil
    #  libmono-system-data-datasetextensions4.0-cil libmono-system-data-entity4.0-cil
    #  libmono-system-data-linq4.0-cil libmono-system-data-services-client4.0-cil
    #  libmono-system-data-services4.0-cil libmono-system-data4.0-cil libmono-system-deployment4.0-cil
    #  libmono-system-design4.0-cil libmono-system-drawing-design4.0-cil libmono-system-drawing4.0-cil
    #  libmono-system-dynamic4.0-cil libmono-system-enterpriseservices4.0-cil
    #  libmono-system-identitymodel-selectors4.0-cil libmono-system-identitymodel4.0-cil
    #  libmono-system-io-compression-filesystem4.0-cil libmono-system-io-compression4.0-cil
    #  libmono-system-json-microsoft4.0-cil libmono-system-json4.0-cil libmono-system-ldap-protocols4.0-cil
    #  libmono-system-ldap4.0-cil libmono-system-management4.0-cil libmono-system-messaging4.0-cil
    #  libmono-system-net-http-formatting4.0-cil libmono-system-net-http-webrequest4.0-cil
    #  libmono-system-net-http4.0-cil libmono-system-net4.0-cil libmono-system-numerics-vectors4.0-cil
    #  libmono-system-numerics4.0-cil libmono-system-reactive-core2.2-cil
    #  libmono-system-reactive-debugger2.2-cil libmono-system-reactive-experimental2.2-cil
    #  libmono-system-reactive-interfaces2.2-cil libmono-system-reactive-linq2.2-cil
    #  libmono-system-reactive-observable-aliases0.0-cil libmono-system-reactive-platformservices2.2-cil
    #  libmono-system-reactive-providers2.2-cil libmono-system-reactive-runtime-remoting2.2-cil
    #  libmono-system-reactive-windows-forms2.2-cil libmono-system-reactive-windows-threading2.2-cil
    #  libmono-system-reflection-context4.0-cil libmono-system-runtime-caching4.0-cil
    #  libmono-system-runtime-durableinstancing4.0-cil
    #  libmono-system-runtime-interopservices-runtimeinformation4.0-cil
    #  libmono-system-runtime-serialization-formatters-soap4.0-cil libmono-system-runtime-serialization4.0-cil
    #  libmono-system-runtime4.0-cil libmono-system-security4.0-cil
    #  libmono-system-servicemodel-activation4.0-cil libmono-system-servicemodel-discovery4.0-cil
    #  libmono-system-servicemodel-internals0.0-cil libmono-system-servicemodel-routing4.0-cil
    #  libmono-system-servicemodel-web4.0-cil libmono-system-servicemodel4.0a-cil
    #  libmono-system-serviceprocess4.0-cil libmono-system-threading-tasks-dataflow4.0-cil
    #  libmono-system-transactions4.0-cil libmono-system-web-abstractions4.0-cil
    #  libmono-system-web-applicationservices4.0-cil libmono-system-web-dynamicdata4.0-cil
    #  libmono-system-web-extensions-design4.0-cil libmono-system-web-extensions4.0-cil
    #  libmono-system-web-http-selfhost4.0-cil libmono-system-web-http-webhost4.0-cil
    #  libmono-system-web-http4.0-cil libmono-system-web-mobile4.0-cil libmono-system-web-mvc3.0-cil
    #  libmono-system-web-razor2.0-cil libmono-system-web-regularexpressions4.0-cil
    #  libmono-system-web-routing4.0-cil libmono-system-web-services4.0-cil
    #  libmono-system-web-webpages-deployment2.0-cil libmono-system-web-webpages-razor2.0-cil
    #  libmono-system-web-webpages2.0-cil libmono-system-web4.0-cil
    #  libmono-system-windows-forms-datavisualization4.0a-cil libmono-system-windows-forms4.0-cil
    #  libmono-system-windows4.0-cil libmono-system-workflow-activities4.0-cil
    #  libmono-system-workflow-componentmodel4.0-cil libmono-system-workflow-runtime4.0-cil
    #  libmono-system-xaml4.0-cil libmono-system-xml-linq4.0-cil libmono-system-xml-serialization4.0-cil
    #  libmono-system-xml4.0-cil libmono-system4.0-cil libmono-tasklets4.0-cil libmono-webbrowser4.0-cil
    #  libmono-webmatrix-data4.0-cil libmono-windowsbase4.0-cil libmono-xbuild-tasks4.0-cil libmonoboehm-2.0-1
    #  libmonosgen-2.0-1 libmonosgen-2.0-dev mono-4.0-gac mono-4.0-service mono-complete mono-csharp-shell
    #  mono-devel mono-gac mono-jay mono-mcs mono-runtime mono-runtime-common mono-runtime-sgen mono-utils
    #  mono-xbuild monodoc-base monodoc-http monodoc-manual)

    #NR=(mono-roslyn msbuild msbuild-libhostfxr msbuild-sdkresolver referenceassemblies-pcl)

    fuckmono=()

    #for i in ${PACKAGES[@]}; do
    #  fuckmono+=(${i}/${version})
    #done

    apt-get -y -q update
    apt-get -y -q upgrade
    #apt-get install -q -y --allow-downgrades ${fuckmono[@]} || apt-get install -q -y --force-yes ${fuckmono[@]}
    apt-get -y -q autoremove
  fi
else
  if [[ $distro == "Ubuntu" ]]; then
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF >/dev/null 2>&1
  elif [[ $distro == "Debian" ]]; then
    if [[ $version == "jessie" ]]; then
      apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF >/dev/null 2>&1
      cd /tmp
      wget -q -O libjpeg8.deb http://ftp.fr.debian.org/debian/pool/main/libj/libjpeg8/libjpeg8_8d-1+deb7u1_amd64.deb
      dpkg -i libjpeg8.deb >/dev/null 2>&1
    else
      gpg --keyserver http://keyserver.ubuntu.com --recv 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF >/dev/null 2>&1
      gpg --export 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF > /etc/apt/trusted.gpg.d/mono-xamarin.gpg
    fi
  fi
  echo "Upgrading to mono snapshot v5.8"
  echo "deb https://download.mono-project.com/repo/debian wheezy/snapshots/5.8/. main" > /etc/apt/sources.list.d/mono-xamarin.list
  apt-get -y -q update
  apt-get -y -q install mono-complete
  apt-get -y -q upgrade
fi
  for a in sonarr jackett radarr; do
  if [[ $a = "active" ]]; then
    if [[ $a =~ ("sonarr"|"jackett") ]]; then
      a=$a@$master
    fi
    systemctl restart $a
  fi
  done
fi