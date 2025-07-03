import * as THREE from 'three'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'
import GUI from 'lil-gui'

import vertexShader from "./vertex.glsl"
import fragmentShader from "./fragment.glsl"
import birdVertexShader from "./bird-vertex.glsl"
import birdFragmentShader from "./bird-fragment.glsl"

/**
 * Base
 */
// Debug
const gui = new GUI({ width: 340 })
const debugObject = {
    color: '#000000',
    topColor: '#fea37c',
    fogColor: '#b2a4a4',
}

// Canvas
const canvas = document.querySelector('canvas.webgl')

// Scene
const scene = new THREE.Scene()

/**
 * Water
 */
// Geometry
const waterGeometry = new THREE.PlaneGeometry(8, 8, 1024, 1024)
const textureLoader = new THREE.TextureLoader()
// Material
const waterMaterial = new THREE.ShaderMaterial({
    vertexShader,
    fragmentShader,
    uniforms: {
        uColor: {value: new THREE.Color(debugObject.color) },
        uTopColor: {value: new THREE.Color(debugObject.topColor) },
        uFogColor: {value: new THREE.Color(debugObject.fogColor) },
        uCameraPosition: { value: new THREE.Vector3() },
        uFogMaxDistance: {value: 7.0},
        uSeed: {value: 12345.0},
        uTime: {value: 0},
        uBlinn: {value: true},
        uShininess: {value: 4.0},
        texture1: { type: "t", value: textureLoader.load( "texture.jpg" ) }
    }
})
gui.addColor(debugObject, 'color').onChange(() => { waterMaterial.uniforms.uColor.value.set(debugObject.color) })
gui.addColor(debugObject, 'topColor').onChange(() => { waterMaterial.uniforms.uTopColor.value.set(debugObject.topColor) })
gui.addColor(debugObject, 'fogColor').onChange(() => { waterMaterial.uniforms.uFogColor.value.set(debugObject.fogColor) })
gui.add(waterMaterial.uniforms.uFogMaxDistance, "value").min(0).max(20).step(0.0001).name("uFogMaxDistance")
gui.add(waterMaterial.uniforms.uSeed, "value").min(1).max(12345).step(1).name("uSeed")
gui.add(waterMaterial.uniforms.uBlinn, "value").name("uBlinn")
gui.add(waterMaterial.uniforms.uShininess, "value").min(0.001).max(16).step(0.0001).name("uShininess")

// Mesh
const water = new THREE.Mesh(waterGeometry, waterMaterial)
water.rotation.x = - Math.PI * 0.5
scene.add(water)

const birdGeometry = new THREE.PlaneGeometry(0.01, 0.01, 10, 10)
const birdMaterial = new THREE.ShaderMaterial({
    vertexShader: birdVertexShader,
    fragmentShader: birdFragmentShader,
    side: THREE.DoubleSide,
    transparent: true,
    alphaTest: 0.1,
    uniforms: {
        uTime: { value: 0 },
        texture1: { type: "t", value: textureLoader.load( "bird.png" ) }
    }
})
const birds = []
const birdsCount = 20
for(let i = 0; i < birdsCount; i++){
    const bird = new THREE.Mesh(birdGeometry, birdMaterial)
    bird.startPosition = new THREE.Vector3().random().divide(new THREE.Vector3(10.0, 40.0, 10.0)).multiplyScalar(4)
    bird.position.y = bird.startPosition.y + 0.5
    bird.rotation.x = - Math.PI * 0.5
    scene.add(bird)
    birds.push(bird)
}

/**
 * Sizes
 */
const sizes = {
    width: window.innerWidth,
    height: window.innerHeight
}

window.addEventListener('resize', () =>
{
    // Update sizes
    sizes.width = window.innerWidth
    sizes.height = window.innerHeight

    // Update camera
    camera.aspect = sizes.width / sizes.height
    camera.updateProjectionMatrix()

    // Update renderer
    renderer.setSize(sizes.width, sizes.height)
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
})

/**
 * Camera
 */
// Base camera
const camera = new THREE.PerspectiveCamera(75, sizes.width / sizes.height, 0.1, 100)
camera.position.set(1, 1, 1)
scene.add(camera)

// Controls
const controls = new OrbitControls(camera, canvas)
controls.enableDamping = true

/**
 * Renderer
 */
const renderer = new THREE.WebGLRenderer({
    canvas: canvas
})
renderer.setSize(sizes.width, sizes.height)
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))

/**
 * Animate
 */
const clock = new THREE.Clock()
const birdSpeed = 1 / 20

const tick = () =>
{
    const elapsedTime = clock.getElapsedTime()
    waterMaterial.uniforms.uCameraPosition.value = camera.position
    waterMaterial.uniforms.uTime.value = elapsedTime
    scene.background = waterMaterial.uniforms.uFogColor.value

    birdMaterial.uniforms.uTime.value = elapsedTime

    birds.map(bird => {
        bird.position.x = Math.sin(elapsedTime * birdSpeed - Math.PI / 2) + bird.startPosition.x
        bird.position.z = Math.cos(elapsedTime * birdSpeed - Math.PI / 2) + bird.startPosition.z
        bird.rotation.z = elapsedTime * birdSpeed + Math.PI
    })

    // Update controls
    controls.update()

    // Render
    renderer.render(scene, camera)

    // Call tick again on the next frame
    window.requestAnimationFrame(tick)
}

tick()