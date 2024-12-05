<script setup>
  import { RouterLink, RouterView } from 'vue-router'
  import NavBar from './components/nav/NavBar.vue';
</script>

<template>
  <v-app id="dhcf">
    <NavBar/>
    <RouterView style="margin-top: 150px; margin-left: 64px; margin-right: 64px;"/>
  </v-app>
</template>
