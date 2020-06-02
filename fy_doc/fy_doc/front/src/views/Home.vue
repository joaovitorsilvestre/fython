<template lang="pug">
  .wrapper
    .header
    LeftBar.left-bar
    Content.content

</template>

<script>
import LeftBar from '../components/LeftBar/LeftBar'
import Content from '../components/Content'

export default {
  name: 'HelloWorld',
  props: {
    msg: String
  },
  components: { LeftBar, Content }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped lang="scss">
.wrapper {
  display: grid;
  width: 100%;
  height: 100%;
  grid-template-columns: 1fr 4.5fr;
  grid-template-rows: 50px auto;

  .header {
    grid-row: 1;
    grid-column: 1/4;
    background-color: var(--header-blue);
    box-shadow: 0px 1px 4px rgba(0, 0, 0, 0.25);
  }

  .left-bar {
    grid-row: 2;
    grid-column: 1;
  }
  .content {
    grid-row: 2;
    grid-column: 2/4;
  }
}
</style>
