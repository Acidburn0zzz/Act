package Act::Handler::User::Purchase;
use Apache::Constants qw(NOT_FOUND);

use Act::Config;
use Act::Order;
use Act::Payment;
use Act::Template::HTML;

sub handler
{
    # shouldn't get here unless the online payment is open
    # and this user is registered and hasn't paid
    unless ($Config->payment_open &&
            $Request{user}->has_registered() &&
            !$Request{user}->has_paid)
    {
        $Request{status} = NOT_FOUND;
        return;
    }

    $Request{r}->no_cache(1);
    my $template = Act::Template::HTML->new();

    if (   $Request{args}{purchase}
        && $Request{args}{price}
        && (my $price = Act::Payment::get_price($Request{args}{price})))
    {
        # first form has been submitted
        # always a use a newly created order
        # (the bank will only process an order once)
        my %f = (
            user_id  => $Request{user}{user_id},
            conf_id  => $Request{conference},
            amount   => $price->{amount},
            currency => $Config->payment_currency,
            status   => 'init',
        );
        my $order = Act::Order->create(%f);

        # display second form (submits to the bank)
        my $plugin = Act::Payment::load_plugin();
        $template->variables(order => $order);
        $template->variables_raw(form => $plugin->create_form($order));
        $template->process('user/payment');
    }
    else {
        # display the first form
        $template->variables(
            currency => $Config->payment_currency,
            prices   => Act::Payment::get_prices,
        );
        $template->process('user/purchase');
    }
}

1;
__END__

=head1 NAME

Act::Handler::User::Purchase - purchase conference ticket

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
