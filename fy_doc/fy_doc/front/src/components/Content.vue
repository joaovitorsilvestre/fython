<template lang="pug">
  .content-wrapper
    .content
      h1 {{ doc.name[doc.name.length - 1] }}

      span(v-html="moduleText")

      .function(v-for="(func, index) in functions" :key="index")
        .name {{ func.name }}
        span.docstring(v-html="func.docstring")

    RightBar.right-bar
</template>

<script>
import { getDocs } from '../utils'
import marked from 'marked'
import RightBar from '../components/RightBar'

const docs = getDocs()

export default {
  computed: {
    doc () {
      return docs.find(i => i.name.join('/') === this.$route.name)
    },
    moduleText () {
      return this.toMarkDown(this.doc.text)
    },
    functions () {
      return this.doc.functions
        .map(({ name, docstring }) => {
          return { name, docstring: this.toMarkDown(docstring) }
        })
    }
  },
  methods: {
    toMarkDown (text) {
      let inCodeBlock = false
      let newText = ''

      text
        .split('\n')
        .forEach((line, index) => {
          const idented = line.startsWith('    ')

          if (idented && !inCodeBlock) {
            inCodeBlock = true
            newText = newText + '```python\n'
          }

          newText = `${newText}${line}\n`

          if (!idented && inCodeBlock) {
            inCodeBlock = false
            newText = newText + '```\n'
          }
        })

      return marked(newText)
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

  .content {
    float: left;
    width: 50%;
    text-align: left;
    padding: 5ex 15ex 5ex 15ex;

    .function {
      .name {
        background-color: var(--light-blue);
        padding: 10px;
        border-radius: 3px;
      }
      .docstring {
        padding: 10px;
      }
    }
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
