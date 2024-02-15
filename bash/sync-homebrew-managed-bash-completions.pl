#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;
use File::Spec::Functions;
use File::Path qw(make_path);
use Cwd 'abs_path';

# This script is an automated workaround for the integration of HomeBrew-installed 'bash-completion' scripts for modern
# (v2) 'bash-completion' instead of legacy (v1) 'bash-completion'
#
# Specifically, this script creates symlinks pointing to completion files located in the HomeBrew-managed directory
# '/opt/homebrew/etc/bash_completion.d/' and the symlink files are created in
# '$HOME/.local/share/bash-completion/completions' which is a conventional directory that 'bash-completion' looks for
# v2-based completions.
#
# As an additional feature, the script also cleans up any dangling symlinks in the '.local' directory, which will
# occur if you uninstall a HomeBrew package that came with completions, like 'docker', 'kcat', etc.
#
# For more information, see https://github.com/dgroomes/my-config

sub remove_symlink {
    my ($dest_file) = @_;

    # Check if the symlink is dangling
    if (!-e $dest_file) {
        print "Removing dangling symlink for " . basename($dest_file) . "...\n";
        unlink($dest_file) or warn "Couldn't remove symlink: $!";
    }
}

my $homebrew_completions_dir = '/opt/homebrew/etc/bash_completion.d/';
my $local_completions_dir = "$ENV{HOME}/.local/share/bash-completion/completions";

if (!-d $homebrew_completions_dir) {
    print "The HomeBrew Bash completions directory ('$homebrew_completions_dir') does not exist. There is no work to do. Exiting...\n";
    exit;
}

if (!-d $local_completions_dir) {
    print "The local completions directory ('$local_completions_dir') does not exist. Creating it...\n";
    make_path($local_completions_dir) or die "Unable to create destination directory: $!";
}

# Loop through each HomeBrew completions file and symlink it to the local completions directory
opendir(my $dh, $homebrew_completions_dir) or die "Can't open $homebrew_completions_dir: $!";
while (my $filename = readdir $dh) {
    next if $filename =~ /^\./;  # Skip hidden files and directories

    my $source_file = catfile($homebrew_completions_dir, $filename);
    my $dest_file = catfile($local_completions_dir, $filename);

    # Skip if it's a directory
    next if -d $source_file;

    # Skip if there is already a file at the destination. There are two cases where a file might exist:
    #   - We've already created a symlink for this file
    #   - Some HomeBrew-installed packages like 'fnm' and 'gh' seem to automatically copy their completions to the local
    #     completions directory.
    next if -e $dest_file;

    print "Creating symlink for " . basename($source_file) . "...\n";
    symlink($source_file, $dest_file) or warn "Couldn't create symlink: $!";
}
closedir $dh;

# Clean up any dangling symlinks in the local completions directory
opendir($dh, $local_completions_dir) or die "Can't open $local_completions_dir: $!";
while (my $filename = readdir $dh) {
    next if $filename =~ /^\./;  # Skip hidden files and directories

    my $dest_file = catfile($local_completions_dir, $filename);

    # Skip if it's not a symlink
    next unless -l $dest_file;

    remove_symlink($dest_file);
}
closedir $dh;

print "Done!\n";
