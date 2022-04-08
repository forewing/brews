class YoutubeDl < Formula
  desc "Create youtube-dl linked to yt-dlp"
  homepage "https://github.com/yt-dlp/yt-dlp"
  url "file:///dev/null"
  sha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  version "1.0.0"
  license "The Unlicense"

  conflicts_with "youtube-dl", because: "naming conflict"
  depends_on "yt-dlp"

  def install
    yt_dlp_path = `which yt-dlp`.strip
    system yt_dlp_path, "--version"

    system "ln", "-s", yt_dlp_path, "youtube-dl"
    system "./youtube-dl", "--version"

    bin.install "youtube-dl"
  end

end
