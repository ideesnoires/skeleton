require 'haml/util'

module Haml
  # Handles Haml version-reporting.
  # Haml not only reports the standard three version numbers,
  # but its Git revision hash as well,
  # if it was installed from Git.
  module Version
    include Haml::Util

    # Returns a hash representing the version of Haml.
    # The `:major`, `:minor`, and `:teeny` keys have their respective numbers as Fixnums.
    # The `:name` key has the name of the version.
    # The `:string` key contains a human-readable string representation of the version.
    # The `:number` key is the major, minor, and teeny keys separated by periods.
    # If Haml is checked out from Git, the `:rev` key will have the revision hash.
    # For example:
    #
    #     {
    #       :string => "2.1.0.9616393",
    #       :rev    => "9616393b8924ef36639c7e82aa88a51a24d16949",
    #       :number => "2.1.0",
    #       :major  => 2, :minor => 1, :teeny => 0
    #     }
    #
    # @return [{Symbol => String/Fixnum}] The version hash
    def version
      return @@version if defined?(@@version)

      numbers = File.read(scope('VERSION')).strip.split('.').map { |n| n.to_i }
      name = File.read(scope('VERSION_NAME')).strip
      @@version = {
        :major => numbers[0],
        :minor => numbers[1],
        :teeny => numbers[2],
        :name => name
      }
      @@version[:number] = [:major, :minor, :teeny].map { |comp| @@version[comp] }.compact.join('.')
      @@version[:string] = @@version[:number].dup

      if rev = revision_number
        @@version[:rev] = rev
        unless rev[0] == ?(
          @@version[:string] << "." << rev[0...7]
        end
      end

      @@version[:string] << " (#{name})"
      @@version
    end

    private

    def revision_number
      if File.exists?(scope('REVISION'))
        rev = File.read(scope('REVISION')).strip
        return rev unless rev =~ /^([a-f0-9]+|\(.*\))$/ || rev == '(unknown)'
      end

      return unless File.exists?(scope('.git/HEAD'))
      rev = File.read(scope('.git/HEAD')).strip
      return rev unless rev =~ /^ref: (.*)$/

      ref_name = $1
      ref_file = scope(".git/#{ref_name}")
      info_file = scope(".git/info/refs")
      return File.read(ref_file).strip if File.exists?(ref_file)
      return unless File.exists?(info_file)
      File.open(info_file) do |f|
        f.each do |l|
          sha, ref = l.strip.split("\t", 2)
          next unless ref == ref_name
          return sha
        end
      end
      return nil
    end
  end
end
