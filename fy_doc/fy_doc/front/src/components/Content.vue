<template lang="pug">
  .content-wrapper
    span(v-html="compiledMarkdown")

    RightBar.right-bar
</template>

<script>
import docs from '../../public/docs.js'
import { findInDocsByRef } from '../utils'
import marked from 'marked'
import RightBar from '../components/RightBar'

export default {
  computed: {
    page () {
      return findInDocsByRef(docs, this.$route.name)
    },
    compiledMarkdown () {
      let lines = this.page.text.split('\n')

      lines = lines.map(line => {
        if (line.slice(0, 4) === '    ') {
          return '```js\n' + line + '\n```'
        } else {
          return line
        }
      })

      console.log('lines', lines)

      return marked(lines.join('\n'))
    }
  },
  components: { RightBar }
}
</script>

<style scoped lang="scss">
.content-wrapper {
  overflow-y: scroll;
  position: relative;
  margin: 10px 10px 10px 0;

  span {
    float: left;
    width: 50%;
    text-align: left;
    padding: 5ex 15ex 5ex 15ex;
  }

  .right-bar {
    right: 0px;
    z-index: -10;
    position: fixed;
    width: 20%;
    height: 100%;
  }
}
</style>
