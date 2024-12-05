<script setup>
  import { ref } from 'vue';
  import { useRouter } from 'vue-router';

  const router = useRouter();
  const fakeData = {
    'tags':  ['tag1','tag2','tag3'],
    'doc_name':  'Document 1',
    'doc_id':  '1',
    'date_created':  '01/01/2024',
    'date_modified':  '02/02/2024',
    'description':  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
    'meta':  {
      'video_codecs':  ['codec1','codec2']
    }
  };
  const fakeComments = [
    {
      user: {
        name: 'User1'
      },
      datetime: '11/11/2024 11:11:11',
      comment: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'
    },
    {
      user: {
        name: 'User2'
      },
      datetime: '11/11/2024 11:11:11',
      comment: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'
    },
    {
      user: {
        name: 'User2'
      },
      datetime: '11/11/2024 11:11:11',
      comment: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'
    }
  ]
</script>

<template>
  <div>
    <v-container>
      <v-row>
        <v-col>
          <v-sheet class="mb-3 pa-2" rounded>
            <router-link to="/">All Documents</router-link> > {{ fakeData.doc_name }}
          </v-sheet>
          <v-card class="mb-3">
            <v-card-title>
              {{ fakeData.doc_name }}
            </v-card-title>
            <v-card-subtitle>
              Tags: {{ fakeData.tags.join(', ') }}
            </v-card-subtitle>
            <v-card-text>
              {{ fakeData.description }}
            </v-card-text>
            <v-card-text class="text-center">
              Document Goes Here
            </v-card-text>
          </v-card>
          <v-card>
            <v-card-title>
              Comments
            </v-card-title>
            <v-card-actions class="d-flex flex-column w-100">
              <v-textarea
                label="Leave a comment"
                placeholder="Leave a comment"
                class="w-100"
              >
              </v-textarea>
            </v-card-actions>
            <div v-for="(comment, i) in fakeComments" :key="i">
              <v-card>
                <v-card-title>{{ comment.user.name }}</v-card-title>
                <v-card-subtitle>
                  {{ comment.datetime }}
                </v-card-subtitle>
                <v-card-text>
                  {{ comment.comment }}
                </v-card-text>
              </v-card>
            </div>
          </v-card>
        </v-col>
        <v-col cols="3">
          <v-card>
            <v-card-title>
              Similar Projects
            </v-card-title>
            <v-card-actions class="ml-2">
              <router-link to="/document/2">Document 2</router-link>
            </v-card-actions>
          </v-card>
        </v-col>
      </v-row>
    </v-container>
  </div>
</template>