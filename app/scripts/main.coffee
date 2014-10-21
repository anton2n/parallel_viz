require.config
  paths:
    'jquery': '../vendor/jquery/dist/jquery.min'
    'd3': '../vendor/d3/d3'
    'threejs': '../vendor/threejs/build/three'
  shim:
    'd3': exports: 'd3'
    "/vendor/FBOUtils.js": {
      deps: ["threejs"]
    }
    "/vendor/OrbitControls.js": {
      deps: ["threejs"]
    }

requirejs( ['d3', 'threejs', '/vendor/FBOUtils.js' , '/vendor/OrbitControls.js'], (d3, threejs) ->

  texSize = 64
  simulationShader = null
  fboParticles = null
  material2 = null
  controls = null
  renderer = null
  scene = null
  camera = null
  timer = 0

  init = () ->
    renderer = new THREE.WebGLRenderer()
    camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 1, 10000)
    camera.position.z = 2
    scene = new THREE.Scene()

    d3.json("/data/state1.json", (err, state1) ->
      d3.json("/data/state2.json", (err, state2) ->
        state = []
        window.state = state
        state.push state1
        state.push state2
        textures = []

        state.map (d,i) ->
          dataLength = state[i].nodes.length

          extent = {
            x: d3.extent( state[i].nodes , (d) -> d.x)
            y: d3.extent( state[i].nodes , (d) -> d.y)
          }

          scale = {
            x: d3.scale.linear().domain(extent.x).range([-0.5,0.5])
            y: d3.scale.linear().domain(extent.y).range([-0.5,0.5])
          }

          data = (new Float32Array(texSize*texSize*3))
          [0...data.length].forEach (i) -> data[i] = 0
          state[i].nodes.map (d,i) ->
            data[i*3] = scale.x(d.x)
            data[i*3+1] = scale.y(d.y)

          texture = new THREE.DataTexture(data, texSize, texSize, THREE.RGBFormat, THREE.FloatType)
          texture.minFilter = THREE.NearestFilter
          texture.magFilter = THREE.NearestFilter
          texture.needsUpdate = true
          textures.push texture

        rtTexturePos = new THREE.WebGLRenderTarget(texSize,texSize, {
          wrapS:THREE.RepeatWrapping
          wrapT:THREE.RepeatWrapping
          minFilter: THREE.NearestFilter
          magFilter: THREE.NearestFilter
          format: THREE.RGBFormat
          type:THREE.FloatType
          stencilBuffer: false
        })

        outPos = rtTexturePos.clone()

        simulationShader = new THREE.ShaderMaterial({

            uniforms: {
                start: { type: "t", value: textures[0] }
                end: { type: "t", value: textures[1] }
                timer: { type: "f", value: 0}
            }

            vertexShader: document.getElementById('fboVert').innerHTML,
            fragmentShader:  document.getElementById('fboFrag').innerHTML

        })

        fboParticles = new THREE.FBOUtils( texSize, renderer, simulationShader );
        fboParticles.renderToTexture(rtTexturePos, outPos);

        fboParticles.in = rtTexturePos;
        fboParticles.out = outPos;

        geometry2 = new THREE.Geometry();

        [0...texSize*texSize*3].forEach (i) ->
          vertex = new THREE.Vector3()
          vertex.x = ( i % texSize ) / texSize
          vertex.y = Math.floor( i / texSize ) / texSize
          geometry2.vertices.push( vertex )

        material2 = new THREE.ShaderMaterial {
            uniforms: {
                "map": { type: "t", value: rtTexturePos }
                "width": { type: "f", value: texSize }
                "height": { type: "f", value: texSize }
                "pointSize": { type: "f", value: 2 }
                "effector" : { type: "f", value: 0 }

            }
            vertexShader: document.getElementById('fboRenderVert').innerHTML
            fragmentShader: document.getElementById('fboRenderFrag').innerHTML
            depthTest: true
            transparent: true
            blending: THREE.AdditiveBlending
        }

        mesh2 = new THREE.PointCloud( geometry2, material2 )
        scene.add( mesh2 )

        if false
          geometry = new THREE.BoxGeometry(1,1,1)

          material = new THREE.MeshLambertMaterial({color: 0xCC0000})
          cube = new THREE.Mesh(geometry, material)
          scene.add(cube)

          pointLight = new THREE.PointLight(0xFFFFFF)

          pointLight.position.x = 10
          pointLight.position.y = 50
          pointLight.position.z = 130

          scene.add(pointLight)

        controls = new THREE.OrbitControls( camera, renderer.domElement )
        renderer.setSize(window.innerWidth, window.innerHeight)

        document.body.appendChild(renderer.domElement)
      )
    )

  animate = (t) ->
      requestAnimationFrame(animate);

      simulationShader.uniforms.timer.value = t

      tmp = fboParticles.in
      fboParticles.in = fboParticles.out
      fboParticles.out = tmp

      simulationShader.uniforms.start.value = fboParticles.in
      fboParticles.simulate(fboParticles.out)
      material2.uniforms.map.value = fboParticles.out
      # debugger

      controls.update()
      renderer.render( scene, camera )

  init()
  animate(new Date().getTime());

  # #basic render setup
  # viewAngle = 75
  # aspectRatio = window.innerWidth/window.innerHeight
  # nearClip = 0.1
  # farClip = 10000

  # scene = new THREE.Scene()
  # camera = new THREE.PerspectiveCamera(viewAngle, aspectRatio, nearClip, farClip)

  # renderer = new THREE.WebGLRenderer()
  # renderer.setSize(window.innerWidth, window.innerHeight)
  # document.body.appendChild(renderer.domElement)

  # geometry = new THREE.BoxGeometry(1,1,1)

  # material = new THREE.MeshLambertMaterial({color: 0xCC0000})
  # cube = new THREE.Mesh(geometry, material)
  # scene.add(cube)

  # pointLight = new THREE.PointLight(0xFFFFFF)

  # pointLight.position.x = 10
  # pointLight.position.y = 50
  # pointLight.position.z = 130

  # scene.add(pointLight)

  # camera.position.z = 5

  # render = () ->
  #   requestAnimationFrame(render)

  #   cube.rotation.x += 0.01
  #   cube.rotation.y += 0.01

  #   renderer.render(scene, camera)

  # render()
)