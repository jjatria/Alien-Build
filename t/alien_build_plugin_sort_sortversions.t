use Test2::Bundle::Extended;
use Alien::Build::Plugin::Sort::SortVersions;
use lib 't/lib';
use MyTest;
use Path::Tiny qw( path );

subtest 'updates requires' => sub {

  my $plugin = Alien::Build::Plugin::Sort::SortVersions->new;

  my($build,$meta) = build_blank_alien_build;
  
  $plugin->init($meta);
  
  is( $build->requires('share')->{'Sort::Versions'}, 0 );

  note $meta->_dump;

};

subtest 'sort' => sub {

  my $builder = sub {
    my $plugin = Alien::Build::Plugin::Sort::SortVersions->new(@_);
    my($build,$meta) = build_blank_alien_build;
    $plugin->init($meta);
    eval { $build->load_requires('share') };
    $@ ? () : wantarray ? ($build,$meta) : $build;
  };
  
  my $make_list = sub {
    return {
      type => 'list',
      list => [
        map {
          my $h = { filename => $_, url => "http://example.test/foo/bar/$_" };
        } @_
      ],
    };
  };

  skip_all 'test requires Sort::Versions' unless $builder->();

  subtest 'default settings' => sub {
  
    my $build = $builder->();
    
    my $res = $build->sort($make_list->(qw(roger-0.0.0.tar.gz abc-2.3.4.tar.gz xyz-1.0.0.tar.gz)));
    is( $res, $make_list->(qw( abc-2.3.4.tar.gz xyz-1.0.0.tar.gz roger-0.0.0.tar.gz )) );
  
  };
  
  subtest 'filter' => sub {
  
    my $build = $builder->(filter => qr/abc|xyz/);
    my $res = $build->sort($make_list->(qw(roger-0.0.0.tar.gz abc-2.3.4.tar.gz xyz-1.0.0.tar.gz)));
    is( $res, $make_list->(qw( abc-2.3.4.tar.gz xyz-1.0.0.tar.gz )) );
  
  };
  
  subtest 'version regex' => sub {
  
    my $build = $builder->(qr/^foo-[0-9\.]+-bar-([0-9\.])/);
    my $res = $build->sort($make_list->(qw( foo-10.0-bar-0.1.0.tar.gz foo-5-bar-2.1.0.tar.gz bogus.tar.gz )));
    is( $res, $make_list->(qw( foo-5-bar-2.1.0.tar.gz foo-10.0-bar-0.1.0.tar.gz )) );
    
  };

};

done_testing;
