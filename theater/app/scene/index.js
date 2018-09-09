const THREE = require('three')
require('imports-loader?THREE=three!three/examples/js/controls/OrbitControls')

const scene = new THREE.Scene({
  fog: new THREE.Fog(0x000000, 0.1, 1000),
})

const camera = new THREE.PerspectiveCamera(33, 1, 0.1, 100)
camera.position.set(0, 0, 4.5)
camera.lookAt(new THREE.Vector3(0, 0, 0))

let renderer
let controls

export function setRenderer({ canvas }) {
  renderer = new THREE.WebGLRenderer({
    alpha: true,
    antialias: true,
    canvas,
  })
  controls = new THREE.OrbitControls(camera, renderer.domElement)
}

export function onResize({ width, height }) {
  camera.aspect = width / height
  camera.updateProjectionMatrix()

  if (renderer) renderer.setSize(width, height)
}

let planet

export function setPlanet({ position, normal, index }) {
  if (planet) {
    scene.remove(planet)
    planet = null
  }

  const planetGeometry = new THREE.BufferGeometry()

  planetGeometry.setIndex(new THREE.BufferAttribute(new Uint32Array(index), 1))

  planetGeometry.addAttribute(
    'position',
    new THREE.BufferAttribute(new Float32Array(position), 3),
  )

  planetGeometry.addAttribute(
    'normal',
    new THREE.BufferAttribute(new Float32Array(normal), 3),
  )

  planetGeometry.addAttribute(
    'color',
    new THREE.BufferAttribute(new Float32Array(position.length), 3),
  )

  planet = new THREE.Mesh(
    planetGeometry,
    new THREE.MeshBasicMaterial({
      vertexColors: THREE.VertexColors,
    }),
  )

  scene.add(planet)
}

function isPentagon(fi, div) {
  if (fi < 2) return true
  else {
    const ll = fi - 2

    const x_lim = div * 2
    const y_lim = div

    const fs = Math.floor(ll / (x_lim * y_lim))
    const fx = Math.floor((ll - fs * x_lim * y_lim) / y_lim)
    const fy = ll - fs * x_lim * y_lim - fx * y_lim

    return fy === 0 && (fx + 1) % div === 0
  }
}

export function setPlanetFrame(divisions, frame) {
  let ci = 0
  if (planet)
    for (let fi = 0; fi < 10 * divisions * divisions + 2; fi += 1) {
      const sides = (isPentagon(fi, divisions) && 5) || 6
      for (let si = 0; si < sides; si += 1) {
        const cc = ci + si
        planet.geometry.attributes.color.array[cc * 3 + 0] = frame[fi][0] / 255
        planet.geometry.attributes.color.array[cc * 3 + 1] = frame[fi][1] / 255
        planet.geometry.attributes.color.array[cc * 3 + 2] = frame[fi][2] / 255
      }
      ci += sides
    }
  planet.geometry.attributes.color.needsUpdate = true
}

let playing = false

function onRender() {
  if (renderer && scene && camera) renderer.render(scene, camera)
}

function render() {
  onRender()
  if (playing) requestAnimationFrame(render)
}

export function play() {
  playing = true
  render()
}

export function pause() {
  playing = false
}
