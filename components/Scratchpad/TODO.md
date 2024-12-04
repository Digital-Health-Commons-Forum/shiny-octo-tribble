# PGW

1. Do #API1 
2. Make a worker connect and establish a connection
3. Make the bot deal with SQLite and Minio in its entry
4. Make templates for these
    * Python
    * Perl
    * Csharp
50. Profit

## API1

* TODO: Update the schema to deal with all the changes after these: 
* TODO: Front end calls backend for get, which is a hash that includes:
* NOTE: with no specified docid returns all. ?docid=1
* Make the following work:

    ```csharp
    ARRAY [
        STANDARD FORMAT: {
            '_NOTE'         =>  'Each hash section is for each file that has succesfully passed ingestion'
            'tags'          =>  'all tags related to title/resource',
            'doc_name'      =>  '...', # Order the items in the array by this case nsensitive
            'doc_id'        =>  'int',
            'date_created'  =>  'dd/mm/yy hh/mm/ss',
            'date_modified' =>  'dd/mm/yy hh/mm/ss',
            'description'   =>  '<100 characters> (future use)'
            'meta'          =>  {
                'video_codecs'  =>  ['codec1','codec2']
            }
         }
     }
 
 * TODO: Convert this to /media/get?docid=\d+
 * TODO: Create endpoint /media/get_asset?docid=\d
 * TODO: When /media/find is called with an element of [], forward request to get_all
 * TODO: Put acme comment handler post/put/delete/get 

