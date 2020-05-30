<template lang="pug">
  .left-bar-wrapper
    .topic(v-for="topic in docs.topics")
      router-link.topic-link(:to="{name: docRefToRouteName(topic.ref)}") {{ topic.name }}
      SubPageLink(:parent="topic")
</template>

<script>
import docs from '../../../public/docs.js'
import { docRefToRouteName } from '../../utils'
import SubPageLink from './SubPageLink'

export default {
  data () {
    return { docs }
  },
  methods: {
    docRefToRouteName,
    goto (ref) {
      this.$router.push({ name: ref })
    }
  },
  components: { SubPageLink }
}
</script>

<style scoped lang="scss">
.left-bar-wrapper {
  background-color: var(--light-blue);
  box-shadow: 1px 0px 4px rgba(0, 0, 0, 0.25);
  color: var(--light-blue-font);
  padding: 40px 15% 50px 15%;
  text-align: left;

  a {
    text-decoration: none;
    color: var(--light-blue-font);
    font-size: 22px;

    &.router-link-exact-active {
      color: var(--dark-blue-font);
    }
  }

  .topic {
    text-transform: capitalize;
    margin-bottom: 40px;

    .subpage {
      padding-left: 14px;
      .page-link {
        font-size: 16px;
      }
    }
  }
}
</style>
