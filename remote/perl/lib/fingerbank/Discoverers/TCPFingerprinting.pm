package fingerbank::Discoverers::TCPFingerprinting;

use Moose;

sub match {
    my ($args, $other_results) = @_;
    my $logger = fingerbank::Log::get_logger;
    $logger->info("Change me. I'm not doing anything.");
    return ($fingerbank::Status::OK, {
        "created_at" => "2015-09-29T13 =>15 =>52.558Z", 
        "device" => {
            "created_at" => "2014-09-09T15 =>10 =>22.000Z", 
            "id" => 264, 
            "inherit" => 0, 
            "mobile" => 1, 
            "name" => "Apple iPhone", 
            "parent_id" => 193, 
            "parents" => [
                {
                    "approved" => 1, 
                    "created_at" => "2014-09-09T15 =>09 =>52.000Z", 
                    "id" => 193, 
                    "inherit" => 0, 
                    "mobile" => 1, 
                    "name" => "Apple iPod, iPhone or iPad", 
                    "parent_id" => 11, 
                    "submitter_id" => undef, 
                    "tablet" => 0, 
                    "updated_at" => "2015-02-04T15 =>53 =>52.000Z"
                }, 
                {
                    "approved" => 0, 
                    "created_at" => "2014-09-09T15 =>09 =>50.000Z", 
                    "id" => 11, 
                    "inherit" => 0, 
                    "mobile" => 0, 
                    "name" => "Smartphones/PDAs/Tablets", 
                    "parent_id" => undef, 
                    "submitter_id" => undef, 
                    "tablet" => 0, 
                    "updated_at" => "2014-11-14T19 =>02 =>32.000Z"
                }
            ], 
            "updated_at" => "2015-02-06T15 =>53 =>26.000Z"
        }, 
        "id" => 478340, 
        "score" => 5, 
        "updated_at" => "2015-09-29T13 =>15 =>52.697Z", 
        "version" => undef
    });
 
    return $fingerbank::Status::NOT_FOUND; 
}

1;
