import {
  Elm
} from '../ReviewPage'

document.addEventListener('DOMContentLoaded', () => {

  const node = document.getElementById("review_page_props");
  const flags = JSON.parse(node.getAttribute("data-props"));

  const csrf = document.getElementsByName("csrf-token")[0];
  const csrfToken = csrf.getAttribute("content");
  flags['urls']['csrfToken'] = csrfToken;
  
  Elm.ReviewPage.init({
    node: node,
    flags: flags
  })
})
