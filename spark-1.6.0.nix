{ stdenv, fetchurl, makeWrapper, jre, pythonPackages
, mesosSupport ? true, mesos
}:

with stdenv.lib;

stdenv.mkDerivation rec {
  name    = "spark-${version}";
  version = "1.6.0";

  src = fetchurl {
    url    = "mirror://apache/spark/${name}/${name}-bin-cdh4.tgz";
    sha256 = "0waq8xx4bjj1yvfbadv1gdvz8s4kh5zasicv2n5623ld6lj7zgad";
  };

  buildInputs = [ makeWrapper jre pythonPackages.python pythonPackages.numpy ]
    ++ optional mesosSupport [ mesos ];

  untarDir = "${name}-bin-cdh4";
  installPhase = ''
    mkdir -p $out/{lib/${untarDir}/conf,bin}
    mv * $out/lib/${untarDir}

    cat > $out/lib/${untarDir}/conf/spark-env.sh <<- EOF
    export JAVA_HOME="${jre}"
    export SPARK_HOME="$out/lib/${untarDir}"
    export PYSPARK_PYTHON="${pythonPackages.python}/bin/${pythonPackages.python.executable}"
    export PYTHONPATH="\$PYTHONPATH:$PYTHONPATH"
    ${optionalString mesosSupport
      ''export MESOS_NATIVE_LIBRARY="$MESOS_NATIVE_LIBRARY"''}
    EOF

    for n in $(find $out/lib/${untarDir}/bin -type f ! -name "*.*"); do
      makeWrapper "$n" "$out/bin/$(basename $n)"
    done
  '';

  meta = {
    description      = "Lightning-fast cluster computing";
    homepage         = "http://spark.apache.org";
    license          = stdenv.lib.licenses.asl20;
    platforms        = stdenv.lib.platforms.all;
    maintainers      = with maintainers; [ thoughtpolice offline ];
    repositories.git = git://git.apache.org/spark.git;
  };
}
