<template lang="pug">
  .content-wrapper
    | {{ page.text }}
</template>

<script>
import docs from '../../public/docs.js'
import { findInDocsByRef } from '../utils'

export default {
  computed: {
    page () {
      return findInDocsByRef(docs, this.$route.name)
    }
  }
}
</script>

<style scoped lang="scss">
.content-wrapper {
}
</style>
