import {
  Elm
} from '../Menu'

document.addEventListener('DOMContentLoaded', () => {
  const node = document.getElementById("menu_props");
  const flags = JSON.parse(node.getAttribute("data-props"));

  const csrf = document.getElementsByName("csrf-token")[0];
  const csrfToken = csrf.getAttribute("content");
  flags['urls']['csrfToken'] = csrfToken;
  
  Elm.Menu.init({
    node: node,
    flags: flags
  })
})
