<template lang="pug">
  .left-bar-wrapper
    .topic(v-for="topic in docs.topics")
      router-link.topic-link(:to="topicUrlLink(topic)") {{ topic.name }}
      .subpage(v-for="page in topic.pages")
        router-link.page-link(:to="pageUrlLink(topic, page)") {{ page.name }}

</template>

<script>
import docs from '../../public/docs.js'
import { topicUrlLink, pageUrlLink } from '../utils'

export default {
  data () {
    return { docs }
  },
  methods: {
    topicUrlLink, pageUrlLink
  }
}
</script>

<style scoped lang="scss">
.left-bar-wrapper {
  background-color: var(--light-blue);
  box-shadow: 1px 0px 4px rgba(0, 0, 0, 0.25);
  color: var(--light-blue-font);
  padding: 40px 15% 50px 15%;

  .topic {
    text-transform: capitalize;
    margin-bottom: 40px;

    .topic-link {
      cursor: pointer;
      text-align: left;
      font-size: 22px;
    }

    .subpage {
      padding-left: 14px;
      .page-link {
        font-size: 16px;
      }
    }
  }
}
</style>
