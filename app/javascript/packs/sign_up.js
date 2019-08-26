import {
  Elm
} from '../SignUpPage'

document.addEventListener('DOMContentLoaded', () => {
  const target = document.createElement('div')

  const props = document.getElementById("sign_up_props");
  const flags = JSON.parse(props.getAttribute("data-props"));

  const csrf = document.getElementsByName("csrf-token")[0];
  const csrfToken = csrf.getAttribute("content");
  flags['urls']['csrfToken'] = csrfToken;

  document.body.appendChild(target)
  Elm.Main.init({
    node: target,
    flags: flags
  })
})
