use ExtUtils::MakeMaker;

warn "Carp::Assert likes to have B::Deparse but can't find it.\n" unless 
  eval { require B::Deparse };

WriteMakefile(
    NAME        => 'Carp::Assert',
    VERSION_FROM => 'lib/Carp/Assert.pm', # finds $VERSION
    PREREQ_PM   => { Carp       => 0,
                     Test::More => 0.40,
                   },
    'dist'      => {COMPRESS => 'gzip -9',
                    SUFFIX   => '.gz',
                    DIST_DEFAULT => 'all tardist',
                   },
);

{
    package MY;
    sub top_targets {
        my($self) = @_;

        return $self->SUPER::top_targets(@_) unless
          eval { require Pod::Tests; 1 };

        my $out = "POD2TEST_EXE = pod2test\n";

        $out .= $self->SUPER::top_targets(@_);
        $out =~ s/^(pure_all\b.*)/$1 testifypods/m;

        foreach my $pod (keys %{$self->{MAN1PODS}},
                         keys %{$self->{MAN3PODS}})
        {
            (my $test = $pod) =~ s/\.(pm|pod)$//;
            $test =~ s/^lib\W//;
            $test =~ s/\W/-/;
            $test = "t/embedded-$test.t";
            
            $pod2test{$pod} = $test;
        }

        $out .= <<"END_OF_MAKE";

testifypods : @{[ join " ", values %pod2test ]}
\t\$(NOECHO) \$(NOOP)

END_OF_MAKE
        
        for my $pod (keys %pod2test) {
            my $test = $pod2test{$pod};
            
            $out .= <<"END_OF_MAKE";
$test : $pod
\t\$(NOECHO) \$(ECHO) Testifying $pod to $test
\t\$(NOECHO) \$(POD2TEST_EXE) $pod $test

END_OF_MAKE
        }

        return $out;
    }


    sub test_via_harness {
        my($self, $orig_perl, $tests) = @_;

        my @perls = ($orig_perl);
        push @perls, qw(bleadperl
                        perl5.6.1
                        perl5.005_03
                        perl5.004_05
                        perl5.004_04
                        perl5.004
                       )
          if $ENV{PERL_TEST_ALL};

        my $out;
        foreach my $perl (@perls) {
            $out .= $self->SUPER::test_via_harness($perl, $tests);
        }

        return $out;
    }
}
