package HTML::SocialMedia;

use warnings;
use strict;
use CGI::Lingua;

=head1 NAME

HTML::SocialMedia - Put social media links into your website

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';

=head1 SYNOPSIS

Many websites these days have links and buttons into social media sites.
This module eases links into Twitter, Facebook and Google's PlusOne.

    use HTML::SocialMedia;

    my $sm = HTML::SocialMedia->new();
    # ...

=head1 SUBROUTINES/METHODS

=head2 new

Creates a HTML::SocialMedia object.

    use HTML::SocialMedia;

    my $sm = HTML::SocialMedia->new(twitter => 'example');
    # ...

=head3 Optional parameters

twitter: twitter account name
twitter_related: array of 2 elements - the name and description of a related account

=cut

sub new {
	my ($proto, %params) = @_;

	my $class = ref($proto) || $proto;

	my $lingua;
	if($params{twitter}) {
		# Languages supported by Twitter according to
		# https://twitter.com/about/resources/tweetbutton
		$lingua = CGI::Lingua->new(supported => ['en', 'nl', 'fr', 'fr-fr', 'de', 'id', 'il', 'ja', 'ko', 'pt', 'ru', 'es', 'tr']),
	} else {
		use I18N::LangTags::Detect;
		# Facebook supports just about everything
		my @l = I18N::LangTags::implicate_supers_strictly(I18N::LangTags::Detect::detect());
		if(@l) {
			$lingua = CGI::Lingua->new(supported => [$l[0]]);
		}
		unless($lingua) {
			$lingua = CGI::Lingua->new(supported => []);
		}
	}

	my $self = {
		_lingua => $lingua,
		_twitter => $params{twitter},
		_twitter_related => $params{twitter_related},
		_alpha2 => undef,
	};
	bless $self, $class;

	return $self;
}

=head2 as_string

Returns the HTML to be added to your website.
HTML::SocialMedia uses L<CGI::Lingua> to try to ensure that the text printed is
in the language of the user.

    use HTML::SocialMedia;

    my $sm = HTML::SocialMedia->new(
    	twitter => 'mytwittername',
    	twotter_related => [ 'someonelikeme', 'another twitter feed' ]
    );

    print "Content-type: text/html\n\n";

    print'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">';print '<HTML><HEAD></HEAD><BODY>';
    print $sm->as_string(
    	twitter_follow_button => 1,
    	twitter_tweet_button => 1,
    	facebook_like_button => 1,
	linkedin_share_button => 1,
    	google_plusone => 1
    );

    print '</BODY></HTML>';
    print "\n";

=head3 Optional parameters

twitter_follow_button: add a button to follow the account

twitter_tweet_button: add a button to tweet this page

facebook_like_button: add a Facebook like button

linkedin_share_button; add a LinkedIn share button

google_plusone: add a Google +1 button

=cut

sub as_string {
	my ($self, %params) = @_;

	unless($self->{_alpha2}) {
		my $alpha2 = $self->{_lingua}->code_alpha2();

		if($alpha2) {
			my $salpha2 = $self->{_lingua}->sublanguage_code_alpha2();
			unless($salpha2) {
				my $locale = $self->{_lingua}->locale();
				if($locale) {
					$salpha2 = $locale->code_alpha2();
				}
			}
			if($salpha2) {
				$salpha2 = uc($salpha2);
				$alpha2 .= "_$salpha2";
			} else {
				my $locale = $self->{_lingua}->locale();
				if($locale) {
					my @l = $locale->languages_official();
					$alpha2 = lc($l[0]->code_alpha2()) . '_' . uc($locale->code_alpha2());
				} else {
					$alpha2 = undef;
				}
			}
		}

		unless($alpha2) {
			my $locale = $self->{_lingua}->locale();
			if($locale) {
				my @l = $locale->languages_official();
				$alpha2 = lc($l[0]->code_alpha2()) . '_' . uc($locale->code_alpha2());
			} else {
				$alpha2 = 'en_GB';
			}
		}
		$self->{_alpha2} = $alpha2;
	}

	my $rc;

	if($self->{_twitter}) {
		if($params{twitter_follow_button}) {
			my $language = $self->{_lingua}->language();
			if(($language eq 'English') || ($language eq 'Unknown')) {
				$rc = '<a href="http://twitter.com/' . $self->{_twitter} . '" class="twitter-follow-button">Follow @' . $self->{_twitter} . '</a>';
			} else {
				my $langcode = substr($self->{_alpha2}, 0, 2);
				$rc = '<a href="http://twitter.com/' . $self->{_twitter} . "\" class=\"twitter-follow-button\" data-lang=\"$langcode\">Follow \@" . $self->{_twitter} . '</a>';
			}
			if($params{twitter_tweet_button}) {
				$rc .= '<p>';
			}
		}
		if($params{twitter_tweet_button}) {
			$rc .= << 'END';
				<script type="text/javascript">
					var t = document.createElement('SCRIPT'), t1 = document.getElementsByTagName('HEAD')[0];
					t.type = 'text/javascript';
					t.async = true;
					t.src = "http://platform.twitter.com/widgets.js";
					t1.parentNode.insertBefore(t, t1);
				</script>
				<a href="http://twitter.com/share" class="twitter-share-button" data-count="horizontal" data-via="
END
			$rc .= $self->{_twitter} . '"';
			if($self->{_twitter_related}) {
				my @related = @{$self->{_twitter_related}};
				$rc .= ' data-related="' . $related[0] . ':' . $related[1] . '"';
			}
			$rc .= '>Tweet</a><script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>';
		}
	}
	if($params{facebook_like_button}) {
		if($params{twitter_tweet_button} || $params{twitter_follow_button}) {
			$rc .= '<p>';
		}

		# See if Facebook supports our wanted language. If not then
		# I suppose we could enuerate through other requested languages,
		# but that is probably not worth the effort.

		my $url = "http://connect.facebook.net/$self->{_alpha2}/all.js#xfbml=1";

		# Resposnse is of type HTTP::Response
		require LWP::UserAgent;

		my $response = LWP::UserAgent->new->request(HTTP::Request->new(GET => $url));
		if($response->is_success()) {
			# If it's not supported, Facebook doesn't return an HTTP
			# error such as 404, it returns a string, which no doubt
			# will get changed at sometime in the future. Sigh.
			if($response->decoded_content() =~ /is not a valid locale/) {
				# TODO: Guess more appropriate fallbacks
				$url = 'http://connect.facebook.net/en_GB/all.js#xfbml=1';
			}
		} else {
			$url = 'http://connect.facebook.net/en_GB/all.js#xfbml=1';
		}

		$rc .= << 'END';
			<div id="facebook">
			<div id="fb-root"></div>
			<script type="text/javascript">
				document.write('<' + 'fb:like send="false" layout="button_count" width="100" show_faces="false" font=""></fb:like>');
				var s = document.createElement('SCRIPT'), s1 = document.getElementsByTagName('HEAD')[0];
				s.type = 'text/javascript';
				s.async = true;
END
		$rc .= "s.src = \"$url\";";

		$rc .= << 'END';
			s1.parentNode.insertBefore(s, s1);
		    </script>
		</div>
END
		if($params{google_plusone} || $params{linkedin_share_button}) {
			$rc .= '<p>';
		}
	}
	if($params{linkedin_share_button}) {
		$rc .= << 'END';
<script src="http://platform.linkedin.com/in.js" type="text/javascript"></script>
<script type="IN/Share" data-counter="right"></script>
END
	}
	if($params{google_plusone}) {
		$rc .= << 'END';
			<div id="gplus">
				<script type="text/javascript" src="https://apis.google.com/js/plusone.js">
					{"parsetags": "explicit"}
				</script>
				<div id="plusone-div"></div>

				<script type="text/javascript">
					gapi.plusone.render("plusone-div",{"size": "medium", "count": "true"});
				</script>
			</div>
END
	}

	return $rc;
}

=head2 render

Synonym for as_string.

=cut

sub render {
	my ($self, %params) = @_;

	return $self->as_string(%params);
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-socialmedia at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-SocialMedia>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SEE ALSO

HTTP::BrowserDetect


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::SocialMedia


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-SocialMedia>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-SocialMedia>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-SocialMedia>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-SocialMedia/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Nigel Horne.

This program is released under the following licence: GPL


=cut

1; # End of HTML::SocialMedia
