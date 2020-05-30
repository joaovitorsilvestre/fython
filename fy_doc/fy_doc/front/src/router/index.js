import Vue from 'vue'
import VueRouter from 'vue-router'
import Home from '../views/Home.vue'
import docs from '../../public/docs'
import { docRefToRouteName } from '../utils'

Vue.use(VueRouter)

function formatPages (acc, value) {
  const path = value.ref.split('.').map(encodeURIComponent).join('/')
  return [
    ...acc,
    ...(value.pages.length > 0 ? value.pages.reduce(formatPages, []) : []),
    {
      name: docRefToRouteName(value.ref),
      path: `/${path}`,
      component: Home
    }
  ]
}

const routes = docs.topics.reduce(formatPages, [])

console.log(routes)

const router = new VueRouter({
  base: process.env.BASE_URL,
  routes
})

export default router
