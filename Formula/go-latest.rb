class GoLatest < Formula
  desc "Latest Go, fuck the 100000000 deps"
  homepage "https://go.dev/"
  url "https://go.dev/dl/go1.20.src.tar.gz"
  sha256 "3a29ff0421beaf6329292b8a46311c9fbf06c800077ceddef5fb7f8d5b1ace33"
  license "BSD-3-Clause"
  head "https://go.googlesource.com/go.git", branch: "master"
  conflicts_with "go", because: "it sucks, runs years of CI for a minor update"

  # Don't update this unless this version cannot bootstrap the new version.
  resource "gobootstrap" do
    on_macos do
      if Hardware::CPU.arm?
        url "https://go.dev/dl/go1.18.5.darwin-arm64.tar.gz"
        version "1.18.5"
        sha256 "923a377c6fc9a2c789f5db61c24b8f64133f7889056897449891f256af34065f"
      else
        url "https://go.dev/dl/go1.18.5.darwin-amd64.tar.gz"
        version "1.18.5"
        sha256 "828eeca8b5abea3e56921df8fa4b1101380a5ebcfee10acbc8ffe7ec0bf5876b"
      end
    end

    on_linux do
      if Hardware::CPU.arm?
        url "https://go.dev/dl/go1.18.5.linux-arm64.tar.gz"
        version "1.18.5"
        sha256 "006f6622718212363fa1ff004a6ab4d87bbbe772ec5631bab7cac10be346e4f1"
      else
        url "https://go.dev/dl/go1.18.5.linux-amd64.tar.gz"
        version "1.18.5"
        sha256 "9e5de37f9c49942c601b191ac5fba404b868bfc21d446d6960acc12283d6e5f2"
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
