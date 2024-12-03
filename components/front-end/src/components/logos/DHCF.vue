<script setup>
import { defineProps } from 'vue';

defineProps({
  height: String,
  width: String,
})
</script>

<template>
  <img
    src="@/assets/images/dhcf.webp"
    :style="{ height: height ?? '100%', width: width ?? 'auto' }"
  />
</template>