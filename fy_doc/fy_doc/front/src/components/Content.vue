<template lang="pug">
  .content-wrapper
    span(v-html="compiledMarkdown")

    RightBar.right-bar
</template>

<script>
import { getDocs } from '../utils'
import marked from 'marked'
import RightBar from '../components/RightBar'

const docs = getDocs()

export default {
  computed: {
    compiledMarkdown () {
      const doc = docs.find(i => i.name.join('/') === this.$route.name)

      let lines = doc.text.split('\n')

      lines = lines.map(line => {
        if (line.slice(0, 4) === '    ') {
          return '```js\n' + line + '\n```'
        } else {
          return line
        }
      })

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
