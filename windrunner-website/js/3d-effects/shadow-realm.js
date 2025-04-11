/**
 * WindrunnerRotations - Shadow Realm Background Effect
 * Author: VortexQ8
 * 
 * Creates a dark, animated shadow realm background with fog, floating shapes,
 * and ethereal light effects inspired by Sylvanas' undead realm
 */

class ShadowRealmEffect {
  constructor(containerID) {
    this.container = document.getElementById(containerID);
    if (!this.container) return;
    
    this.width = this.container.offsetWidth;
    this.height = this.container.offsetHeight;
    this.mouseX = 0;
    this.mouseY = 0;
    this.targetMouseX = 0;
    this.targetMouseY = 0;
    
    // Scene setup
    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(60, this.width / this.height, 0.1, 1000);
    this.renderer = new THREE.WebGLRenderer({ 
      alpha: true,
      antialias: true
    });
    
    this.renderer.setSize(this.width, this.height);
    this.renderer.setClearColor(0x000000, 0);
    this.container.appendChild(this.renderer.domElement);
    
    this.camera.position.z = 50;
    
    // Track time for animations
    this.clock = new THREE.Clock();
    
    // Create shadow realm elements
    this.setupFog();
    this.setupFloatingElements();
    this.setupLightShafts();
    
    // Event listeners
    window.addEventListener('resize', this.onWindowResize.bind(this));
    document.addEventListener('mousemove', this.onMouseMove.bind(this));
    
    // Start animation
    this.animate();
  }
  
  setupFog() {
    // Create fog particles
    this.fogParticles = [];
    const fogCount = 100;
    
    // Shared geometry and material
    const fogGeometry = new THREE.PlaneGeometry(30, 30);
    
    // Create fog texture with canvas
    const canvas = document.createElement('canvas');
    canvas.width = 128;
    canvas.height = 128;
    const ctx = canvas.getContext('2d');
    
    // Create radial gradient
    const gradient = ctx.createRadialGradient(64, 64, 0, 64, 64, 64);
    gradient.addColorStop(0, 'rgba(100, 0, 150, 0.4)');
    gradient.addColorStop(0.5, 'rgba(70, 0, 100, 0.2)');
    gradient.addColorStop(1, 'rgba(40, 0, 60, 0)');
    
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, 128, 128);
    
    const fogTexture = new THREE.CanvasTexture(canvas);
    
    const fogMaterial = new THREE.MeshBasicMaterial({
      map: fogTexture,
      transparent: true,
      side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    });
    
    // Create multiple fog planes
    for (let i = 0; i < fogCount; i++) {
      const fog = new THREE.Mesh(fogGeometry, fogMaterial);
      
      // Random position in 3D space
      fog.position.set(
        (Math.random() - 0.5) * 100,
        (Math.random() - 0.5) * 100,
        (Math.random() - 0.5) * 50 - 10
      );
      
      // Random rotation
      fog.rotation.x = Math.random() * Math.PI;
      fog.rotation.y = Math.random() * Math.PI;
      
      // Random scale
      const scale = Math.random() * 2 + 0.5;
      fog.scale.set(scale, scale, 1);
      
      this.scene.add(fog);
      
      // Track with animation properties
      this.fogParticles.push({
        mesh: fog,
        rotateSpeed: (Math.random() - 0.5) * 0.01,
        floatSpeed: {
          x: (Math.random() - 0.5) * 0.05,
          y: (Math.random() - 0.5) * 0.05,
          z: (Math.random() - 0.5) * 0.02
        },
        originalScale: scale,
        pulseSpeed: Math.random() * 0.01 + 0.005
      });
    }
  }
  
  setupFloatingElements() {
    // Create floating dark shapes
    this.floatingElements = [];
    const elementCount = 15;
    
    // Define different shadow shapes
    const createShape = (type) => {
      let geometry;
      
      switch(type) {
        case 0: // Crystal shard
          geometry = new THREE.ConeGeometry(1, 4, 5);
          break;
        case 1: // Floating rock
          geometry = new THREE.DodecahedronGeometry(1.5, 0);
          break;
        case 2: // Skull-like shape
          geometry = new THREE.SphereGeometry(1.2, 8, 8);
          break;
        case 3: // Twisted fragment
          geometry = new THREE.TorusKnotGeometry(1, 0.4, 64, 8, 2, 3);
          break;
        default: // Dark orb
          geometry = new THREE.IcosahedronGeometry(1, 0);
      }
      
      return geometry;
    };
    
    // Create shader material for all elements
    const shadowMaterial = new THREE.ShaderMaterial({
      uniforms: {
        time: { value: 0 },
        color1: { value: new THREE.Color(0x1a0033) },
        color2: { value: new THREE.Color(0x330066) },
        glowColor: { value: new THREE.Color(0x9900ff) }
      },
      vertexShader: `
        varying vec2 vUv;
        varying vec3 vNormal;
        varying vec3 vPosition;
        
        void main() {
          vUv = uv;
          vNormal = normalize(normalMatrix * normal);
          vPosition = position;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      `,
      fragmentShader: `
        uniform float time;
        uniform vec3 color1;
        uniform vec3 color2;
        uniform vec3 glowColor;
        
        varying vec2 vUv;
        varying vec3 vNormal;
        varying vec3 vPosition;
        
        void main() {
          // Base shadow color
          vec3 color = mix(color1, color2, sin(vPosition.x + vPosition.y + time) * 0.5 + 0.5);
          
          // Edge glow
          float fresnel = pow(1.0 - max(0.0, dot(vNormal, vec3(0.0, 0.0, 1.0))), 3.0);
          vec3 finalColor = mix(color, glowColor, fresnel * 0.7);
          
          // Pulsing glow
          float pulse = sin(time * 0.5) * 0.5 + 0.5;
          finalColor = mix(finalColor, glowColor, fresnel * pulse * 0.3);
          
          gl_FragColor = vec4(finalColor, 0.9);
        }
      `,
      transparent: true,
      side: THREE.DoubleSide
    });
    
    // Create elements
    for (let i = 0; i < elementCount; i++) {
      const shapeType = Math.floor(Math.random() * 5);
      const geometry = createShape(shapeType);
      
      // Clone material to have independent time values
      const material = shadowMaterial.clone();
      
      const element = new THREE.Mesh(geometry, material);
      
      // Random position
      element.position.set(
        (Math.random() - 0.5) * 80,
        (Math.random() - 0.5) * 80,
        (Math.random() - 0.5) * 40 - 20
      );
      
      // Random rotation
      element.rotation.set(
        Math.random() * Math.PI * 2,
        Math.random() * Math.PI * 2,
        Math.random() * Math.PI * 2
      );
      
      // Random scale
      const scale = Math.random() * 3 + 1;
      element.scale.set(scale, scale, scale);
      
      this.scene.add(element);
      
      // Track with animation properties
      this.floatingElements.push({
        mesh: element,
        rotateSpeed: {
          x: (Math.random() - 0.5) * 0.01,
          y: (Math.random() - 0.5) * 0.01,
          z: (Math.random() - 0.5) * 0.01
        },
        floatSpeed: {
          x: (Math.random() - 0.5) * 0.03,
          y: (Math.random() - 0.5) * 0.03,
          z: (Math.random() - 0.5) * 0.01
        },
        originalPos: element.position.clone(),
        timeOffset: Math.random() * Math.PI * 2,
        material: material
      });
    }
  }
  
  setupLightShafts() {
    // Create ethereal light shafts
    this.lightShafts = [];
    const shaftCount = 6;
    
    // Create light shaft geometry
    const shaftGeometry = new THREE.CylinderGeometry(0, 5, 40, 8, 1, true);
    
    // Custom shader material for light shafts
    const shaftMaterial = new THREE.ShaderMaterial({
      uniforms: {
        time: { value: 0 },
        color: { value: new THREE.Color(0x7c0aff) }
      },
      vertexShader: `
        varying vec2 vUv;
        varying vec3 vPosition;
        
        void main() {
          vUv = uv;
          vPosition = position;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      `,
      fragmentShader: `
        uniform float time;
        uniform vec3 color;
        
        varying vec2 vUv;
        varying vec3 vPosition;
        
        void main() {
          // Gradient along the shaft
          float gradient = 1.0 - vUv.y;
          
          // Animated noise pattern
          float noise = sin((vUv.x * 10.0) + (vUv.y * 20.0) + time) * 0.5 + 0.5;
          noise *= sin((vUv.x * 5.0) - (vUv.y * 10.0) + time * 0.7) * 0.5 + 0.5;
          
          // Combine gradient and noise
          float alpha = gradient * 0.4 * noise;
          
          // Edge falloff
          float edge = (1.0 - abs(vUv.x - 0.5) * 2.0) * 0.5;
          alpha *= edge;
          
          // Color with slight variation
          vec3 finalColor = mix(color, color * 1.5, noise * 0.3);
          
          gl_FragColor = vec4(finalColor, alpha * 0.5);
        }
      `,
      transparent: true,
      side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    });
    
    // Create light shafts
    for (let i = 0; i < shaftCount; i++) {
      // Clone material to have independent time values
      const material = shaftMaterial.clone();
      
      // Randomize color slightly
      if (Math.random() > 0.5) {
        material.uniforms.color.value = new THREE.Color(0x00bfff);
      }
      
      const shaft = new THREE.Mesh(shaftGeometry, material);
      
      // Random position
      shaft.position.set(
        (Math.random() - 0.5) * 100,
        -30 + Math.random() * 20,
        (Math.random() - 0.5) * 40 - 30
      );
      
      // Random rotation around X axis to angle the shaft
      shaft.rotation.x = Math.PI / 2;
      shaft.rotation.z = Math.random() * Math.PI * 2;
      
      this.scene.add(shaft);
      
      // Track with animation properties
      this.lightShafts.push({
        mesh: shaft,
        floatSpeed: (Math.random() - 0.5) * 0.01,
        pulseSpeed: Math.random() * 0.01 + 0.005,
        rotateSpeed: (Math.random() - 0.5) * 0.002,
        material: material,
        timeOffset: Math.random() * Math.PI * 2
      });
    }
  }
  
  onMouseMove(event) {
    // Calculate mouse position for parallax effect
    this.targetMouseX = (event.clientX / window.innerWidth) * 2 - 1;
    this.targetMouseY = -(event.clientY / window.innerHeight) * 2 + 1;
  }
  
  onWindowResize() {
    this.width = this.container.offsetWidth;
    this.height = this.container.offsetHeight;
    
    this.camera.aspect = this.width / this.height;
    this.camera.updateProjectionMatrix();
    
    this.renderer.setSize(this.width, this.height);
  }
  
  animate() {
    requestAnimationFrame(this.animate.bind(this));
    
    const time = this.clock.getElapsedTime();
    
    // Smooth mouse movement
    this.mouseX += (this.targetMouseX - this.mouseX) * 0.05;
    this.mouseY += (this.targetMouseY - this.mouseY) * 0.05;
    
    // Camera movement based on mouse position
    this.camera.position.x = this.mouseX * 10;
    this.camera.position.y = this.mouseY * 5;
    this.camera.lookAt(0, 0, 0);
    
    // Animate fog
    this.fogParticles.forEach(fog => {
      // Slow rotation
      fog.mesh.rotation.x += fog.rotateSpeed;
      fog.mesh.rotation.z += fog.rotateSpeed * 0.7;
      
      // Drifting movement
      fog.mesh.position.x += fog.floatSpeed.x;
      fog.mesh.position.y += fog.floatSpeed.y;
      fog.mesh.position.z += fog.floatSpeed.z;
      
      // Wrap around edges of visible area
      if (fog.mesh.position.x > 60) fog.mesh.position.x = -60;
      if (fog.mesh.position.x < -60) fog.mesh.position.x = 60;
      if (fog.mesh.position.y > 60) fog.mesh.position.y = -60;
      if (fog.mesh.position.y < -60) fog.mesh.position.y = 60;
      
      // Pulsing scale
      const pulse = fog.originalScale * (0.8 + Math.sin(time * fog.pulseSpeed) * 0.2);
      fog.mesh.scale.set(pulse, pulse, 1);
    });
    
    // Animate floating elements
    this.floatingElements.forEach(element => {
      // Rotation
      element.mesh.rotation.x += element.rotateSpeed.x;
      element.mesh.rotation.y += element.rotateSpeed.y;
      element.mesh.rotation.z += element.rotateSpeed.z;
      
      // Floating motion using sine waves for smooth movement
      element.mesh.position.x = 
        element.originalPos.x + Math.sin(time * 0.5 + element.timeOffset) * 2;
      element.mesh.position.y = 
        element.originalPos.y + Math.cos(time * 0.3 + element.timeOffset) * 2;
      element.mesh.position.z = 
        element.originalPos.z + Math.sin(time * 0.7 + element.timeOffset) * 1;
      
      // Update shader time
      element.material.uniforms.time.value = time;
    });
    
    // Animate light shafts
    this.lightShafts.forEach(shaft => {
      // Floating motion
      shaft.mesh.rotation.y += shaft.rotateSpeed;
      
      // Pulsing opacity
      const pulseOpacity = 0.7 + Math.sin(time * shaft.pulseSpeed + shaft.timeOffset) * 0.3;
      shaft.mesh.material.opacity = pulseOpacity;
      
      // Update shader time
      shaft.material.uniforms.time.value = time;
    });
    
    this.renderer.render(this.scene, this.camera);
  }
}

// Initialize the shadow realm effect when the window loads
window.addEventListener('load', () => {
  // If a container element with id 'shadow-realm' exists, create the effect
  if (document.getElementById('shadow-realm')) {
    window.shadowRealmEffect = new ShadowRealmEffect('shadow-realm');
  }
});