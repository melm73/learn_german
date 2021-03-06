import {
  Elm
} from '../SignUpPage'

document.addEventListener('DOMContentLoaded', () => {
  const node = document.getElementById("sign_up_props");
  const flags = JSON.parse(node.getAttribute("data-props"));

  const csrf = document.getElementsByName("csrf-token")[0];
  const csrfToken = csrf.getAttribute("content");
  flags['urls']['csrfToken'] = csrfToken;
  
  Elm.SignUpPage.init({
    node: node,
    flags: flags
  })
})
