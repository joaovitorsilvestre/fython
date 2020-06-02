import Vue from 'vue'
import VueRouter from 'vue-router'
import Home from '../views/Home.vue'
import { getDocs } from '../utils'

const docs = getDocs()

Vue.use(VueRouter)

const routes = [
  ...docs.map(topic => {
    return {
      path: '/' + topic.name.map(encodeURIComponent).join('/'),
      name: topic.name.join('/'),
      component: Home
    }
  }),
  { path: '*', redirect: `/${docs[0].name.join('/')}` }
]

const router = new VueRouter({
  base: process.env.BASE_URL,
  routes
})

export default router
