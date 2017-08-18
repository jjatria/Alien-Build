package Alien::Build::Plugin::Extract::ArchiveTar;

use strict;
use warnings;
use Alien::Build::Plugin;
use File::chdir;
use File::Temp ();
use Path::Tiny ();

# ABSTRACT: Plugin to extract a tarball using Archive::Tar
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'Extract::ArchiveTar' => (
   format => 'tar.gz',
 );

=head1 DESCRIPTION

Note: in most case you will want to use L<Alien::Build::Plugin::Extract::Negotiate>
instead.  It picks the appropriate Extract plugin based on your platform and environment.
In some cases you may need to use this plugin directly instead.

This plugin extracts from an archive in tarball format (optionally compressed by either
gzip or bzip2) using L<Archive::Tar>.

=head1 PROPERTIES

=head2 format

Gives a hint as to the expected format.  This helps make sure the prerequisites are set
correctly, since compressed archives require extra Perl modules to be installed.

=cut

has '+format' => 'tar';

=head1 METHODS

=head2 handles

 Alien::Build::Plugin::Extract::ArchiveTar->handles($ext);
 $plugin->handles($ext);

Returns true if the plugin is able to handle the archive of the
given format.

=cut

sub handles
{
  my($class, $ext) = @_;
  
  return 1 if $ext =~ /^(tar|tar.gz|tar.bz2|tbz|taz)$/;
  
  return;
}

sub init
{
  my($self, $meta) = @_;
  
  $meta->add_requires('share' => 'Archive::Tar' => 0);
  if($self->format eq 'tar.gz' || $self->format eq 'tgz')
  {
    $meta->add_requires('share' => 'IO::Zlib' => 0);
  }
  elsif($self->format eq 'tar.bz2' || $self->format eq 'tbz')
  {
    $meta->add_requires('share' => 'IO::Uncompress::Bunzip2' => 0);
    $meta->add_requires('share' => 'IO::Compress::Bzip2' => 0);
  }
  
  $meta->register_hook(
    extract => sub {
      my($build, $src) = @_;
      my $tar = Archive::Tar->new;
      $tar->read($src);
      $tar->extract;
    }
  );
}

sub _can_bz2
{
  # even when Archive::Tar reports that it supports bz2, I can sometimes get this error:
  # 'Cannot read enough bytes from the tarfile', so lets just probe for actual support!
  my $dir = Path::Tiny->new(File::Temp::tempdir( CLEANUP => 1 ));
  eval {
    local $CWD = $dir;
    my $tarball = unpack "u", q{M0EIH.3%!62936=+(]$0``$A[D-$0`8!``7^``!!AI)Y`!```""``=!JGIH-(MT#0]0/2!**---&F@;4#0&:D;X?(6@JH(2<%'N$%3VHC-9E>S/N@"6&I*1@GNJNHCC2>$I5(<0BKR.=XBZ""HVZ;T,CV\LJ!K&*?9`#\7<D4X4)#2R/1$`};
    Path::Tiny->new('xx.tar.bz2')->spew_raw($tarball);
    require Archive::Tar;
    my $tar = Archive::Tar->new;
    $tar->read('xx.tar.bz2');
    $tar->extract;
    my $content = Path::Tiny->new('xx.txt')->slurp;
    die unless $content && $content eq "xx\n";
  };
  my $error = $@;
  $dir->remove_tree;
  !$error;
}

1;

=head1 SEE ALSO

L<Alien::Build::Plugin::Extract::Negotiate>, L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut