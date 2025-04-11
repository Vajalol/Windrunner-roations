/**
 * WindrunnerRotations - Banshee Particles Effect
 * Author: VortexQ8
 * 
 * This file creates a Sylvanas-inspired banshee particle effect system,
 * with ethereal trails and ghostly wisps that respond to user interactions.
 */

class BansheeParticlesEffect {
  constructor(containerID) {
    this.container = document.getElementById(containerID);
    if (!this.container) return;
    
    this.width = this.container.offsetWidth;
    this.height = this.container.offsetHeight;
    this.mouseX = 0;
    this.mouseY = 0;
    this.mousePosition = new THREE.Vector2();
    
    // Scene setup
    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(75, this.width / this.height, 0.1, 1000);
    this.renderer = new THREE.WebGLRenderer({ 
      alpha: true,
      antialias: true
    });
    
    this.renderer.setSize(this.width, this.height);
    this.renderer.setClearColor(0x000000, 0);
    this.container.appendChild(this.renderer.domElement);
    
    // Camera position
    this.camera.position.z = 30;
    
    // Particles
    this.bansheeParticles = [];
    this.wispTrails = [];
    this.clock = new THREE.Clock();
    
    // Setup particles
    this.setupBansheeParticles();
    
    // Event listeners
    window.addEventListener('resize', this.onWindowResize.bind(this));
    this.container.addEventListener('mousemove', this.onMouseMove.bind(this));
    
    // Start animation loop
    this.animate();
  }
  
  setupBansheeParticles() {
    // Number of particles
    const particleCount = 100;
    
    // Create a particle group
    this.particleGroup = new THREE.Group();
    this.scene.add(this.particleGroup);
    
    // Create individual particles
    for (let i = 0; i < particleCount; i++) {
      this.createParticle();
    }
    
    // Create the central banshee effect (more concentrated)
    this.createBansheeFocus();
  }
  
  createParticle() {
    // Random position within the container, but biased towards the center
    const x = (Math.random() - 0.5) * this.width * 0.05;
    const y = (Math.random() - 0.5) * this.height * 0.05;
    const z = (Math.random() - 0.5) * 10;
    
    // Create a small, transparent circle
    const geometry = new THREE.PlaneGeometry(Math.random() * 0.5 + 0.2, Math.random() * 0.5 + 0.2);
    
    // Randomly select color (blues and purples)
    const colors = [0x9900ff, 0x00bfff, 0xaa00ff, 0x0088ff, 0xff00cc];
    const color = colors[Math.floor(Math.random() * colors.length)];
    
    const material = new THREE.MeshBasicMaterial({
      color: color,
      transparent: true,
      opacity: Math.random() * 0.5 + 0.1,
      side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    });
    
    const particle = new THREE.Mesh(geometry, material);
    particle.position.set(x, y, z);
    
    // Add to scene
    this.particleGroup.add(particle);
    
    // Store particle with its animation properties
    this.bansheeParticles.push({
      mesh: particle,
      speed: Math.random() * 0.02 + 0.01,
      offset: Math.random() * Math.PI * 2,
      amplitude: {
        x: Math.random() * 0.3,
        y: Math.random() * 0.3
      },
      size: Math.random() * 0.5 + 0.5,
      rotationSpeed: Math.random() * 0.02 - 0.01,
      pulseSpeed: Math.random() * 0.01 + 0.005
    });
  }
  
  createBansheeFocus() {
    // Create a central focus point for the banshee effect
    const geometry = new THREE.PlaneGeometry(4, 4);
    
    // Custom shader material for glowing effect
    const material = new THREE.ShaderMaterial({
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
          float distance = length(vUv - vec2(0.5));
          float alpha = smoothstep(0.5, 0.0, distance);
          alpha *= 0.7 + 0.3 * sin(time * 2.0);
          
          vec3 color = mix(color1, color2, sin(time + distance * 10.0) * 0.5 + 0.5);
          gl_FragColor = vec4(color, alpha * smoothstep(0.5, 0.45, distance));
        }
      `,
      transparent: true,
      side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    });
    
    const bansheeFocus = new THREE.Mesh(geometry, material);
    bansheeFocus.position.set(0, 0, 0);
    this.scene.add(bansheeFocus);
    
    // Store reference to update the shader uniforms
    this.bansheeFocus = {
      mesh: bansheeFocus,
      material: material
    };
  }
  
  createWispTrail(x, y) {
    // Create a trail when mouse moves
    const geometry = new THREE.PlaneGeometry(1, 1);
    
    const material = new THREE.MeshBasicMaterial({
      color: Math.random() > 0.5 ? 0x9900ff : 0x00bfff,
      transparent: true,
      opacity: 0.7,
      side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    });
    
    const wisp = new THREE.Mesh(geometry, material);
    
    // Convert screen coordinates to scene coordinates
    const vector = new THREE.Vector3(
      (x / this.width) * 2 - 1,
      -(y / this.height) * 2 + 1,
      0.5
    );
    
    vector.unproject(this.camera);
    const dir = vector.sub(this.camera.position).normalize();
    const distance = -this.camera.position.z / dir.z;
    const pos = this.camera.position.clone().add(dir.multiplyScalar(distance));
    
    wisp.position.set(pos.x, pos.y, 0);
    this.scene.add(wisp);
    
    // Add to wisp trails
    this.wispTrails.push({
      mesh: wisp,
      life: 1.0,
      fadeSpeed: Math.random() * 0.02 + 0.01,
      velocity: {
        x: (Math.random() - 0.5) * 0.1,
        y: (Math.random() - 0.5) * 0.1 - 0.05 // slight upward bias
      }
    });
  }
  
  onMouseMove(event) {
    // Track mouse position
    const rect = this.container.getBoundingClientRect();
    this.mouseX = event.clientX - rect.left;
    this.mouseY = event.clientY - rect.top;
    
    // Create new wisp trails occasionally when mouse moves
    if (Math.random() > 0.7) {
      this.createWispTrail(this.mouseX, this.mouseY);
    }
    
    // Update mouse position for shader effects
    this.mousePosition.x = (this.mouseX / this.width) * 2 - 1;
    this.mousePosition.y = -(this.mouseY / this.height) * 2 + 1;
  }
  
  onWindowResize() {
    this.width = this.container.offsetWidth;
    this.height = this.container.offsetHeight;
    
    this.camera.aspect = this.width / this.height;
    this.camera.updateProjectionMatrix();
    
    this.renderer.setSize(this.width, this.height);
  }
  
  updateBansheeParticles() {
    const time = this.clock.getElapsedTime();
    
    // Update individual particles
    this.bansheeParticles.forEach(particle => {
      // Sine wave movement (ethereal floating)
      particle.mesh.position.x += Math.sin(time * particle.speed + particle.offset) * particle.amplitude.x * 0.01;
      particle.mesh.position.y += Math.cos(time * particle.speed + particle.offset) * particle.amplitude.y * 0.01;
      
      // Slow rotation
      particle.mesh.rotation.z += particle.rotationSpeed;
      
      // Pulse size
      const pulse = Math.sin(time * particle.pulseSpeed) * 0.2 + 0.8;
      particle.mesh.scale.set(
        particle.size * pulse,
        particle.size * pulse,
        1
      );
      
      // Pulse opacity
      particle.mesh.material.opacity = Math.max(
        0.1,
        (Math.sin(time * particle.pulseSpeed * 2) * 0.3 + 0.7) * 0.5
      );
    });
    
    // Update central banshee focus
    if (this.bansheeFocus) {
      this.bansheeFocus.material.uniforms.time.value = time;
      
      // Make it respond to mouse movement
      const targetX = this.mousePosition.x * 1.5;
      const targetY = this.mousePosition.y * 1.5;
      
      this.bansheeFocus.mesh.position.x += (targetX - this.bansheeFocus.mesh.position.x) * 0.02;
      this.bansheeFocus.mesh.position.y += (targetY - this.bansheeFocus.mesh.position.y) * 0.02;
      
      // Scale based on mouse movement speed
      const speed = Math.sqrt(
        Math.pow(targetX - this.bansheeFocus.mesh.position.x, 2) +
        Math.pow(targetY - this.bansheeFocus.mesh.position.y, 2)
      );
      
      const targetScale = 1 + speed * 3;
      this.bansheeFocus.mesh.scale.x += (targetScale - this.bansheeFocus.mesh.scale.x) * 0.05;
      this.bansheeFocus.mesh.scale.y += (targetScale - this.bansheeFocus.mesh.scale.y) * 0.05;
    }
  }
  
  updateWispTrails() {
    // Update and fade wisp trails
    for (let i = this.wispTrails.length - 1; i >= 0; i--) {
      const wisp = this.wispTrails[i];
      
      // Decrease life
      wisp.life -= wisp.fadeSpeed;
      
      if (wisp.life <= 0) {
        // Remove the wisp
        this.scene.remove(wisp.mesh);
        this.wispTrails.splice(i, 1);
      } else {
        // Update position with velocity
        wisp.mesh.position.x += wisp.velocity.x;
        wisp.mesh.position.y += wisp.velocity.y;
        
        // Update scale and opacity
        wisp.mesh.scale.set(wisp.life, wisp.life, 1);
        wisp.mesh.material.opacity = wisp.life * 0.7;
      }
    }
  }
  
  animate() {
    requestAnimationFrame(this.animate.bind(this));
    
    // Update particle effects
    this.updateBansheeParticles();
    this.updateWispTrails();
    
    this.renderer.render(this.scene, this.camera);
  }
}

// Initialize the banshee particle effect when the window loads
window.addEventListener('load', () => {
  // If a container element with id 'banshee-particles' exists, create the effect
  if (document.getElementById('banshee-particles')) {
    window.bansheeParticlesEffect = new BansheeParticlesEffect('banshee-particles');
  }
});