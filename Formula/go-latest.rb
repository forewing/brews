class GoLatest < Formula
  desc "Latest Go, fuck the 100000000 deps"
  homepage "https://go.dev/"
  url "https://go.dev/dl/go1.17.8.src.tar.gz"
  sha256 "2effcd898140da79a061f3784ca4f8d8b13d811fb2abe9dad2404442dabbdf7a"
  license "BSD-3-Clause"
  head "https://go.googlesource.com/go.git", branch: "master"
  conflicts_with "go", because: "it sucks, runs years of CI for a minor update"

  # Don't update this unless this version cannot bootstrap the new version.
  resource "gobootstrap" do
    on_macos do
      if Hardware::CPU.arm?
        url "https://go.dev/dl/go1.17.darwin-arm64.tar.gz"
        version "1.17"
        sha256 "da4e3e3c194bf9eed081de8842a157120ef44a7a8d7c820201adae7b0e28b20b"
      else
        url "https://go.dev/dl/go1.17.darwin-amd64.tar.gz"
        version "1.17"
        sha256 "355bd544ce08d7d484d9d7de05a71b5c6f5bc10aa4b316688c2192aeb3dacfd1"
      end
    end

    on_linux do
      if Hardware::CPU.arm?
        url "https://go.dev/dl/go1.17.linux-arm64.tar.gz"
        version "1.17"
        sha256 "01a9af009ada22122d3fcb9816049c1d21842524b38ef5d5a0e2ee4b26d7c3e7"
      else
        url "https://go.dev/dl/go1.17.linux-amd64.tar.gz"
        version "1.17"
        sha256 "6bf89fc4f5ad763871cf7eac80a2d594492de7a818303283f1366a7f6a30372d"
      end
    end
  end

  def install
    (buildpath/"gobootstrap").install resource("gobootstrap")
    ENV["GOROOT_BOOTSTRAP"] = buildpath/"gobootstrap"

    cd "src" do
      ENV["GOROOT_FINAL"] = libexec
      system "./make.bash", "--no-clean"
    end

    (buildpath/"pkg/obj").rmtree
    rm_rf "gobootstrap" # Bootstrap not required beyond compile.
    libexec.install Dir["*"]
    bin.install_symlink Dir[libexec/"bin/go*"]

    system bin/"go", "install", "-race", "std"

    # Remove useless files.
    # Breaks patchelf because folder contains weird debug/test files
    (libexec/"src/debug/elf/testdata").rmtree
    # Binaries built for an incompatible architecture
    (libexec/"src/runtime/pprof/testdata").rmtree
  end

  test do
    (testpath/"hello.go").write <<~EOS
      package main
      import "fmt"
      func main() {
          fmt.Println("Hello World")
      }
    EOS
    # Run go fmt check for no errors then run the program.
    # This is a a bare minimum of go working as it uses fmt, build, and run.
    system bin/"go", "fmt", "hello.go"
    assert_equal "Hello World\n", shell_output("#{bin}/go run hello.go")

    ENV["GOOS"] = "freebsd"
    ENV["GOARCH"] = "amd64"
    system bin/"go", "build", "hello.go"
  end
end
