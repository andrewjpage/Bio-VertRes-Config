#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Temp;
use File::Slurper qw[write_text read_text];
BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::VertRes::Config::Recipes::EukaryotesMappingUsingSmalt');
}

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

ok(
    (
        my $obj = Bio::VertRes::Config::Recipes::EukaryotesMappingUsingSmalt->new(
            database    => 'my_database',
            config_base => $destination_directory,
            database_connect_file => 't/data/database_connection_details',
            limits      => { project => ['ABC study( EFG )'] },
            reference_lookup_file => 't/data/refs.index',
            reference             => 'ABC'
        )
    ),
    'initalise creating files'
);
ok( ( $obj->create ), 'Create all the config files and toplevel files' );

# Are all the nessisary top level files there?
ok( -e $destination_directory . '/my_database/my_database.ilm.studies' , 'study names file exists');
ok( -e $destination_directory . '/my_database/my_database_import_cram_pipeline.conf', 'import toplevel file');
ok( -e $destination_directory . '/my_database/my_database_mapping_pipeline.conf', 'mapping toplevel file');


# Individual config files
ok((-e "$destination_directory/my_database/import_cram/import_cram_global.conf"), 'import config file exists');
ok((-e "$destination_directory/my_database/mapping/mapping_ABC_study_EFG_ABC_smalt.conf"), 'mapping config file exists' );


my $text = read_text( "$destination_directory/my_database/mapping/mapping_ABC_study_EFG_ABC_smalt.conf" );
my $input_config_file = eval($text);
$input_config_file->{prefix} = '_checked_elsewhere_';
is_deeply($input_config_file,{
  'db' => {
            'database' => 'my_database',
            'password' => 'some_password',
            'user' => 'some_user',
            'port' => 1234,
            'host' => 'some_hostname'
          },
  'data' => {
              'mark_duplicates' => 1,
              'do_recalibration' => 0,
              'db' => {
                        'database' => 'my_database',
                        'password' => 'some_password',
                        'user' => 'some_user',
                        'port' => 1234,
                        'host' => 'some_hostname'
                      },
              'get_genome_coverage' => 1,
              'dont_wait' => 0,
              'assembly_name' => 'ABC',
              'exit_on_errors' => 0,
              'add_index' => 1,
              'reference' => '/path/to/ABC.fa',
              'do_cleanup' => 1,
              'ignore_mapped_status' => 1,
              'mapper_index_suffix' => 'k13s2',
              'additional_mapper_params' => '-r 0 -x -y 0.8',
              'mapper_index_params' => '-k 13 -s 2',
              'slx_mapper' => 'smalt',
              'slx_mapper_exe' => '/software/pathogen/external/apps/usr/local/smalt-0.7.4/smalt_x86_64'
            },
  'limits' => {
                'project' => [
                               'ABC\ study\(\ EFG\ \)'
                             ]
              },
  'vrtrack_processed_flags' => {
                                 'qc' => 1,
                                 'import' => 1
                               },
  'log' => '/nfs/pathnfs05/log/my_database/mapping_ABC_study_EFG_ABC_smalt.log',
  'root' => '/lustre/scratch118/infgen/pathogen/pathpipe/my_database/seq-pipelines',
  'prefix' => '_checked_elsewhere_',
  'dont_use_get_lanes' => 1,
  'module' => 'VertRes::Pipelines::Mapping',
  'umask' => 23,
  'octal_permissions' => 488,
  'unix_group' => 'pathogen',
  'limit' => 40,
},'Mapping Config file as expected');


done_testing();
