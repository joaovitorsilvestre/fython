export function topicUrlLink (topic) {
  return `/topics/${encodeURIComponent(topic.ref)}`
}

export function pageUrlLink (topic, page) {
  const ref = page.ref.split('.').slice(1).map(encodeURIComponent).join('/')
  return `${topicUrlLink(topic)}/${ref}`
}

export function findInDocsByRef (docs, ref) {
  debugger
  function findPage (page) {
    if (page.ref === ref) {
      return page
    } else if (page.pages.length) {
      return page.pages.find(findPage)
    } else {
      console.log('opaa')
      throw new Error('Invalid ref')
    }
  }

  return docs.topics.find(findPage)
}
