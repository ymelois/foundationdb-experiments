{
  lib,
  stdenv,
  fetchFromGitHub,

  cmake,
  ninja,
  python3,
  python3Packages,
  jinja2 ? python3Packages.jinja2,
  build ? python3Packages.build,

  boost189,
  doctest,
  fmt_11,
  jemalloc,
  msgpack-cxx,
  openssl,
  toml11,
  zlib,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "foundationdb";
  version = "8.0.0";

  src = fetchFromGitHub {
    owner = "apple";
    repo = "foundationdb";
    tag = finalAttrs.version;
    hash = "sha256-PbZyJMTLP69WyLb+apZ97eGbh9x23eedNJ89EQ1OTJM=";
  };

  patches = [
    # https://github.com/apple/foundationdb/issues/14356
    ./use-dynamic-openssl.patch
    ./any-version-toml11.patch
    ./any-version-fmt.patch
    ./any-version-msgpack-cxx.patch
    ./use-dynamic-boost.patch
    ./fix-missing-cstdint.patch
  ];

  postPatch = ''
    substituteInPlace bindings/CMakeLists.txt \
      --replace-fail 'package_bindingtester()' "" \
      --replace-fail 'package_bindingtester2()' ""

    substituteInPlace flow/CMakeLists.txt \
      --replace-fail 'add_subdirectory(bench EXCLUDE_FROM_ALL)' ""

    substituteInPlace fdbrpc/CMakeLists.txt \
      --replace-fail 'add_subdirectory(bench EXCLUDE_FROM_ALL)' ""

    substituteInPlace fdbclient/CMakeLists.txt \
      --replace-fail 'add_subdirectory(bench EXCLUDE_FROM_ALL)' ""

    substituteInPlace fdbserver/CMakeLists.txt \
      --replace-fail 'add_subdirectory(bench/coroflow EXCLUDE_FROM_ALL)' ""

    substituteInPlace fdbserver/checkpoint/RocksDBCheckpointUtils.cpp \
      --replace-fail '#include "fdbserver/core/FDBRocksDBVersion.h"' ""

    substituteInPlace fdbserver/storageserver/storageserver.cpp \
      --replace-fail '#include "fdbserver/core/FDBRocksDBVersion.h"' ""

    substituteInPlace fdbserver/storageserver/storageserver.cpp \
      --replace-fail 'te.detail("RocksDBVersion", format("%d.%d.%d", FDB_ROCKSDB_MAJOR, FDB_ROCKSDB_MINOR, FDB_ROCKSDB_PATCH));' ""
  '';

  nativeBuildInputs = [
    cmake
    ninja
    python3
    jinja2
    build
  ];

  buildInputs = [
    boost189
    doctest
    fmt_11
    jemalloc
    msgpack-cxx
    openssl
    toml11
    zlib
  ];

  env = {
    NIX_CFLAGS_COMPILE = "-w";
  };

  cmakeFlags = [
    "-DFDB_RELEASE=TRUE"

    "-DSTATIC_LINK_LIBCXX=FALSE"

    "-DUSE_LTO=ON"
    "-DUSE_LD=GOLD"

    "-DUSE_CCACHE=OFF"
    "-DUSE_SCCACHE=OFF"

    "-DWITH_GRPC=OFF"
    "-DWITH_ROCKSDB=OFF"
    "-DWITH_SWIFT=OFF"
    "-DWITH_CSHARP=OFF"

    "-DBUILD_C_BINDING=ON"
    "-DBUILD_PYTHON_BINDING=OFF"
    "-DBUILD_JAVA_BINDING=OFF"
    "-DBUILD_GO_BINDING=OFF"
    "-DBUILD_RUBY_BINDING=OFF"
    "-DBUILD_SWIFT_BINDING=OFF"

    "-DBUILD_DOCUMENTATION=OFF"
    "-DBUILD_TESTING=OFF"
    "-DENABLE_UNIT_TESTS=OFF"
  ];

  doCheck = false;

  postInstall = ''
    rm -rf \
      $out/etc \
      $out/log \
      $out/usr \
      $out/var \
      $out/sbin \
      $out/lib/foundationdb \
      $out/lib/systemd

    mkdir -p \
      $dev/lib \
      $lib/lib

    mv $out/include $dev/include
    mv $out/lib/cmake $dev/lib/cmake
    mv $out/lib/pkgconfig $dev/lib/pkgconfig

    mv $out/lib/*.so $lib/lib/

    # fix pkg-config paths
    substituteInPlace $dev/lib/pkgconfig/foundationdb-client.pc \
      --replace-fail "libdir=/lib" "libdir=$lib/lib" \
      --replace-fail "includedir=/include" "includedir=$dev/include"

    # fix cmake paths
    substituteInPlace $dev/lib/cmake/FoundationDB-Client/FoundationDB-Client-release.cmake \
      --replace-fail "''${_IMPORT_PREFIX}/lib/libfdb_c.so" "$lib/lib/libfdb_c.so" \
      --replace-fail "''${_IMPORT_PREFIX}/lib/libfdb_c_shim.so" "$lib/lib/libfdb_c_shim.so"
  '';

  outputs = [
    "out"
    "dev"
    "lib"
  ];

  meta = {
    description = "Open source, distributed, transactional key-value store";
    homepage = "https://www.foundationdb.org/";
    license = lib.licenses.asl20;
    platforms = [
      "x86_64-linux"
    ];
  };
})
