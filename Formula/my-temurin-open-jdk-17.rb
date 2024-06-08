require "fileutils"

# I think well-behaved Homebrew formulas typically build from source (or are bottles built from the same instructions),
# but I'm veering from the standard because that's what I need and this isn't meant to be used by anyone else anyway.
# This formula downloads the Eclipse Temurin distribution of OpenJDK 17 and installs it as a keg.
#
# For now, I'm just installing from a local copy of the tar ball I already downloaded, but eventually I want to download
# from the Adoptium API or the file in the GitHub Releases.
#
# Reference:
#   - https://adoptium.net
#   - https://github.com/Homebrew/homebrew-core/blob/3f593a20333d496928a1daed45aedc8f1b2b454a/Formula/o/openjdk%4017.rb
class MyTemurinOpenJdk17 < Formula
  desc "My personal formula of the Eclipse Temurin distribution of OpenJDK 17"

  homepage "https://github.com/dgroomes/my-config"

  url "file:///Users/dave/subjects/2024-05-28_adoptium/OpenJDK17U-jdk_aarch64_mac_hotspot_17.0.11_9.tar.gz"

  version "1.0.2"

  sha256 "09a162c58dd801f7cfacd87e99703ed11fb439adc71cfa14ceb2d3194eaca01c"

  def install
    # The tar ball should extract exactly one top-level file, which is a directory named as the version number of
    # OpenJDK (e.g. "jdk-17.0.11+9"). Interestingly, at this point, Homebrew seems to have automatically changed the
    # current directory into that top-level directory. That's quite strange, because a tar ball could have multiple
    # files and directories in the top-level. After some quick searching, I can't find any documentation that describes
    # this behavior, so maybe I'm just interpreting something wrong. But this is actually annoying because I can't just
    # `libexec.install Dir["jdk*"].first => "openjdk"`. Instead, I need to build a containing directory and then move
    # "Contents" into it.
    openjdk_dir = libexec/"openjdk"
    openjdk_dir.mkpath
    contents_dir = Pathname.new(Dir.pwd)/"Contents"
    FileUtils.mv contents_dir, openjdk_dir

    # Create symlinks for all executables in the bin directory
    bin.install_symlink Dir[openjdk_dir/"Contents/Home/bin/*"]
  end
end
