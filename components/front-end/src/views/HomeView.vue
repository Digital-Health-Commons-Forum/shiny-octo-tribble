<script setup>
  import { ref } from 'vue';
  import { useRouter } from 'vue-router';

  const search = ref('');
  const router = useRouter();
  const headers = [
    {
      title: 'Name',
      key: 'doc_name',
    },
    {
      title: 'Tags',
      key: 'tags',
      value: item => `${item.tags.join(', ')}`
    },
    {
      title: 'Description',
      key: 'description',
      // Fix this so it can use %, not sure why it doesn't respect % widths
      maxWidth: '500px',
      minWidth: '100px',
      cellProps: {
        class: 'text-truncate',
      }
    },
    {
      title: 'Date Created',
      key: 'date_created',
    },
    {
      title: 'Date Updated',
      key: 'date_modified',
    },
  ];
  const fakeData = [
    {
      'tags':  ['tag1','tag2','tag3'],
      'doc_name':  'Document 1',
      'doc_id':  '1',
      'date_created':  '01/01/2024',
      'date_modified':  '02/02/2024',
      'description':  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
      'meta':  {
        'video_codecs':  ['codec1','codec2']
      }
    },
    {
      'tags':  ['tag4'],
      'doc_name':  'Document 2',
      'doc_id':  '2',
      'date_created':  '01/01/2024',
      'date_modified':  '02/02/2024',
      'description':  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
      'meta':  {
        'video_codecs':  ['codec1','codec2']
      }
    },
    {
      'tags':  ['tag1','tag5'],
      'doc_name':  'Document 3',
      'doc_id':  '3',
      'date_created':  '01/01/2024',
      'date_modified':  '02/02/2024',
      'description':  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
      'meta':  {
        'video_codecs':  ['codec1','codec2']
      }
    },
    {
      'tags':  ['tag13','tag5','tag7'],
      'doc_name':  'Document 4',
      'doc_id':  '4',
      'date_created':  '01/01/2024',
      'date_modified':  '02/02/2024',
      'description':  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
      'meta':  {
        'video_codecs':  ['codec1','codec2']
      }
    }
  ];

  const handleClick = (event, row) => {
    console.log(row.item.doc_id)
    router.push(`/document/${row.item.doc_id}`)
  }
</script>

<template>
  <v-container>
    <v-card>
      <v-card-title>
        All Documents
      </v-card-title>
      <v-text-field
        label="Search for names or tags"
        class="mx-3"
        v-model="search"
      ></v-text-field>
      <v-data-table
        class="px-3"
        :headers="headers"
        :hover="true"
        :items="fakeData"
        :items-length="fakeData.length"
        :hide-default-footer="true"
        :search="search"
        @click:row="handleClick"
      >
      </v-data-table>
    </v-card>
  </v-container>
</template>