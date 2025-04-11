/**
 * WindrunnerRotations - Shadow Portal Effect
 * Author: VortexQ8
 * 
 * Creates a 3D shadow portal effect that simulates a dark void opening to reveal Sylvanas' realm
 * This effect combines distortion, particles, and shadow magic
 */

class ShadowPortalEffect {
  constructor(containerID) {
    this.container = document.getElementById(containerID);
    if (!this.container) return;
    
    this.width = this.container.offsetWidth;
    this.height = this.container.offsetHeight;
    
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
    
    this.camera.position.z = 30;
    
    // Track time and mouse
    this.clock = new THREE.Clock();
    this.mouse = new THREE.Vector2();
    this.targetMouse = new THREE.Vector2();
    
    // Create portal elements
    this.setupPortal();
    this.setupShadowWisps();
    this.setupDistortionField();
    
    // Event listeners
    window.addEventListener('resize', this.onWindowResize.bind(this));
    document.addEventListener('mousemove', this.onMouseMove.bind(this));
    
    // Start animation
    this.animate();
  }
  
  setupPortal() {
    // Portal ring
    const ringGeometry = new THREE.RingGeometry(8, 10, 64);
    const ringMaterial = new THREE.ShaderMaterial({
      uniforms: {
        time: { value: 0 },
        color1: { value: new THREE.Color(0x9900ff) },
        color2: { value: new THREE.Color(0x00bfff) }
      },
      vertexShader: `
        varying vec2 vUv;
        void main() {
          vUv = uv;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      `,
      fragmentShader: `
        uniform float time;
        uniform vec3 color1;
        uniform vec3 color2;
        varying vec2 vUv;
        
        void main() {
          float angle = atan(vUv.y - 0.5, vUv.x - 0.5);
          float normAngle = (angle + 3.14159) / (2.0 * 3.14159);
          float dist = distance(vUv, vec2(0.5));
          
          // Animated color flow
          float flow = fract(normAngle + time * 0.1);
          vec3 color = mix(color1, color2, flow);
          
          // Edge glow
          float edgeGlow = smoothstep(0.45, 0.5, dist) * (1.0 - smoothstep(0.5, 0.55, dist));
          edgeGlow = edgeGlow * (0.5 + 0.5 * sin(time * 2.0 + normAngle * 20.0));
          
          gl_FragColor = vec4(color, edgeGlow * 0.8);
        }
      `,
      transparent: true,
      side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    });
    
    this.portalRing = new THREE.Mesh(ringGeometry, ringMaterial);
    this.scene.add(this.portalRing);
    
    // Portal interior - dark void
    const voidGeometry = new THREE.CircleGeometry(8, 64);
    const voidMaterial = new THREE.ShaderMaterial({
      uniforms: {
        time: { value: 0 },
        resolution: { value: new THREE.Vector2(this.width, this.height) }
      },
      vertexShader: `
        varying vec2 vUv;
        void main() {
          vUv = uv;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      `,
      fragmentShader: `
        uniform float time;
        uniform vec2 resolution;
        varying vec2 vUv;
        
        // Noise functions from https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
        float rand(vec2 n) { 
          return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
        }
        
        float noise(vec2 p) {
          vec2 ip = floor(p);
          vec2 u = fract(p);
          u = u*u*(3.0-2.0*u);
          
          float res = mix(
            mix(rand(ip), rand(ip+vec2(1.0,0.0)), u.x),
            mix(rand(ip+vec2(0.0,1.0)), rand(ip+vec2(1.0,1.0)), u.x), u.y);
          return res*res;
        }
        
        void main() {
          // Center coordinates
          vec2 center = vec2(0.5);
          float dist = distance(vUv, center);
          
          // Swirling void effect
          float angle = atan(vUv.y - 0.5, vUv.x - 0.5);
          float swirl = sin(angle * 5.0 + time) * 0.1;
          
          // Noise for texture
          float noiseVal = noise(vUv * 10.0 + time * 0.2);
          float darkNoise = noise(vUv * 5.0 - time * 0.1);
          
          // Glowing edges
          float edge = smoothstep(0.35, 0.5, dist);
          float innerGlow = (1.0 - dist * 2.0) * 0.5;
          
          // Purple and blue mix
          vec3 purpleColor = vec3(0.6, 0.0, 0.8) * (noiseVal * 0.4 + 0.2);
          vec3 blueColor = vec3(0.0, 0.4, 0.8) * (darkNoise * 0.4 + 0.2);
          vec3 darkColor = vec3(0.05, 0.02, 0.1) * (1.0 - edge);
          
          // Final color
          vec3 color = mix(
            mix(darkColor, purpleColor, swirl + 0.5),
            blueColor,
            edge
          );
          
          // Add some stars/sparkles in the void
          if (noiseVal > 0.95 && dist < 0.3) {
            color += vec3(0.8, 0.8, 1.0) * (noiseVal - 0.95) * 20.0;
          }
          
          gl_FragColor = vec4(color, 0.9 - edge * 0.5);
        }
      `,
      transparent: true,
      side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    });
    
    this.portalVoid = new THREE.Mesh(voidGeometry, voidMaterial);
    this.portalVoid.position.z = -0.1;
    this.scene.add(this.portalVoid);
    
    // Add glow around portal
    const glowGeometry = new THREE.CircleGeometry(15, 64);
    const glowMaterial = new THREE.ShaderMaterial({
      uniforms: {
        time: { value: 0 }
      },
      vertexShader: `
        varying vec2 vUv;
        void main() {
          vUv = uv;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      `,
      fragmentShader: `
        uniform float time;
        varying vec2 vUv;
        
        void main() {
          vec2 center = vec2(0.5);
          float dist = distance(vUv, center);
          
          // Radial gradient for the glow
          float alpha = smoothstep(0.0, 1.0, 1.0 - dist);
          alpha = pow(alpha, 3.0) * 0.15;
          
          // Pulsing effect
          alpha *= 0.7 + 0.3 * sin(time);
          
          // Purple-blue gradient
          vec3 color = mix(
            vec3(0.6, 0.0, 1.0),
            vec3(0.0, 0.7, 1.0),
            sin(dist * 10.0 + time * 0.5) * 0.5 + 0.5
          );
          
          gl_FragColor = vec4(color, alpha);
        }
      `,
      transparent: true,
      side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    });
    
    this.portalGlow = new THREE.Mesh(glowGeometry, glowMaterial);
    this.portalGlow.position.z = -0.2;
    this.scene.add(this.portalGlow);
  }
  
  setupShadowWisps() {
    // Create shadow wisps emanating from the portal
    this.wisps = [];
    const wispCount = 20;
    
    for (let i = 0; i < wispCount; i++) {
      const size = Math.random() * 2 + 1;
      
      const geometry = new THREE.PlaneGeometry(size, size * 2);
      
      // Use gradient texture for wisp
      const canvas = document.createElement('canvas');
      canvas.width = 64;
      canvas.height = 128;
      const ctx = canvas.getContext('2d');
      
      const gradient = ctx.createLinearGradient(32, 0, 32, 128);
      
      if (Math.random() > 0.5) {
        // Purple wisp
        gradient.addColorStop(0, 'rgba(153, 0, 255, 0)');
        gradient.addColorStop(0.4, 'rgba(153, 0, 255, 0.3)');
        gradient.addColorStop(0.6, 'rgba(153, 0, 255, 0.3)');
        gradient.addColorStop(1, 'rgba(153, 0, 255, 0)');
      } else {
        // Blue wisp
        gradient.addColorStop(0, 'rgba(0, 191, 255, 0)');
        gradient.addColorStop(0.4, 'rgba(0, 191, 255, 0.3)');
        gradient.addColorStop(0.6, 'rgba(0, 191, 255, 0.3)');
        gradient.addColorStop(1, 'rgba(0, 191, 255, 0)');
      }
      
      ctx.fillStyle = gradient;
      ctx.fillRect(0, 0, 64, 128);
      
      const texture = new THREE.CanvasTexture(canvas);
      
      const material = new THREE.MeshBasicMaterial({
        map: texture,
        transparent: true,
        side: THREE.DoubleSide,
        blending: THREE.AdditiveBlending,
        depthWrite: false
      });
      
      const wisp = new THREE.Mesh(geometry, material);
      
      // Position within or around the portal
      const angle = Math.random() * Math.PI * 2;
      const radius = Math.random() * 10;
      
      wisp.position.set(
        Math.cos(angle) * radius,
        Math.sin(angle) * radius,
        Math.random() * 5 - 2.5
      );
      
      // Random rotation
      wisp.rotation.z = Math.random() * Math.PI;
      
      this.scene.add(wisp);
      
      // Track with animation properties
      this.wisps.push({
        mesh: wisp,
        initialPos: wisp.position.clone(),
        angle: angle,
        radius: radius,
        speed: Math.random() * 0.02 + 0.01,
        rotateSpeed: (Math.random() - 0.5) * 0.02,
        pulseSpeed: Math.random() * 0.03 + 0.01,
        wispSize: size
      });
    }
  }
  
  setupDistortionField() {
    // Add distortion field around the portal
    const fieldGeometry = new THREE.CircleGeometry(20, 64);
    const fieldMaterial = new THREE.ShaderMaterial({
      uniforms: {
        time: { value: 0 }
      },
      vertexShader: `
        varying vec2 vUv;
        
        void main() {
          vUv = uv;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      `,
      fragmentShader: `
        uniform float time;
        varying vec2 vUv;
        
        float noise(vec2 p) {
          vec2 ip = floor(p);
          vec2 u = fract(p);
          u = u*u*(3.0-2.0*u);
          
          float res = mix(
            mix(sin(dot(ip, vec2(12.9898, 78.233))), 
                sin(dot(ip + vec2(1.0, 0.0), vec2(12.9898, 78.233))), u.x),
            mix(sin(dot(ip + vec2(0.0, 1.0), vec2(12.9898, 78.233))), 
                sin(dot(ip + vec2(1.0, 1.0), vec2(12.9898, 78.233))), u.x), 
            u.y);
          return 0.5 + 0.5 * res;
        }
        
        void main() {
          vec2 center = vec2(0.5);
          float dist = distance(vUv, center);
          
          // Distortion field
          float distortion = noise(vUv * 5.0 + time * 0.2);
          
          // Ripple effect
          float ripple = sin(dist * 40.0 - time * 2.0) * 0.5 + 0.5;
          ripple *= smoothstep(0.5, 0.8, dist) * (1.0 - smoothstep(0.8, 1.0, dist));
          
          // Opacity based on distance from center
          float alpha = smoothstep(0.4, 0.5, dist) * (1.0 - smoothstep(0.8, 1.0, dist));
          alpha *= 0.15 * (distortion * 0.5 + ripple * 0.5);
          
          // Color based on distortion
          vec3 color = mix(
            vec3(0.6, 0.0, 1.0), 
            vec3(0.0, 0.7, 1.0),
            distortion
          );
          
          gl_FragColor = vec4(color, alpha);
        }
      `,
      transparent: true,
      side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    });
    
    this.distortionField = new THREE.Mesh(fieldGeometry, fieldMaterial);
    this.distortionField.position.z = -0.3;
    this.scene.add(this.distortionField);
  }
  
  onMouseMove(event) {
    // Update mouse position for portal interaction
    this.targetMouse.x = (event.clientX / window.innerWidth) * 2 - 1;
    this.targetMouse.y = -(event.clientY / window.innerHeight) * 2 + 1;
  }
  
  onWindowResize() {
    this.width = this.container.offsetWidth;
    this.height = this.container.offsetHeight;
    
    this.camera.aspect = this.width / this.height;
    this.camera.updateProjectionMatrix();
    
    this.renderer.setSize(this.width, this.height);
    
    // Update shader uniforms
    if (this.portalVoid && this.portalVoid.material.uniforms) {
      this.portalVoid.material.uniforms.resolution.value.set(this.width, this.height);
    }
  }
  
  animate() {
    requestAnimationFrame(this.animate.bind(this));
    
    const time = this.clock.getElapsedTime();
    
    // Smooth mouse movement
    this.mouse.x += (this.targetMouse.x - this.mouse.x) * 0.05;
    this.mouse.y += (this.targetMouse.y - this.mouse.y) * 0.05;
    
    // Animate portal elements
    if (this.portalRing && this.portalRing.material.uniforms) {
      this.portalRing.material.uniforms.time.value = time;
      
      // Subtle movement based on mouse
      this.portalRing.rotation.x = this.mouse.y * 0.2;
      this.portalRing.rotation.y = this.mouse.x * 0.2;
    }
    
    if (this.portalVoid && this.portalVoid.material.uniforms) {
      this.portalVoid.material.uniforms.time.value = time;
      
      // Match rotation with ring
      this.portalVoid.rotation.x = this.portalRing.rotation.x;
      this.portalVoid.rotation.y = this.portalRing.rotation.y;
    }
    
    if (this.portalGlow && this.portalGlow.material.uniforms) {
      this.portalGlow.material.uniforms.time.value = time;
      
      // Match rotation with ring
      this.portalGlow.rotation.x = this.portalRing.rotation.x;
      this.portalGlow.rotation.y = this.portalRing.rotation.y;
    }
    
    if (this.distortionField && this.distortionField.material.uniforms) {
      this.distortionField.material.uniforms.time.value = time;
      
      // Match rotation with ring
      this.distortionField.rotation.x = this.portalRing.rotation.x;
      this.distortionField.rotation.y = this.portalRing.rotation.y;
    }
    
    // Animate wisps
    this.wisps.forEach(wisp => {
      // Floating motion
      wisp.angle += wisp.speed;
      
      const newX = Math.cos(wisp.angle) * wisp.radius;
      const newY = Math.sin(wisp.angle) * wisp.radius;
      
      wisp.mesh.position.x = wisp.initialPos.x + newX * 0.2;
      wisp.mesh.position.y = wisp.initialPos.y + newY * 0.2;
      
      // Slow rotation
      wisp.mesh.rotation.z += wisp.rotateSpeed;
      
      // Pulsing opacity
      wisp.mesh.material.opacity = 0.3 + Math.sin(time * wisp.pulseSpeed) * 0.2;
      
      // Scale pulsing
      const scale = wisp.wispSize * (0.8 + Math.sin(time * wisp.pulseSpeed * 2) * 0.2);
      wisp.mesh.scale.set(scale, scale, 1);
    });
    
    this.renderer.render(this.scene, this.camera);
  }
}

// Initialize the shadow portal effect when the window loads
window.addEventListener('load', () => {
  // If a container element with id 'shadow-portal' exists, create the effect
  if (document.getElementById('shadow-portal')) {
    window.shadowPortalEffect = new ShadowPortalEffect('shadow-portal');
  }
});