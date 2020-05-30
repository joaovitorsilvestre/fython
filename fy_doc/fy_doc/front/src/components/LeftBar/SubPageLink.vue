<template functional lang="pug">
  span
    .subpage(v-for="page in props.parent.pages")
      router-link.page-link(:to="{name: encodeURIComponent(page.ref)}") {{ page.name }}

      SubPageLink(:parent="page" name="SubPageLink")

</template>
