import _ from 'lodash/join'

function component() {
  const element = document.createElement('div')

  // Lodash, currently included via a script, is required for this line to work
  element.innerHTML = _(['Hello', 'webpack'], ' ')

  return element
}

document.body.appendChild(component())
