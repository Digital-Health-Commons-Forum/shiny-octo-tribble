use Net::Amazon::S3;
use Net::Amazon::S3::Authorization::Basic;
use Net::Amazon::S3::Authorization::IAM;
use Net::Amazon::S3::Vendor::Generic;

my $aws_access_key_id     = '9fQuwMfXKMDwh9xd2YN6';
my $aws_secret_access_key = 'SGPKltl5v4FgshdB6zem8EZNyfaw3IgvdH35L5Cm';

use Net::Amazon::S3;
use Net::Amazon::S3::Client;
use Net::Amazon::S3::Client::Bucket;

my $s3 = Net::Amazon::S3->new(
    {
        aws_access_key_id     => $aws_access_key_id,
        aws_secret_access_key => $aws_secret_access_key,
        host                  => '127.0.0.1:9000',
        secure                => 0,  # Set to 1 if using https
    }
);

my $client = Net::Amazon::S3::Client->new( s3 => $s3 );
# my $bucket = $client->bucket( name => 'chum' );
# my $object = $bucket->object(
#     key          => 'test key',
#     content_type => 'text/plain',
# );
# $object->put_filename('miniotest.pl');

# # Open the file to be uploaded
# my $file_path = 'miniotest.pl';
# my $file = IO::File->new($file_path, "r") or die "Cannot open file: $file_path";

# # Upload the file
# $bucket->add_key( 'miniotest', $file, { content_type => 'text/plain' } );

# print "File uploaded successfully.\n";


# my $vendor = Net::Amazon::S3::Vendor::Generic->new (
#         host                 => '127.0.0.1',
#         use_https            => 0,
#         use_virtual_host     => 0,
#         authorization_method => 'Net::Amazon::S3::Signature::V2',
#         default_region       => 'docker'
# );

# my $s3 = Net::Amazon::S3->new (
#     vendor  => $vendor,
#     authorization_context => Net::Amazon::S3::Authorization::Basic->new (
#         aws_access_key_id       => $aws_access_key_id,
#         aws_secret_access_key   => $aws_secret_access_key,
#     ),
#     retry => 1,
# );
# # or use an IAM role.
# # my $s3 = Net::Amazon::S3->new (
# #   authorization_context => Net::Amazon::S3::Authorization::IAM->new (
# #     aws_access_key_id     => $aws_access_key_id,
# #     aws_secret_access_key => $aws_secret_access_key,
# #   ),
# #   retry => 1,
# # );
# # a bucket is a globally-unique directory
# # list all buckets that i own
# my $response = $s3->buckets;
# foreach my $bucket ( @{ $response->{buckets} } ) {
#     print "You have a bucket: " . $bucket->bucket . "\n";
# }


# # # create a new bucket
# # my $bucketname = 'acmes_photo_backups';
# # my $bucket = $s3->add_bucket( { bucket => $bucketname } )
# #     or die $s3->err . ": " . $s3->errstr;
# # # or use an existing bucket
# # $bucket = $s3->bucket($bucketname);
# # # store a file in the bucket
# # $bucket->add_key_filename( '1.JPG', 'DSC06256.JPG',
# #     { content_type => 'image/jpeg', },
# # ) or die $s3->err . ": " . $s3->errstr;
# # # store a value in the bucket
# # $bucket->add_key( 'reminder.txt', 'this is where my photos are backed up' )
# #     or die $s3->err . ": " . $s3->errstr;
# # # list files in the bucket
# # $response = $bucket->list_all
# #     or die $s3->err . ": " . $s3->errstr;
# # foreach my $key ( @{ $response->{keys} } ) {
# #     my $key_name = $key->{key};
# #     my $key_size = $key->{size};
# #     print "Bucket contains key '$key_name' of size $key_size\n";
# # }
# # # fetch file from the bucket
# # $response = $bucket->get_key_filename( '1.JPG', 'GET', 'backup.jpg' )
# #     or die $s3->err . ": " . $s3->errstr;
# # # fetch value from the bucket
# # $response = $bucket->get_key('reminder.txt')
# #     or die $s3->err . ": " . $s3->errstr;
# # print "reminder.txt:\n";
# # print "  content length: " . $response->{content_length} . "\n";
# # print "    content type: " . $response->{content_type} . "\n";
# # print "            etag: " . $response->{content_type} . "\n";
# # print "         content: " . $response->{value} . "\n";
# # # delete keys
# # $bucket->delete_key('reminder.txt') or die $s3->err . ": " . $s3->errstr;
# # $bucket->delete_key('1.JPG')        or die $s3->err . ": " . $s3->errstr;
# # # and finally delete the bucket
# # $bucket->delete_bucket or die $s3->err . ": " . $s3->errstr;