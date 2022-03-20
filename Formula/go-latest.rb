class GoLatest < Formula
  desc "Latest Go, fuck the 100000000 deps"
  homepage "https://go.dev/"
  url "https://go.dev/dl/go1.18.src.tar.gz"
  sha256 "38f423db4cc834883f2b52344282fa7a39fbb93650dc62a11fdf0be6409bdad6"
  license "BSD-3-Clause"
  head "https://go.googlesource.com/go.git", branch: "master"
  conflicts_with "go", because: "it sucks, runs years of CI for a minor update"

  # Don't update this unless this version cannot bootstrap the new version.
  resource "gobootstrap" do
    on_macos do
      if Hardware::CPU.arm?
        url "https://go.dev/dl/go1.17.8.darwin-arm64.tar.gz"
        version "1.17.8"
        sha256 "2827fb5d62453b30f0644382e22ab9d287c7bca868c374a15145b29e272443b1"
      else
        url "https://go.dev/dl/go1.17.8.darwin-amd64.tar.gz"
        version "1.17.8"
        sha256 "345f530a6a4295a1bf0a25931c08bf31582ed83252580196bd643049dfef0563"
      end
    end

    on_linux do
      if Hardware::CPU.arm?
        url "https://go.dev/dl/go1.17.8.linux-arm64.tar.gz"
        version "1.17.8"
        sha256 "57a9171682e297df1a5bd287be056ed0280195ad079af90af16dcad4f64710cb"
      else
        url "https://go.dev/dl/go1.17.8.linux-amd64.tar.gz"
        version "1.17.8"
        sha256 "980e65a863377e69fd9b67df9d8395fd8e93858e7a24c9f55803421e453f4f99"
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
