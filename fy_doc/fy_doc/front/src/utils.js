export function docRefToRouteName (ref) {
  return encodeURIComponent(ref)
}

export function findInDocsByRef (docs, ref) {
  let page = null

  function findPage (cPage) {
    if (cPage.ref === ref) {
      page = cPage
    } else {
      cPage.pages.forEach(findPage)
    }
  }

  docs.topics.forEach(findPage)

  return page
}
