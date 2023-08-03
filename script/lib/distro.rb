#!/usr/bin/env ruby

require 'optionparser'

class DistroMap
  attr_reader :entries

  def initialize(map = nil)
    @entries = map || self.class.builtin_map
  end
  # Returns the map for our distros.
  #
  # The key in each case is a string containing a lowercase OS name, a slash,
  # and a version number.  The value is a map containing the following fields:
  #
  # name:: a human-readable name for this distro.
  # component:: a component suitable for a packagecloud.io URL.
  # image:: a Docker image name from build_dockers without any extension.
  # equivalent:: packagecloud.io components for which we can upload the same
  # package.
  # package_type:: the extension for the package format on this OS.
  # package_tag:: the trailing component after the version number on this OS.
  def self.builtin_map
    {
      # RHEL EOL https://access.redhat.com/support/policy/updates/errata
      "centos/7" => {
        name: "RPM RHEL 7/CentOS 7",
        component: "el/7",
        image: "centos_7",
        package_type: "rpm",
        package_tag: "-1.el7",
        equivalent: [
          "el/7",         # EOL June 2024
          "scientific/7", # EOL June 2024
          # opensuse https://en.opensuse.org/Lifetime
          # or https://en.wikipedia.org/wiki/OpenSUSE_version_history
          "opensuse/15.4", # EOL November 2023
          # SLES EOL https://www.suse.com/lifecycle/
          "sles/12.5", # EOL October 2024 (LTSS October 2027)
          "sles/15.4", # Current
        ],
      },
      "centos/8" => {
        name: "RPM RHEL 8/Rocky Linux 8",
        component: "el/8",
        image: "centos_8",
        package_type: "rpm",
        package_tag: "-1.el8",
        equivalent: [
          "el/8",
        ],
      },
      "rocky/9" => {
        name: "RPM RHEL 9/Rocky Linux 9",
        component: "el/9",
        image: "rocky_9",
        package_type: "rpm",
        package_tag: "-1.el9",
        equivalent: [
          "el/9",
          "fedora/37", # EOL November 2023
          "fedora/38", # EOL May 2024
        ],
      },
      # Debian EOL https://wiki.debian.org/LTS/
      # Ubuntu EOL https://wiki.ubuntu.com/Releases
      # Mint EOL https://linuxmint.com/download_all.php
      "debian/10" => {
        name: "Debian 10",
        component: "debian/buster",
        image: "debian_10",
        package_type: "deb",
        package_tag: "",
        equivalent: [
          "debian/buster",    # EOL June 2024
          "linuxmint/ulyana", # EOL April 2025
          "linuxmint/ulyssa", # EOL April 2025
          "linuxmint/uma",    # EOL April 2025
          "linuxmint/una",    # EOL April 2025
          "ubuntu/focal",     # EOL April 2025
        ],
      },
      "debian/11" => {
        name: "Debian 11",
        component: "debian/bullseye",
        image: "debian_11",
        package_type: "deb",
        package_tag: "",
        equivalent: [
          "debian/bullseye",  # EOL June 2026
          "ubuntu/jammy",     # EOL April 2027
          "ubuntu/kinetic",   # EOL July 2023
          "ubuntu/lunar",     # EOL January 2024
          "linuxmint/vanessa",# EOL April 2027
          "linuxmint/vera",   # EOL April 2027
        ],
      },
      "debian/12" => {
        name: "Debian 12",
        component: "debian/bookworm",
        image: "debian_12",
        package_type: "deb",
        package_tag: "",
        equivalent: [
          "debian/bookworm",  # Current stable
          "debian/trixie",    # Current testing
        ]
      },
    }
  end

  def distro_name_map
    entries.map { |k, v| [k, v[:equivalent]] }.to_h
  end

  def image_names
    entries.values.map { |v| v[:image] }.to_a
  end
end

class DistroMapProgram
  def initialize(stdout, stderr, dmap = nil)
    @dmap = DistroMap.new(dmap)
    @stdout = stdout
    @stderr = stderr
  end

  def image_names
    @stdout.puts @dmap.image_names.join(" ")
  end

  def distro_markdown
    arch = {
      "rpm" => ".x86_64",
      "deb" => "_amd64",
    }
    separator = {
      "rpm" => "-",
      "deb" => "_",
    }
    result = @dmap.entries.map do |_k, v|
      type = v[:package_type]
      "[#{v[:name]}](https://packagecloud.io/github/git-lfs/packages/#{v[:component]}/git-lfs#{separator[type]}VERSION#{v[:package_tag]}#{arch[type]}.#{type}/download)\n"
    end.join
    @stdout.puts result
  end

  def run(args)
    options = {}
    OptionParser.new do |parser|
      parser.on("--image-names", "Print the names of all images") do
        options[:mode] = :image_names
      end

      parser.on("--distro-markdown", "Print links to packages for all distros") do
        options[:mode] = :distro_markdown
      end
    end.parse!(args)

    case options[:mode]
    when nil
      @stderr.puts "A mode option is required"
      2
    when :image_names
      image_names
      0
    when :distro_markdown
      distro_markdown
      0
    end
  end
end

if $PROGRAM_NAME == __FILE__
  exit DistroMapProgram.new($stdout, $stderr).run(ARGV)
end
