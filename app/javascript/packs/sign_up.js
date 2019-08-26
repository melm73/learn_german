import {
  Elm
} from '../SignUpPage'

document.addEventListener('DOMContentLoaded', () => {
  const target = document.createElement('div')

  const props = document.getElementById("sign_up_props");
  const flags = JSON.parse(props.getAttribute("data-props"));

  document.body.appendChild(target)
  Elm.Main.init({
    node: target,
    flags: flags
  })
})
