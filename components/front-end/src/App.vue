<script setup>
  import { RouterView } from 'vue-router'
  import NavBar from './components/nav/NavBar.vue';
</script>

<template>
  <v-app id="dhcf">
    <NavBar/>
    <RouterView style="margin-top: 80px; margin-bottom: 20px;"/>
  </v-app>
</template>
