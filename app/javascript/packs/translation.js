import {
  Elm
} from '../Translation'

document.addEventListener('DOMContentLoaded', () => {
  const node = document.getElementById("translation_props");
  const flags = JSON.parse(node.getAttribute("data-props"));

  const csrf = document.getElementsByName("csrf-token")[0];
  const csrfToken = csrf.getAttribute("content");
  flags['urls']['csrfToken'] = csrfToken;
  
  Elm.TranslationPage.init({
    node: node,
    flags: flags
  })
})
