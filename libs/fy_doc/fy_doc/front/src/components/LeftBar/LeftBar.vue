<template lang="pug">
  .left-bar-wrapper
    ol
      li(
        v-for="(topic, index) in docs"
        :style="{'text-indent': (topic.name.length - 1) + 'em'}"
      )
        router-link(
          :key="index"
          :to="{name: topic.name.join('/')}"
        )
          | {{ topic.name[topic.name.length - 1] }}

</template>

<script>
import { getDocs } from '../../utils'

export default {
  data () {
    return { docs: getDocs() }
  }
}
</script>

<style scoped lang="scss">
.left-bar-wrapper {
  background-color: var(--light-blue);
  box-shadow: 1px 0px 4px rgba(0, 0, 0, 0.25);
  color: var(--light-blue-font);
  padding: 20px 15% 50px 20px;
  text-align: left;
  position: static;

  ol li {
    list-style-type: none;

    a {
      text-decoration: captalize;
      color: var(--light-blue-font);
      font-size: 18px;

      &.router-link-exact-active {
        color: var(--dark-blue-font);
      }
    }
  }
}
</style>
