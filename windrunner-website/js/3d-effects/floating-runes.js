/**
 * WindrunnerRotations - Floating Runes Background Effect
 * Author: VortexQ8
 * 
 * This file creates a background of floating WoW-style magic runes with 
 * subtle particle effects and depth, creating an immersive 3D environment.
 */

class FloatingRunesBackground {
  constructor(containerID) {
    this.container = document.getElementById(containerID);
    this.width = this.container.offsetWidth;
    this.height = this.container.offsetHeight;
    
    // Scene setup
    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(45, this.width / this.height, 0.1, 1000);
    this.renderer = new THREE.WebGLRenderer({ 
      alpha: true,
      antialias: true
    });
    
    this.renderer.setSize(this.width, this.height);
    this.renderer.setClearColor(0x000000, 0);
    this.container.appendChild(this.renderer.domElement);
    
    // Camera position
    this.camera.position.z = 50;
    
    // Controls for depth effect on scroll
    this.scrollY = 0;
    this.targetScrollY = 0;
    
    // Mouse interaction
    this.mouse = new THREE.Vector2();
    this.raycaster = new THREE.Raycaster();
    
    // Rune elements
    this.runes = [];
    this.particles = [];
    
    // Create runes and particles
    this.initRunes();
    this.initParticles();
    
    // Event listeners
    window.addEventListener('resize', this.onWindowResize.bind(this));
    window.addEventListener('scroll', this.onScroll.bind(this));
    window.addEventListener('mousemove', this.onMouseMove.bind(this));
    
    // Start animation loop
    this.animate();
  }
  
  initRunes() {
    // Define different rune shapes (simple geometric shapes for the examples)
    const runeShapes = [
      this.createRuneShape1(),
      this.createRuneShape2(),
      this.createRuneShape3(),
      this.createRuneShape4(),
      this.createRuneShape5()
    ];
    
    // Create multiple runes
    const runeCount = 15;
    
    for (let i = 0; i < runeCount; i++) {
      // Create a random rune
      const runeGeometry = runeShapes[Math.floor(Math.random() * runeShapes.length)];
      
      // Materials with emissive glow
      const colors = [0x9900ff, 0x00bfff, 0x9900ff, 0x00bfff, 0xff3db4];
      const colorIndex = Math.floor(Math.random() * colors.length);
      
      const runeMaterial = new THREE.MeshBasicMaterial({
        color: colors[colorIndex],
        transparent: true,
        opacity: Math.random() * 0.5 + 0.3,
        side: THREE.DoubleSide,
        wireframe: Math.random() > 0.7
      });
      
      const rune = new THREE.Mesh(runeGeometry, runeMaterial);
      
      // Random position and rotation
      rune.position.set(
        (Math.random() - 0.5) * this.width / 10,
        (Math.random() - 0.5) * this.height / 10,
        (Math.random() - 0.5) * 40
      );
      
      rune.rotation.set(
        Math.random() * Math.PI * 2,
        Math.random() * Math.PI * 2,
        Math.random() * Math.PI * 2
      );
      
      // Random scale
      const scale = Math.random() * 1.5 + 0.5;
      rune.scale.set(scale, scale, scale);
      
      // Add to scene and track
      this.scene.add(rune);
      
      // Add animation properties
      this.runes.push({
        mesh: rune,
        rotationSpeed: {
          x: (Math.random() - 0.5) * 0.01,
          y: (Math.random() - 0.5) * 0.01,
          z: (Math.random() - 0.5) * 0.01
        },
        floatSpeed: Math.random() * 0.01 + 0.005,
        floatOffset: Math.random() * Math.PI * 2,
        depthSpeed: Math.random() * 0.3 + 0.1,
        originalZ: rune.position.z,
        pulseSpeed: Math.random() * 0.01 + 0.005,
        hovered: false
      });
    }
  }
  
  createRuneShape1() {
    // Pentagon shape
    const shape = new THREE.Shape();
    const sides = 5;
    const radius = 2;
    
    for (let i = 0; i < sides; i++) {
      const angle = (i / sides) * Math.PI * 2;
      const x = Math.sin(angle) * radius;
      const y = Math.cos(angle) * radius;
      
      if (i === 0) {
        shape.moveTo(x, y);
      } else {
        shape.lineTo(x, y);
      }
    }
    shape.closePath();
    
    // Add inner details
    const hole = new THREE.Path();
    const innerRadius = radius * 0.6;
    for (let i = 0; i < sides; i++) {
      const angle = (i / sides) * Math.PI * 2;
      const x = Math.sin(angle) * innerRadius;
      const y = Math.cos(angle) * innerRadius;
      
      if (i === 0) {
        hole.moveTo(x, y);
      } else {
        hole.lineTo(x, y);
      }
    }
    hole.closePath();
    
    shape.holes.push(hole);
    
    return new THREE.ShapeGeometry(shape);
  }
  
  createRuneShape2() {
    // Triangle with details
    const shape = new THREE.Shape();
    
    shape.moveTo(0, 2);
    shape.lineTo(-2, -1.5);
    shape.lineTo(2, -1.5);
    shape.closePath();
    
    // Add inner line
    const path = new THREE.Path();
    path.moveTo(-1, -0.5);
    path.lineTo(1, -0.5);
    
    shape.holes.push(path);
    
    return new THREE.ShapeGeometry(shape);
  }
  
  createRuneShape3() {
    // Four-pointed star
    const shape = new THREE.Shape();
    
    shape.moveTo(0, 3);
    shape.lineTo(1, 1);
    shape.lineTo(3, 0);
    shape.lineTo(1, -1);
    shape.lineTo(0, -3);
    shape.lineTo(-1, -1);
    shape.lineTo(-3, 0);
    shape.lineTo(-1, 1);
    shape.closePath();
    
    // Add center circle hole
    const hole = new THREE.Path();
    hole.absarc(0, 0, 0.8, 0, Math.PI * 2, true);
    shape.holes.push(hole);
    
    return new THREE.ShapeGeometry(shape);
  }
  
  createRuneShape4() {
    // Hexagram (Star of David-like)
    const shape = new THREE.Shape();
    
    // First triangle
    shape.moveTo(0, 2);
    shape.lineTo(-1.7, -1);
    shape.lineTo(1.7, -1);
    shape.closePath();
    
    // Second triangle (inverted)
    const path = new THREE.Path();
    path.moveTo(0, -2);
    path.lineTo(-1.7, 1);
    path.lineTo(1.7, 1);
    path.closePath();
    
    shape.holes.push(path);
    
    return new THREE.ShapeGeometry(shape);
  }
  
  createRuneShape5() {
    // Complex arcane symbol
    const shape = new THREE.Shape();
    
    // Outer circle
    shape.absarc(0, 0, 2, 0, Math.PI * 2, false);
    
    // Inner circle hole
    const hole1 = new THREE.Path();
    hole1.absarc(0, 0, 1.5, 0, Math.PI * 2, true);
    shape.holes.push(hole1);
    
    // Create a complex geometry
    const geometry = new THREE.BufferGeometry();
    const vertices = [];
    
    // Create spokes
    const spokes = 8;
    const innerRadius = 0.5;
    const outerRadius = 2.5;
    
    for (let i = 0; i < spokes; i++) {
      const angle = (i / spokes) * Math.PI * 2;
      const nextAngle = ((i + 1) / spokes) * Math.PI * 2;
      
      const sinA = Math.sin(angle);
      const cosA = Math.cos(angle);
      const sinB = Math.sin(nextAngle);
      const cosB = Math.cos(nextAngle);
      
      vertices.push(
        innerRadius * sinA, innerRadius * cosA, 0,
        outerRadius * sinA, outerRadius * cosA, 0,
        innerRadius * sinB, innerRadius * cosB, 0,
        
        outerRadius * sinA, outerRadius * cosA, 0,
        outerRadius * sinB, outerRadius * cosB, 0,
        innerRadius * sinB, innerRadius * cosB, 0
      );
    }
    
    geometry.setAttribute('position', new THREE.Float32BufferAttribute(vertices, 3));
    return geometry;
  }
  
  initParticles() {
    // Particle system for background ambience
    const particleCount = 100;
    const particleGeometry = new THREE.BufferGeometry();
    const vertices = [];
    
    // Random particle positions
    for (let i = 0; i < particleCount; i++) {
      vertices.push(
        (Math.random() - 0.5) * this.width / 5,
        (Math.random() - 0.5) * this.height / 5,
        (Math.random() - 0.5) * 50
      );
    }
    
    particleGeometry.setAttribute('position', new THREE.Float32BufferAttribute(vertices, 3));
    
    // Create two different particle systems with different colors
    const createParticleSystem = (color, size) => {
      const particleMaterial = new THREE.PointsMaterial({
        color: color,
        size: size,
        transparent: true,
        opacity: 0.6,
        blending: THREE.AdditiveBlending,
        depthWrite: false
      });
      
      const particles = new THREE.Points(particleGeometry, particleMaterial);
      this.scene.add(particles);
      
      // Add to particle collection
      this.particles.push({
        points: particles,
        speed: 0.01
      });
    };
    
    // Create multiple particle systems with different colors
    createParticleSystem(0x9900ff, 0.2);  // Purple particles
    createParticleSystem(0x00bfff, 0.15); // Blue particles
  }
  
  onScroll() {
    // Get scroll position for parallax effect
    this.targetScrollY = window.scrollY;
  }
  
  onMouseMove(event) {
    // Track mouse position for interaction
    this.mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
    this.mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;
    
    // Update raycaster
    this.raycaster.setFromCamera(this.mouse, this.camera);
    
    // Check for intersections with runes
    const runeObjects = this.runes.map(rune => rune.mesh);
    const intersects = this.raycaster.intersectObjects(runeObjects);
    
    // Reset all hover states
    this.runes.forEach(rune => {
      rune.hovered = false;
    });
    
    // Set hover state for intersected runes
    if (intersects.length > 0) {
      const intersectedIndex = runeObjects.indexOf(intersects[0].object);
      if (intersectedIndex !== -1) {
        this.runes[intersectedIndex].hovered = true;
      }
    }
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
    
    // Smooth scrolling effect
    this.scrollY += (this.targetScrollY - this.scrollY) * 0.1;
    
    // Animate runes
    const time = Date.now() * 0.001;
    
    this.runes.forEach(rune => {
      // Rotation
      rune.mesh.rotation.x += rune.rotationSpeed.x;
      rune.mesh.rotation.y += rune.rotationSpeed.y;
      rune.mesh.rotation.z += rune.rotationSpeed.z;
      
      // Floating motion
      rune.mesh.position.y = 
        rune.mesh.position.y + Math.sin(time * rune.floatSpeed + rune.floatOffset) * 0.02;
      
      // Depth parallax based on scroll
      rune.mesh.position.z = 
        rune.originalZ - (this.scrollY * 0.01 * rune.depthSpeed);
      
      // Reset position if too far back or forward
      if (rune.mesh.position.z > 30) {
        rune.mesh.position.z = -30;
        rune.originalZ = -30;
      } else if (rune.mesh.position.z < -30) {
        rune.mesh.position.z = 30;
        rune.originalZ = 30;
      }
      
      // Pulse effect on hover
      if (rune.hovered) {
        rune.mesh.scale.x = 
          rune.mesh.scale.x * 0.95 + (1.5 * 0.05);
        rune.mesh.scale.y = 
          rune.mesh.scale.y * 0.95 + (1.5 * 0.05);
        rune.mesh.scale.z = 
          rune.mesh.scale.z * 0.95 + (1.5 * 0.05);
        
        rune.mesh.material.opacity = 
          rune.mesh.material.opacity * 0.9 + (0.8 * 0.1);
      } else {
        // Subtle pulsing
        const pulse = (Math.sin(time * rune.pulseSpeed * 2) * 0.1) + 1;
        rune.mesh.scale.x = rune.mesh.scale.x * 0.95 + (pulse * 0.05);
        rune.mesh.scale.y = rune.mesh.scale.y * 0.95 + (pulse * 0.05);
        rune.mesh.scale.z = rune.mesh.scale.z * 0.95 + (pulse * 0.05);
        
        // Return to original opacity
        rune.mesh.material.opacity = 
          rune.mesh.material.opacity * 0.95 + (0.5 * 0.05);
      }
    });
    
    // Animate particles
    this.particles.forEach(particleSystem => {
      particleSystem.points.rotation.y += particleSystem.speed * 0.1;
      
      // Move particles based on scroll for parallax
      particleSystem.points.position.y = -(this.scrollY * 0.003);
    });
    
    this.renderer.render(this.scene, this.camera);
  }
}

// Initialize the floating runes background when the window loads
window.addEventListener('load', () => {
  // If a container element with id 'floating-runes-bg' exists, create the effect
  if (document.getElementById('floating-runes-bg')) {
    window.floatingRunesBackground = new FloatingRunesBackground('floating-runes-bg');
  }
});