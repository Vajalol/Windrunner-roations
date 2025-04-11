/**
 * WindrunnerRotations - Sylvanas Bow 3D Effects
 * Author: VortexQ8
 * 
 * This file creates an advanced 3D effect that simulates Sylvanas Windrunner's 
 * bow and shadow magic. The effect includes particle systems, glowing arrow trails,
 * and animated shadow magic.
 */

class SylvanasBowEffect {
  constructor(containerID) {
    this.container = document.getElementById(containerID);
    this.width = this.container.offsetWidth;
    this.height = this.container.offsetHeight;
    this.mouseX = 0;
    this.mouseY = 0;
    this.targetMouseX = 0;
    this.targetMouseY = 0;

    // Three.js scene setup
    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(75, this.width / this.height, 0.1, 1000);
    this.renderer = new THREE.WebGLRenderer({ 
      alpha: true,
      antialias: true
    });
    
    this.renderer.setSize(this.width, this.height);
    this.renderer.shadowMap.enabled = true;
    this.renderer.outputEncoding = THREE.sRGBEncoding;
    this.container.appendChild(this.renderer.domElement);
    
    // Camera position
    this.camera.position.z = 30;
    
    // Lighting
    this.setupLights();
    
    // Bow model and particles
    this.bowGroup = new THREE.Group();
    this.scene.add(this.bowGroup);
    
    // Create particles system
    this.particleSystem = new THREE.Group();
    this.scene.add(this.particleSystem);
    
    // Arrow particles
    this.arrowParticles = [];
    
    // Background shadow wisps
    this.shadowWisps = [];
    
    // Setup scene
    this.createBow();
    this.createShadowWisps();
    
    // Event listeners
    window.addEventListener('resize', this.onWindowResize.bind(this));
    document.addEventListener('mousemove', this.onMouseMove.bind(this));
    
    // Start animation loop
    this.animate();
  }
  
  setupLights() {
    // Ambient light
    const ambientLight = new THREE.AmbientLight(0x333366, 0.5);
    this.scene.add(ambientLight);
    
    // Main purple spotlight
    const purpleLight = new THREE.PointLight(0x9900ff, 1.5, 100);
    purpleLight.position.set(10, 10, 20);
    purpleLight.castShadow = true;
    this.scene.add(purpleLight);
    
    // Secondary blue light
    const blueLight = new THREE.PointLight(0x00bfff, 1, 100);
    blueLight.position.set(-10, -5, 15);
    this.scene.add(blueLight);
    
    // Soft glow from below
    const bottomLight = new THREE.PointLight(0x330066, 0.8, 50);
    bottomLight.position.set(0, -15, 5);
    this.scene.add(bottomLight);
    
    // Create light helper for main light (helpful for debugging)
    // const sphereSize = 1;
    // const pointLightHelper = new THREE.PointLightHelper(purpleLight, sphereSize);
    // this.scene.add(pointLightHelper);
  }
  
  createBow() {
    // Bow body - curved arc
    const bowCurve = new THREE.CubicBezierCurve3(
      new THREE.Vector3(0, -10, 0),
      new THREE.Vector3(-10, -5, 0),
      new THREE.Vector3(-10, 5, 0),
      new THREE.Vector3(0, 10, 0)
    );
    
    const bowGeometry = new THREE.TubeGeometry(bowCurve, 50, 0.5, 8, false);
    const bowMaterial = new THREE.MeshStandardMaterial({
      color: 0x6600cc,
      metalness: 0.7,
      roughness: 0.2,
      emissive: 0x330066,
      emissiveIntensity: 0.3
    });
    
    const bow = new THREE.Mesh(bowGeometry, bowMaterial);
    this.bowGroup.add(bow);
    
    // Bow details - gem in the center
    const gemGeometry = new THREE.IcosahedronGeometry(1.2, 0);
    const gemMaterial = new THREE.MeshStandardMaterial({
      color: 0x00bfff,
      metalness: 0.9,
      roughness: 0.1,
      emissive: 0x00bfff,
      emissiveIntensity: 0.5
    });
    
    const gem = new THREE.Mesh(gemGeometry, gemMaterial);
    gem.position.set(0, 0, 0.5);
    this.bowGroup.add(gem);
    
    // Bow string
    const stringMaterial = new THREE.LineBasicMaterial({ 
      color: 0x9f00ff,
      transparent: true,
      opacity: 0.7,
      fog: true
    });
    
    const stringGeometry = new THREE.BufferGeometry().setFromPoints([
      new THREE.Vector3(0, -10, 0),
      new THREE.Vector3(0, 10, 0)
    ]);
    
    const bowString = new THREE.Line(stringGeometry, stringMaterial);
    this.bowGroup.add(bowString);
    
    // Bow decorations
    this.addBowDecorations();
    
    // Position bow group
    this.bowGroup.position.set(0, 0, 0);
    this.bowGroup.rotation.y = Math.PI * 0.1;
  }
  
  addBowDecorations() {
    // Top decoration
    const topDecGeometry = new THREE.ConeGeometry(1, 2, 5);
    const decorMaterial = new THREE.MeshStandardMaterial({
      color: 0x9900ff,
      metalness: 0.8,
      roughness: 0.2
    });
    
    const topDecoration = new THREE.Mesh(topDecGeometry, decorMaterial);
    topDecoration.position.set(0, 11, 0);
    topDecoration.rotation.z = Math.PI;
    this.bowGroup.add(topDecoration);
    
    // Bottom decoration
    const bottomDecoration = new THREE.Mesh(topDecGeometry, decorMaterial);
    bottomDecoration.position.set(0, -11, 0);
    this.bowGroup.add(bottomDecoration);
    
    // Small energy orbs
    const orbGeometry = new THREE.SphereGeometry(0.3, 16, 16);
    const orbMaterial = new THREE.MeshStandardMaterial({
      color: 0x00bfff,
      metalness: 0.5,
      roughness: 0.2,
      emissive: 0x00bfff,
      emissiveIntensity: 0.8
    });
    
    // Create several small orbs along the bow
    const orbPositions = [
      { x: -3, y: -8, z: 0 },
      { x: -5, y: -4, z: 0 },
      { x: -5, y: 4, z: 0 },
      { x: -3, y: 8, z: 0 }
    ];
    
    orbPositions.forEach(pos => {
      const orb = new THREE.Mesh(orbGeometry, orbMaterial);
      orb.position.set(pos.x, pos.y, pos.z);
      this.bowGroup.add(orb);
    });
  }
  
  createArrow(shootArrow = false) {
    // Arrow shaft
    const arrowGeometry = new THREE.CylinderGeometry(0.1, 0.1, 15, 8);
    const arrowMaterial = new THREE.MeshStandardMaterial({
      color: 0x9900ff,
      metalness: 0.3,
      roughness: 0.5,
      emissive: 0x9900ff,
      emissiveIntensity: 0.3,
      transparent: true,
      opacity: 0.9
    });
    
    const arrow = new THREE.Mesh(arrowGeometry, arrowMaterial);
    arrow.rotation.z = Math.PI / 2;
    
    // Arrow head
    const headGeometry = new THREE.ConeGeometry(0.4, 1.5, 8);
    const headMaterial = new THREE.MeshStandardMaterial({
      color: 0x00bfff,
      metalness: 0.7,
      roughness: 0.2,
      emissive: 0x00bfff,
      emissiveIntensity: 0.5
    });
    
    const arrowHead = new THREE.Mesh(headGeometry, headMaterial);
    arrowHead.position.set(7.5, 0, 0);
    arrowHead.rotation.z = Math.PI / 2;
    arrow.add(arrowHead);
    
    // Arrow feathers
    const featherGeometry = new THREE.PlaneGeometry(2, 1);
    const featherMaterial = new THREE.MeshStandardMaterial({
      color: 0x9900ff,
      side: THREE.DoubleSide,
      transparent: true,
      opacity: 0.7,
      emissive: 0x9900ff,
      emissiveIntensity: 0.3
    });
    
    // Top feather
    const topFeather = new THREE.Mesh(featherGeometry, featherMaterial);
    topFeather.position.set(-6, 0, 0);
    topFeather.rotation.z = Math.PI / 2;
    arrow.add(topFeather);
    
    // Bottom feather
    const bottomFeather = new THREE.Mesh(featherGeometry, featherMaterial);
    bottomFeather.position.set(-6, 0, 0);
    bottomFeather.rotation.set(0, Math.PI/2, Math.PI/2);
    arrow.add(bottomFeather);
    
    // Position arrow
    arrow.position.set(3, 0, 0);
    
    // Add to scene
    this.bowGroup.add(arrow);
    
    // Animate arrow if shooting
    if (shootArrow) {
      this.shootArrowAnimation(arrow);
      this.createArrowTrail(arrow);
    }
    
    return arrow;
  }
  
  shootArrowAnimation(arrow) {
    // Timeline for shooting animation
    const timeline = gsap.timeline();
    
    // Arrow shooting animation
    timeline.to(arrow.position, {
      x: 50,
      y: this.targetMouseY * 0.3,
      z: this.targetMouseX * 0.3,
      duration: 1.5,
      ease: "power2.in",
      onUpdate: () => {
        // Create particles along the trail
        if (Math.random() > 0.7) {
          this.createArrowParticle(arrow.position.x, arrow.position.y, arrow.position.z);
        }
      },
      onComplete: () => {
        // Remove arrow after animation
        this.bowGroup.remove(arrow);
      }
    });
    
    // Arrow rotation
    timeline.to(arrow.rotation, {
      x: Math.random() * 0.1,
      y: Math.random() * 0.1,
      duration: 1.5,
      ease: "power1.in"
    }, 0);
    
    // Arrow opacity fade out
    timeline.to(arrow.material, {
      opacity: 0,
      duration: 0.8,
      ease: "power1.in",
      delay: 0.7
    }, 0);
  }
  
  createArrowTrail(arrow) {
    // Create a trail of particles
    const trailGeometry = new THREE.BufferGeometry();
    const trailMaterial = new THREE.PointsMaterial({
      color: 0x9900ff,
      size: 0.5,
      transparent: true,
      opacity: 0.8,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    });
    
    // Number of particles in trail
    const particleCount = 100;
    const positions = new Float32Array(particleCount * 3);
    const alphas = new Float32Array(particleCount);
    
    for (let i = 0; i < particleCount; i++) {
      positions[i * 3] = arrow.position.x;
      positions[i * 3 + 1] = arrow.position.y;
      positions[i * 3 + 2] = arrow.position.z;
      alphas[i] = 1.0;
    }
    
    trailGeometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    trailGeometry.setAttribute('alpha', new THREE.BufferAttribute(alphas, 1));
    
    const trail = new THREE.Points(trailGeometry, trailMaterial);
    this.scene.add(trail);
    
    // Timeline animation for trail
    gsap.to({}, {
      duration: 2,
      onUpdate: () => {
        const positions = trail.geometry.attributes.position.array;
        const alphas = trail.geometry.attributes.alpha.array;
        
        // Update trail positions and fade out
        for (let i = particleCount - 1; i > 0; i--) {
          positions[i * 3] = positions[(i - 1) * 3];
          positions[i * 3 + 1] = positions[(i - 1) * 3 + 1];
          positions[i * 3 + 2] = positions[(i - 1) * 3 + 2];
          
          alphas[i] = alphas[i] * 0.95; // Fade out
        }
        
        // Head of trail follows arrow
        positions[0] = arrow.position.x;
        positions[1] = arrow.position.y;
        positions[2] = arrow.position.z;
        alphas[0] = 1.0;
        
        trail.geometry.attributes.position.needsUpdate = true;
        trail.geometry.attributes.alpha.needsUpdate = true;
      },
      onComplete: () => {
        this.scene.remove(trail);
      }
    });
  }
  
  createArrowParticle(x, y, z) {
    const particleGeometry = new THREE.SphereGeometry(0.2, 8, 8);
    const particleMaterial = new THREE.MeshStandardMaterial({
      color: Math.random() > 0.5 ? 0x9900ff : 0x00bfff,
      emissive: Math.random() > 0.5 ? 0x9900ff : 0x00bfff,
      emissiveIntensity: 0.7,
      transparent: true,
      opacity: 0.8
    });
    
    const particle = new THREE.Mesh(particleGeometry, particleMaterial);
    particle.position.set(x, y, z);
    
    // Add tiny random offset
    particle.position.x += (Math.random() - 0.5) * 0.5;
    particle.position.y += (Math.random() - 0.5) * 0.5;
    particle.position.z += (Math.random() - 0.5) * 0.5;
    
    this.particleSystem.add(particle);
    this.arrowParticles.push({
      mesh: particle,
      life: 1.0,
      velocity: {
        x: (Math.random() - 0.5) * 0.2,
        y: (Math.random() - 0.5) * 0.2,
        z: (Math.random() - 0.5) * 0.2
      }
    });
  }
  
  createShadowWisps() {
    // Create floating shadow wisps
    const count = 20;
    
    for (let i = 0; i < count; i++) {
      const size = Math.random() * 2 + 1;
      
      const geometry = new THREE.PlaneGeometry(size, size * 2);
      
      // Use shader material for ghostly effect
      const material = new THREE.MeshBasicMaterial({
        color: Math.random() > 0.5 ? 0x9900ff : 0x00bfff,
        transparent: true,
        opacity: Math.random() * 0.3 + 0.1,
        side: THREE.DoubleSide,
        blending: THREE.AdditiveBlending,
        depthWrite: false
      });
      
      const wisp = new THREE.Mesh(geometry, material);
      
      // Random positions around the scene
      wisp.position.set(
        (Math.random() - 0.5) * 30,
        (Math.random() - 0.5) * 30,
        (Math.random() - 0.5) * 20
      );
      
      // Random rotation
      wisp.rotation.x = Math.random() * Math.PI;
      wisp.rotation.y = Math.random() * Math.PI;
      wisp.rotation.z = Math.random() * Math.PI;
      
      this.scene.add(wisp);
      
      // Save wisp with animation properties
      this.shadowWisps.push({
        mesh: wisp,
        rotateSpeed: (Math.random() - 0.5) * 0.01,
        floatSpeed: (Math.random() - 0.5) * 0.05,
        floatOffset: Math.random() * Math.PI * 2
      });
    }
  }
  
  updateParticles() {
    // Update arrow particles
    for (let i = this.arrowParticles.length - 1; i >= 0; i--) {
      const particle = this.arrowParticles[i];
      
      // Update life
      particle.life -= 0.02;
      
      if (particle.life <= 0) {
        this.particleSystem.remove(particle.mesh);
        this.arrowParticles.splice(i, 1);
        continue;
      }
      
      // Update position
      particle.mesh.position.x += particle.velocity.x;
      particle.mesh.position.y += particle.velocity.y;
      particle.mesh.position.z += particle.velocity.z;
      
      // Update scale and opacity
      particle.mesh.scale.set(particle.life, particle.life, particle.life);
      particle.mesh.material.opacity = particle.life * 0.8;
    }
    
    // Update shadow wisps
    const time = Date.now() * 0.001;
    
    this.shadowWisps.forEach(wisp => {
      // Gentle floating motion
      wisp.mesh.position.y += Math.sin(time + wisp.floatOffset) * wisp.floatSpeed;
      
      // Slow rotation
      wisp.mesh.rotation.x += wisp.rotateSpeed;
      wisp.mesh.rotation.z += wisp.rotateSpeed * 0.7;
      
      // Gentle pulsing
      const pulse = (Math.sin(time * 0.5 + wisp.floatOffset) * 0.2 + 0.8);
      wisp.mesh.scale.set(pulse, pulse, pulse);
      
      // Update opacity pulse
      wisp.mesh.material.opacity = Math.max(0.05, Math.min(0.4, wisp.mesh.material.opacity * pulse));
    });
  }

  onMouseMove(event) {
    // Calculate mouse position in normalized device coordinates (-1 to +1)
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
    
    // Smooth mouse movement
    this.mouseX += (this.targetMouseX - this.mouseX) * 0.05;
    this.mouseY += (this.targetMouseY - this.mouseY) * 0.05;
    
    // Rotate bow slightly based on mouse position
    this.bowGroup.rotation.y = Math.PI * 0.1 + (this.mouseX * 0.3);
    this.bowGroup.rotation.x = this.mouseY * 0.3;
    
    // Update particles
    this.updateParticles();
    
    // Random arrows shooting
    if (Math.random() > 0.994) {
      this.createArrow(true);
    }
    
    this.renderer.render(this.scene, this.camera);
  }
  
  // Public method to shoot an arrow manually (can be triggered by events)
  shootArrow() {
    this.createArrow(true);
  }
}

// Initialize the bow effect when the window loads
window.addEventListener('load', () => {
  // If a container element with id 'sylvanas-bow-effect' exists, create the effect
  if (document.getElementById('sylvanas-bow-effect')) {
    window.sylvanasBowEffect = new SylvanasBowEffect('sylvanas-bow-effect');
  }
});