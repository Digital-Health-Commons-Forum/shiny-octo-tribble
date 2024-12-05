<script setup>
  import IconDHCF from '../logos/DHCF.vue'
  import { useRouter } from 'vue-router';

  const router = useRouter();
</script>

<template>
  <v-app-bar>
    <v-app-bar-title>
      <router-link to="/">
        <IconDHCF :height="'40px'"/>
      </router-link>
    </v-app-bar-title>
  </v-app-bar>
</template>