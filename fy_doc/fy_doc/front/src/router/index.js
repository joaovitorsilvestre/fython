import Vue from 'vue'
import VueRouter from 'vue-router'
import Home from '../views/Home.vue'
import docs from '../../public/docs'
import { topicUrlLink, pageUrlLink } from '../utils'

Vue.use(VueRouter)

function formatPages (topic, page) {
  return {
    name: page.ref,
    path: pageUrlLink(topic, page),
    children: page.pages.map(page => formatPages(topic, page))
  }
}

const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home,
    children: docs.topics.map((topic) => {
      return {
        name: topic.ref,
        path: topicUrlLink(topic),
        children: topic.pages.map(page => formatPages(topic, page))
      }
    })
  }
]

console.log(routes)

const router = new VueRouter({
  base: process.env.BASE_URL,
  routes
})

export default router
