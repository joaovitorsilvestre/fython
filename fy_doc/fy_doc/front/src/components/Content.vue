<template lang="pug">
  .content-wrapper
    h1 oii

</template>

<script>
import docs from '../../public/docs.js'
import { findInDocsByRef } from '../utils'

export default {
  computed: {
    rr () {
      return this.$route.name
    },
    content () {
      return findInDocsByRef(docs, this.$route.name)
    }
  }
}
</script>

<style scoped lang="scss">
.content-wrapper {
}
</style>
